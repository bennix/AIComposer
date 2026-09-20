import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

nonisolated struct AIWorkImage: @unchecked Sendable {
    let image: CGImage
    /// OpenAI Images mask: transparent = edit, opaque = keep. Same size as `image`.
    let mask: CGImage?
    /// Grayscale coverage, white = selected. Same size and crop as `image`.
    let coverage: CGImage?
    let origin: CGPoint
    let canvasSize: CGSize
    /// Selection bounds in `image` pixels, top-left origin.
    let selectionInWork: CGRect?

    init(image: CGImage, mask: CGImage?, origin: CGPoint, canvasSize: CGSize,
         coverage: CGImage? = nil, selectionInWork: CGRect? = nil) {
        self.image = image
        self.mask = mask
        self.coverage = coverage
        self.origin = origin
        self.canvasSize = canvasSize
        self.selectionInWork = selectionInWork
    }
}

nonisolated enum AIImagePipeline {
    static let maxSendEdge = 2048

    static func pngData(from image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.encode
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ExportError.encode }
        return data as Data
    }

    static func image(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageImportError.unreadable
        }
        return image
    }

    static func asset(from data: Data, name: String) throws -> ImportedImage {
        let image = try image(from: data)
        return ImportedImage(image: image, thumbnail: try PixelAdjust.thumbnail(of: image), name: name)
    }

    static func asset(from image: CGImage, name: String) throws -> ImportedImage {
        ImportedImage(image: image, thumbnail: try PixelAdjust.thumbnail(of: image), name: name)
    }

    /// OpenAI Images mask: fully transparent pixels are edited; opaque pixels are preserved.
    static func openaiMask(from coverage: CGImage) throws -> CGImage {
        let width = coverage.width, height = coverage.height
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let inverted = invertCoverage(coverage) else { throw ExportError.render }
        context.clip(to: CGRect(x: 0, y: 0, width: width, height: height), mask: inverted)
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        guard let mask = context.makeImage() else { throw ExportError.render }
        return mask
    }

    /// White coverage becomes a hole (edit); black coverage stays opaque (keep).
    static func invertCoverage(_ coverage: CGImage) -> CGImage? {
        let width = coverage.width, height = coverage.height
        guard let space = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) ?? CGColorSpaceCreateDeviceGray() as CGColorSpace?,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width, space: space,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setBlendMode(.difference)
        context.draw(coverage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// Selection edits send the surrounding photograph, not an isolated cutout.
    /// A 48 px pad is too tight on a real photo: the model invents a new backdrop.
    static func contextBox(for selection: CGRect, canvas: CGSize) -> CGRect {
        let canvasRect = CGRect(origin: .zero, size: canvas)
        let longest = max(selection.width, selection.height)
        if max(canvas.width, canvas.height) <= CGFloat(maxSendEdge) {
            return canvasRect
        }
        let pad = max(512, longest)
        let box = selection.insetBy(dx: -pad, dy: -pad).integral.intersection(canvasRect)
        return box.width >= 1 && box.height >= 1 ? box : canvasRect
    }

    static func workImage(canvas: CGImage, selection: DocumentSelection?, padding: Int? = nil) throws -> AIWorkImage {
        let size = CGSize(width: canvas.width, height: canvas.height)
        guard let selection, !selection.isEmpty else {
            return AIWorkImage(image: canvas, mask: nil, origin: .zero, canvasSize: size)
        }
        let raw = selection.path.boundingBoxOfPath
        let box: CGRect
        if let padding {
            box = raw.insetBy(dx: -CGFloat(padding), dy: -CGFloat(padding))
                .integral.intersection(CGRect(origin: .zero, size: size))
        } else {
            box = contextBox(for: raw, canvas: size)
        }
        guard box.width >= 1, box.height >= 1 else {
            throw AIImageError.noSelection
        }
        let cropped = try crop(canvas, to: box)
        let coverage = try selection.coverage(width: canvas.width, height: canvas.height)
        let croppedCoverage = try crop(coverage, to: box)
        let local = selection.path.boundingBoxOfPath.offsetBy(dx: -box.minX, dy: -box.minY)
        let send = try sendCoverage(from: croppedCoverage, selection: local)
        let mask = try openaiMask(from: send)
        return AIWorkImage(
            image: cropped, mask: mask, origin: box.origin, canvasSize: size,
            coverage: croppedCoverage, selectionInWork: local
        )
    }

    /// Grow the hole the model is asked to paint so its own edge artifacts fall outside the selection.
    static func sendCoverage(from coverage: CGImage, selection: CGRect?) throws -> CGImage {
        let edge = max(8, min(selection?.width ?? 64, selection?.height ?? 64))
        let grown = try morph(coverage, radius: min(12, max(4, edge * 0.04)), dilate: true)
        return try feather(grown, radius: min(3, max(1.5, edge * 0.012)))
    }

    /// Pull the paste edge inward and soften it so a 1 px model frame is replaced by original fur.
    static func compositeCoverage(from coverage: CGImage, selection: CGRect?) throws -> CGImage {
        let edge = max(8, min(selection?.width ?? 64, selection?.height ?? 64))
        let inset = try morph(coverage, radius: min(3, max(1.2, edge * 0.012)), dilate: false)
        return try feather(inset, radius: min(5, max(2, edge * 0.02)))
    }

    static func morph(_ coverage: CGImage, radius: CGFloat, dilate: Bool) throws -> CGImage {
        let amount = max(0, radius)
        guard amount > 0.01 else { return coverage }
        let filter = dilate ? "CIMorphologyMaximum" : "CIMorphologyMinimum"
        let image = CIImage(cgImage: coverage)
            .clampedToExtent()
            .applyingFilter(filter, parameters: [kCIInputRadiusKey: amount])
        return try renderMask(image, width: coverage.width, height: coverage.height)
    }

    static func feather(_ coverage: CGImage, radius: CGFloat) throws -> CGImage {
        let amount = max(0, radius)
        guard amount > 0.01 else { return coverage }
        let image = CIImage(cgImage: coverage)
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: amount])
        return try renderMask(image, width: coverage.width, height: coverage.height)
    }

    private static func renderMask(_ image: CIImage, width: Int, height: Int) throws -> CGImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let clamped = image
            .applyingFilter("CIColorClamp", parameters: [
                "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
            ])
            .cropped(to: rect)
        return try PixelAdjust.render(clamped, width: width, height: height, isMask: true)
    }

    /// Visible black/white mask, same pixel size as the photograph, for models that ignore alpha holes.
    static func rgbMask(from coverage: CGImage) throws -> CGImage {
        let width = coverage.width, height = coverage.height
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        BrushRaster.draw(coverage, in: CGRect(x: 0, y: 0, width: width, height: height), mask: true, context: context)
        guard let image = context.makeImage() else { throw ExportError.render }
        return image
    }

    static func selectionHint(for work: AIWorkImage) -> String {
        guard let box = work.selectionInWork, !box.isNull, !box.isEmpty else { return "" }
        let x = Int(box.minX.rounded()), y = Int(box.minY.rounded())
        let w = Int(box.width.rounded()), h = Int(box.height.rounded())
        return L10n.format("ai.prompt.selectionBounds", x, y, w, h, work.image.width, work.image.height)
            + " [x=\(x) y=\(y) w=\(w) h=\(h) \(work.image.width)x\(work.image.height)]"
    }

    /// If the model returns a transparent hole, keep the photograph instead of punching through.
    static func sourceOver(_ foreground: CGImage, on background: CGImage) throws -> CGImage {
        let fg = try fit(foreground, to: CGSize(width: background.width, height: background.height))
        let result = CIImage(cgImage: fg).applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: CIImage(cgImage: background)
        ])
        return try PixelAdjust.render(result, width: background.width, height: background.height, isMask: false)
    }

    /// coverage × generated + (1 − coverage) × original, so unselected pixels stay the photograph.
    static func compositeIntoOriginal(_ original: CGImage, generated: CGImage, coverage: CGImage) throws -> CGImage {
        let size = CGSize(width: original.width, height: original.height)
        let filled = try sourceOver(generated, on: original)
        let mask = coverage.width == original.width && coverage.height == original.height
            ? coverage
            : try fit(coverage, to: size)
        let blended = CIImage(cgImage: filled).applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(cgImage: original),
            kCIInputMaskImageKey: CIImage(cgImage: mask)
        ])
        return try PixelAdjust.render(blended, width: original.width, height: original.height, isMask: false)
    }

    static func layerMatchesWork(_ layer: ImageLayer, work: AIWorkImage) -> Bool {
        guard let image = layer.asset?.image, work.origin == .zero else { return false }
        let size = layer.transform.size
        return image.width == work.image.width
            && image.height == work.image.height
            && layer.transform.origin == .zero
            && layer.transform.rotation == 0
            && Int(size.width.rounded()) == image.width
            && Int(size.height.rounded()) == image.height
    }

    /// Draws a work-sized image onto an existing layer in the same coordinate space as `workImage`.
    static func paint(
        _ patch: CGImage,
        at workOrigin: CGPoint,
        workSize: CGSize,
        onto layerImage: CGImage,
        layerTransform: LayerTransform
    ) throws -> CGImage {
        let width = layerImage.width, height = layerImage.height
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        BrushRaster.draw(layerImage, in: CGRect(x: 0, y: 0, width: width, height: height), mask: false, context: context)
        let documentToPixel = BrushRaster.pixelToDocument(layerTransform, width: width, height: height).inverted()
        let corners = [
            workOrigin,
            CGPoint(x: workOrigin.x + workSize.width, y: workOrigin.y),
            CGPoint(x: workOrigin.x, y: workOrigin.y + workSize.height),
            CGPoint(x: workOrigin.x + workSize.width, y: workOrigin.y + workSize.height)
        ].map { $0.applying(documentToPixel) }
        let xs = corners.map(\.x), ys = corners.map(\.y)
        let dest = CGRect(
            x: xs.min() ?? 0, y: ys.min() ?? 0,
            width: max(1, (xs.max() ?? 1) - (xs.min() ?? 0)),
            height: max(1, (ys.max() ?? 1) - (ys.min() ?? 0))
        )
        BrushRaster.draw(patch, in: dest, mask: false, context: context)
        guard let result = context.makeImage() else { throw ExportError.render }
        return result
    }

    /// Keep generated pixels only where the selection was; the rest stay transparent
    /// so a mismatched invented backdrop cannot cover the original photograph.
    static func applySelectionAlpha(_ image: CGImage, coverage: CGImage) throws -> CGImage {
        let width = image.width, height = image.height
        let mask = coverage.width == width && coverage.height == height
            ? coverage
            : try fit(coverage, to: CGSize(width: width, height: height))
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        BrushRaster.draw(image, in: rect, mask: false, context: context)
        context.setBlendMode(.destinationIn)
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.clip(to: rect, mask: mask)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(rect)
        context.restoreGState()
        guard let clipped = context.makeImage() else { throw ExportError.render }
        return clipped
    }

    static func expandOverlap(original: CGSize, left: Int, right: Int, top: Int, bottom: Int) -> CGFloat {
        let pad = CGFloat(max(left, right, top, bottom, 1))
        let edge = min(original.width, original.height)
        return min(48, min(pad, max(16, edge * 0.05)))
    }

    static func expand(canvas: CGImage, left: Int, right: Int, top: Int, bottom: Int) throws -> AIWorkImage {
        let width = canvas.width + left + right
        let height = canvas.height + top + bottom
        guard (1...30_000).contains(width), (1...30_000).contains(height) else { throw ExportError.tooLarge }
        let imageContext = try BrushRaster.context(width: width, height: height, mask: false)
        let origin = CGPoint(x: left, y: top)
        imageContext.interpolationQuality = .high
        BrushRaster.draw(canvas, in: CGRect(x: 0, y: 0, width: width, height: height),
                         mask: false, context: imageContext)
        imageContext.interpolationQuality = .none
        BrushRaster.draw(canvas, in: CGRect(origin: origin, size: CGSize(width: canvas.width, height: canvas.height)),
                         mask: false, context: imageContext)
        guard let expanded = imageContext.makeImage() else { throw ExportError.render }
        let original = CGRect(origin: origin, size: CGSize(width: canvas.width, height: canvas.height))
        let overlap = expandOverlap(original: original.size, left: left, right: right, top: top, bottom: bottom)
        let coverage = try expandEditCoverage(width: width, height: height, original: original, overlap: overlap)
        return AIWorkImage(
            image: expanded, mask: try openaiMask(from: coverage), origin: .zero,
            canvasSize: CGSize(width: width, height: height),
            coverage: coverage, selectionInWork: original
        )
    }

    /// White = generate (new border plus an overlap into the original). Black = keep the inner photograph.
    static func expandEditCoverage(width: Int, height: Int, original: CGRect, overlap: CGFloat) throws -> CGImage {
        let context = try BrushRaster.context(width: width, height: height, mask: true)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(gray: 0, alpha: 1)
        let keep = original.insetBy(dx: overlap, dy: overlap)
        let safe = keep.width >= 4 && keep.height >= 4 ? keep : original.insetBy(dx: 1, dy: 1)
        if safe.width >= 1, safe.height >= 1 { context.fill(safe) }
        guard let hard = context.makeImage() else { throw ExportError.render }
        return try feather(hard, radius: max(2, overlap * 0.45))
    }

    /// After expand, keep the invented border plus a soft inward overlap so the join is not a hard rectangle.
    static func punchOriginal(from result: CGImage, original: CGRect) throws -> CGImage {
        try expandBorder(from: result, original: original, overlap: 0)
    }

    static func expandBorder(from result: CGImage, original: CGRect, overlap: CGFloat) throws -> CGImage {
        let alpha = try expandSeamMask(
            width: result.width, height: result.height, original: original, overlap: max(0, overlap)
        )
        let empty = try BrushRaster.context(width: result.width, height: result.height, mask: false)
        empty.clear(CGRect(x: 0, y: 0, width: result.width, height: result.height))
        guard let clear = empty.makeImage() else { throw ExportError.render }
        let blended = CIImage(cgImage: result).applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(cgImage: clear),
            kCIInputMaskImageKey: CIImage(cgImage: alpha)
        ])
        return try PixelAdjust.render(blended, width: result.width, height: result.height, isMask: false)
    }

    /// White shows the generated pixels; the inner original fades in so the seam is a blend, not a box.
    static func expandSeamMask(width: Int, height: Int, original: CGRect, overlap: CGFloat) throws -> CGImage {
        let context = try BrushRaster.context(width: width, height: height, mask: true)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(gray: 0, alpha: 1)
        let inner = original.insetBy(dx: overlap, dy: overlap)
        let hole = inner.width >= 2 && inner.height >= 2 ? inner : original
        if hole.width >= 1, hole.height >= 1 { context.fill(hole) }
        guard let hard = context.makeImage() else { throw ExportError.render }
        return overlap > 0.5 ? try feather(hard, radius: max(2, overlap * 0.5)) : hard
    }

    /// Drop uniform black/white letterbox, then scale uniformly to fill the target.
    static func placed(_ image: CGImage, on size: CGSize) throws -> CGImage {
        try cover(try trimLetterbox(image), to: size)
    }

    /// Crop flat black, white, or transparent bars. Textured night sky is kept.
    static func trimLetterbox(_ image: CGImage) throws -> CGImage {
        let width = image.width, height = image.height
        guard width > 8, height > 8 else { return image }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
              ),
              let data = context.data else { return image }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let stride = context.bytesPerRow
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        func flatRow(_ y: Int) -> Bool { flatLine(count: width, step: 4) { x in y * stride + x * 4 } }
        func flatCol(_ x: Int) -> Bool { flatLine(count: height, step: stride) { y in y * stride + x * 4 } }
        func flatLine(count: Int, step: Int, offset: (Int) -> Int) -> Bool {
            let sample = max(1, count / 80)
            var n = 0, sum = 0, sum2 = 0, empty = 0, i = 0
            while i < count {
                let o = offset(i)
                let r = Int(bytes[o]), g = Int(bytes[o + 1]), b = Int(bytes[o + 2]), a = Int(bytes[o + 3])
                let luma = (r + g + b) / 3
                sum += luma
                sum2 += luma * luma
                n += 1
                if a < 12 || luma < 16 || luma > 242 { empty += 1 }
                i += sample
            }
            guard n > 0 else { return false }
            let mean = sum / n
            let variance = sum2 / n - mean * mean
            return variance < 48 && empty * 10 >= n * 8
        }
        var bottom = 0, top = 0, left = 0, right = 0
        while bottom < height / 2 - 2, flatRow(bottom) { bottom += 1 }
        while top < height / 2 - 2, flatRow(height - 1 - top) { top += 1 }
        while left < width / 2 - 2, flatCol(left) { left += 1 }
        while right < width / 2 - 2, flatCol(width - 1 - right) { right += 1 }
        if top < 3 || bottom < 3 { top = 0; bottom = 0 }
        if left < 3 || right < 3 { left = 0; right = 0 }
        guard top + bottom + left + right > 0 else { return image }
        let box = CGRect(
            x: left, y: bottom,
            width: width - left - right,
            height: height - top - bottom
        )
        guard box.width >= 8, box.height >= 8,
              box.width * box.height >= CGFloat(width * height) * 0.2,
              let trimmed = image.cropping(to: box) else { return image }
        return trimmed
    }

    /// Scale uniformly to fill `size`, then crop. Stretching a 1:1 result onto a wider canvas shifts the seam.
    static func cover(_ image: CGImage, to size: CGSize) throws -> CGImage {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        if image.width == width && image.height == height { return image }
        let scale = max(CGFloat(width) / CGFloat(image.width), CGFloat(height) / CGFloat(image.height))
        let draw = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        let origin = CGPoint(x: (CGFloat(width) - draw.width) / 2, y: (CGFloat(height) - draw.height) / 2)
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        context.interpolationQuality = .high
        BrushRaster.draw(image, in: CGRect(origin: origin, size: draw), mask: false, context: context)
        guard let covered = context.makeImage() else { throw ExportError.render }
        return covered
    }

    static func scaledForUpload(_ image: CGImage) throws -> CGImage {
        let edge = max(image.width, image.height)
        guard edge > maxSendEdge else { return image }
        let scale = CGFloat(maxSendEdge) / CGFloat(edge)
        let width = max(1, Int((CGFloat(image.width) * scale).rounded()))
        let height = max(1, Int((CGFloat(image.height) * scale).rounded()))
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        context.interpolationQuality = .high
        BrushRaster.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height), mask: false, context: context)
        guard let scaled = context.makeImage() else { throw ExportError.render }
        return scaled
    }

    static func fit(_ image: CGImage, to size: CGSize) throws -> CGImage {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        if image.width == width && image.height == height { return image }
        let context = try BrushRaster.context(width: width, height: height, mask: false)
        context.interpolationQuality = .high
        BrushRaster.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height), mask: false, context: context)
        guard let fitted = context.makeImage() else { throw ExportError.render }
        return fitted
    }

    static func crop(_ image: CGImage, to rect: CGRect) throws -> CGImage {
        let region = rect.integral
        let context = try BrushRaster.context(width: Int(region.width), height: Int(region.height), mask: image.colorSpace?.model == .monochrome)
        context.translateBy(x: -region.minX, y: -region.minY)
        BrushRaster.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height),
                         mask: image.colorSpace?.model == .monochrome, context: context)
        guard let cropped = context.makeImage() else { throw ExportError.render }
        return cropped
    }

    static func combinedPrompt(kind: AISheetKind, extra: String, hasSelection: Bool = false) -> String {
        let extra = extra.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .generate { return extra }
        var text = extra.isEmpty ? kind.defaultPrompt : kind.defaultPrompt + " Additional instruction: " + extra
        if hasSelection {
            for key in ["ai.prompt.selectionContext", "ai.prompt.returnEditedPhoto", "ai.prompt.noBorder"] {
                let extra = L10n.t(key)
                if !text.contains(extra) { text += (text.isEmpty ? extra : " " + extra) }
            }
        }
        if kind == .expand {
            let extra = L10n.t("ai.prompt.expandSeam")
            if !text.contains(extra) { text += (text.isEmpty ? extra : " " + extra) }
        }
        if kind != .generate {
            let extra = L10n.t("ai.prompt.fillFrame")
            if !text.contains(extra) { text += (text.isEmpty ? extra : " " + extra) }
        }
        return text
    }
}
