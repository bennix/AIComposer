import Foundation
import CoreGraphics
import Testing
@testable import Compositor

struct AIImagePipelineTests {
    @Test func kindsHaveUniqueTitlesAndGroupedMenus() {
        let titles = AISheetKind.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
        #expect(AISheetKind.inGroup(.generate).contains(.pattern))
        #expect(AISheetKind.inGroup(.transform).contains(.enhance))
        #expect(AISheetKind.inGroup(.edit).contains(.replaceSky))
        #expect(AISheetKind.inGroup(.canvas) == [.expand])
        #expect(AISheetKind.fill.needsSelection)
        #expect(AISheetKind.restyle.input == .canvasOrSelection)
        #expect(AISheetKind.enhance.upscaleFactor == 2)
    }

    @Test func openaiMaskClearsSelectedPixels() throws {
        let coverage = try gray(width: 8, height: 4) { x, _ in x < 4 ? 255 : 0 }
        let mask = try AIImagePipeline.openaiMask(from: coverage)
        #expect(mask.width == 8 && mask.height == 4)
        let png = try AIImagePipeline.pngData(from: mask)
        #expect(png.count > 8)
        let roundTrip = try AIImagePipeline.image(from: png)
        #expect(roundTrip.width == 8)
    }

    @Test func expandGrowsCanvasAndKeepsOriginalPlacement() throws {
        let source = try color(width: 10, height: 6, red: 1, green: 0, blue: 0)
        let work = try AIImagePipeline.expand(canvas: source, left: 4, right: 2, top: 3, bottom: 1)
        #expect(work.image.width == 16)
        #expect(work.image.height == 10)
        #expect(work.canvasSize == CGSize(width: 16, height: 10))
        let punched = try AIImagePipeline.punchOriginal(
            from: work.image,
            original: CGRect(x: 4, y: 3, width: 10, height: 6)
        )
        #expect(punched.width == 16)
        #expect(work.coverage?.width == 16)
        #expect(AIImagePipeline.expandOverlap(original: CGSize(width: 10, height: 6), left: 4, right: 2, top: 3, bottom: 1) >= 2)
    }

    @Test func expandBorderKeepsASoftOverlap() throws {
        let source = try color(width: 20, height: 16, red: 1, green: 0, blue: 0)
        let work = try AIImagePipeline.expand(canvas: source, left: 8, right: 8, top: 8, bottom: 8)
        let border = try AIImagePipeline.expandBorder(
            from: work.image,
            original: CGRect(x: 8, y: 8, width: 20, height: 16),
            overlap: 4
        )
        #expect(border.width == 36 && border.height == 32)
        let outside = try sample(border, x: 2, y: 2)
        let inside = try sample(border, x: 18, y: 16)
        #expect(outside.a > 0.8)
        #expect(inside.a < 0.2)
    }

    @Test func coverPreservesAspectInsteadOfStretching() throws {
        let source = try color(width: 10, height: 10, red: 0, green: 0, blue: 1)
        let covered = try AIImagePipeline.cover(source, to: CGSize(width: 20, height: 10))
        #expect(covered.width == 20 && covered.height == 10)
    }

    @Test func trimLetterboxRemovesAUniformFrame() throws {
        let inner = try color(width: 24, height: 18, red: 1, green: 0, blue: 0)
        let framed = try letterbox(inner, pad: 10)
        let trimmed = try AIImagePipeline.trimLetterbox(framed)
        #expect(trimmed.width < framed.width)
        #expect(trimmed.height < framed.height)
        #expect(trimmed.width >= 20)
        #expect(trimmed.height >= 14)
    }

    @Test func placedFillsTheTargetAfterTrimming() throws {
        let inner = try color(width: 24, height: 18, red: 0, green: 1, blue: 0)
        let framed = try letterbox(inner, pad: 12)
        let placed = try AIImagePipeline.placed(framed, on: CGSize(width: 40, height: 30))
        #expect(placed.width == 40 && placed.height == 30)
        let center = try sample(placed, x: 20, y: 15)
        #expect(center.g > center.r)
    }

    @Test func selectionWorkImageSendsSurroundingBackground() throws {
        let canvas = try color(width: 400, height: 300, red: 0, green: 0.4, blue: 0)
        let selection = DocumentSelection(
            path: CGPath(rect: CGRect(x: 180, y: 130, width: 40, height: 40), transform: nil),
            antialiased: false
        )
        let work = try AIImagePipeline.workImage(canvas: canvas, selection: selection)
        #expect(work.image.width == 400)
        #expect(work.image.height == 300)
        #expect(work.origin == .zero)
        #expect(work.mask != nil)
        #expect(work.mask?.width == 400)
        #expect(work.coverage?.width == 400)
        #expect(work.coverage?.height == 300)
        #expect(work.selectionInWork == CGRect(x: 180, y: 130, width: 40, height: 40))
        #expect(AIImagePipeline.selectionHint(for: work).contains("180"))
    }

    @Test func selectionResultKeepsOnlyEditedPixels() throws {
        let result = try color(width: 20, height: 16, red: 1, green: 0, blue: 0)
        let coverage = try gray(width: 20, height: 16) { x, y in
            (8...11).contains(x) && (6...9).contains(y) ? 255 : 0
        }
        let clipped = try AIImagePipeline.applySelectionAlpha(result, coverage: coverage)
        #expect(clipped.width == 20 && clipped.height == 16)
        let png = try AIImagePipeline.pngData(from: clipped)
        #expect(png.count > 8)
    }

    @Test func compositeKeepsUnselectedPixelsFromOriginal() throws {
        let original = try color(width: 20, height: 16, red: 0, green: 1, blue: 0)
        let generated = try color(width: 20, height: 16, red: 1, green: 0, blue: 0)
        let coverage = try gray(width: 20, height: 16) { x, y in
            (8...11).contains(x) && (6...9).contains(y) ? 255 : 0
        }
        let result = try AIImagePipeline.compositeIntoOriginal(original, generated: generated, coverage: coverage)
        #expect(result.width == 20 && result.height == 16)
        let outside = try sample(result, x: 1, y: 1)
        let inside = try sample(result, x: 9, y: 7)
        #expect(outside.g > outside.r)
        #expect(inside.r > inside.g)
    }

    @Test func compositeKeepsOriginalWhenGeneratedIsTransparent() throws {
        let original = try color(width: 20, height: 16, red: 0, green: 1, blue: 0)
        let generated = try clear(width: 20, height: 16)
        let coverage = try gray(width: 20, height: 16) { x, y in
            (8...11).contains(x) && (6...9).contains(y) ? 255 : 0
        }
        let result = try AIImagePipeline.compositeIntoOriginal(original, generated: generated, coverage: coverage)
        let inside = try sample(result, x: 9, y: 7)
        #expect(inside.g > 0.5)
        #expect(inside.a > 0.5)
    }

    @Test func rgbMaskMatchesCoverageSize() throws {
        let coverage = try gray(width: 12, height: 9) { x, _ in x < 4 ? 255 : 0 }
        let rgb = try AIImagePipeline.rgbMask(from: coverage)
        #expect(rgb.width == 12 && rgb.height == 9)
    }

    @Test func sendCoverageGrowsPastTheHardEdge() throws {
        let coverage = try gray(width: 40, height: 30) { x, y in
            (10...21).contains(x) && (8...17).contains(y) ? 255 : 0
        }
        let send = try AIImagePipeline.sendCoverage(
            from: coverage, selection: CGRect(x: 10, y: 8, width: 12, height: 10)
        )
        #expect(try sampleGray(send, x: 8, y: 12) > 0.05)
    }

    @Test func compositeCoverageSoftensTheHardEdge() throws {
        let coverage = try gray(width: 40, height: 30) { x, y in
            (10...21).contains(x) && (8...17).contains(y) ? 255 : 0
        }
        let seam = try AIImagePipeline.compositeCoverage(
            from: coverage, selection: CGRect(x: 10, y: 8, width: 12, height: 10)
        )
        let edge = try sampleGray(seam, x: 10, y: 12)
        let center = try sampleGray(seam, x: 15, y: 12)
        #expect(center > 0.8)
        #expect(edge < center)
    }

    @Test func compositeHidesAOnePixelBlackFrame() throws {
        let original = try color(width: 40, height: 30, red: 0, green: 0.8, blue: 0)
        let generated = try framed(
            width: 40, height: 30,
            fillRed: 1, fillGreen: 0, fillBlue: 0,
            frame: CGRect(x: 10, y: 8, width: 12, height: 10)
        )
        let coverage = try gray(width: 40, height: 30) { x, y in
            (10...21).contains(x) && (8...17).contains(y) ? 255 : 0
        }
        let seam = try AIImagePipeline.compositeCoverage(
            from: coverage, selection: CGRect(x: 10, y: 8, width: 12, height: 10)
        )
        let result = try AIImagePipeline.compositeIntoOriginal(original, generated: generated, coverage: seam)
        let edge = try sample(result, x: 10, y: 12)
        #expect(edge.g > edge.r)
        #expect(edge.r + edge.g + edge.b > 0.2)
    }

    @Test func paintWritesPatchOntoExistingLayer() throws {
        let layer = try color(width: 40, height: 30, red: 0, green: 1, blue: 0)
        let patch = try color(width: 10, height: 8, red: 1, green: 0, blue: 0)
        let painted = try AIImagePipeline.paint(
            patch,
            at: CGPoint(x: 5, y: 4),
            workSize: CGSize(width: 10, height: 8),
            onto: layer,
            layerTransform: LayerTransform(origin: .zero, size: CGSize(width: 40, height: 30))
        )
        #expect(painted.width == 40 && painted.height == 30)
        let kept = try sample(painted, x: 1, y: 1)
        let edited = try sample(painted, x: 8, y: 6)
        #expect(kept.g > kept.r)
        #expect(edited.r > edited.g)
    }

    @Test func cropAndFitPreserveRequestedSize() throws {
        let source = try color(width: 20, height: 10, red: 0, green: 1, blue: 0)
        let cropped = try AIImagePipeline.crop(source, to: CGRect(x: 5, y: 2, width: 8, height: 6))
        #expect(cropped.width == 8 && cropped.height == 6)
        let fitted = try AIImagePipeline.fit(cropped, to: CGSize(width: 16, height: 12))
        #expect(fitted.width == 16 && fitted.height == 12)
    }

    @MainActor
    @Test func insertGeneratedCreatesCanvasAndLayer() throws {
        let session = EditorSession()
        let image = try color(width: 32, height: 24, red: 0, green: 0, blue: 1)
        let asset = try AIImagePipeline.asset(from: image, name: "AI Image")
        session.insertGenerated(asset)
        #expect(session.document?.width == 32)
        #expect(session.document?.layers.count == 1)
        #expect(session.activeLayer?.name == "AI Image")
    }

    @MainActor
    @Test func enhanceKeepsDisplayedSize() throws {
        let session = EditorSession()
        session.createDocument(width: 64, height: 48, emptyLayer: true)
        let image = try color(width: 128, height: 96, red: 1, green: 1, blue: 0)
        let asset = try AIImagePipeline.asset(from: image, name: "AI Enhance")
        session.insertGenerated(asset, origin: .zero, displaySize: CGSize(width: 64, height: 48))
        #expect(session.activeLayer?.asset?.image.width == 128)
        #expect(session.activeLayer?.transform.size == CGSize(width: 64, height: 48))
    }

    @MainActor
    @Test func selectionCommandsStayDisabledWithoutASelection() {
        let session = EditorSession()
        session.createDocument(width: 64, height: 48, emptyLayer: true)
        #expect(session.canOpen(.generate))
        #expect(session.canOpen(.restyle))
        #expect(!session.canOpen(.fill))
        #expect(!session.canOpen(.removeObject))
        #expect(session.canOpen(.expand))
    }

    @MainActor
    @Test func objectCommandsOpenFromSelectedLayers() throws {
        let session = EditorSession()
        session.createDocument(width: 64, height: 48)
        let photo = try color(width: 64, height: 48, red: 0, green: 0.4, blue: 0)
        session.insert(try AIImagePipeline.asset(from: photo, name: "Photo"))
        #expect(session.hasAIObjectTarget)
        #expect(session.canOpen(.fill))
        #expect(session.canOpen(.removeObject))
        #expect(session.hasAIEditRegion(for: .fill))
    }

    @Test func layerCoverageUsesPaintedPixelsNotTheFullBox() throws {
        let background = try color(width: 40, height: 30, red: 0, green: 0.4, blue: 0)
        let islandContext = try BrushRaster.context(width: 40, height: 30, mask: false)
        islandContext.clear(CGRect(x: 0, y: 0, width: 40, height: 30))
        islandContext.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        islandContext.fill(CGRect(x: 12, y: 8, width: 10, height: 8))
        let island = try #require(islandContext.makeImage())
        let front = ImageLayer(asset: ImportedImage(image: island, thumbnail: island, name: "Front"), origin: .zero)
        let coverage = try AIImagePipeline.coverage(of: [front], canvas: CGSize(width: 40, height: 30))
        #expect(coverage.width == 40 && coverage.height == 30)
        let work = try AIImagePipeline.workImage(
            canvas: background,
            coverage: coverage,
            selection: CGRect(x: 12, y: 8, width: 10, height: 8)
        )
        #expect(work.mask != nil)
        #expect(work.coverage != nil)
        #expect(work.image.width == 40)
    }

    @MainActor
    @Test func selectionEditWritesTheExistingLayer() throws {
        let session = EditorSession()
        session.createDocument(width: 40, height: 30)
        let photo = try color(width: 40, height: 30, red: 0, green: 0.4, blue: 0)
        session.insert(try AIImagePipeline.asset(from: photo, name: "Photo"))
        let layerID = try #require(session.activeLayer?.id)
        let selection = DocumentSelection(
            path: CGPath(rect: CGRect(x: 10, y: 8, width: 12, height: 10), transform: nil),
            antialiased: false
        )
        let work = try AIImagePipeline.workImage(canvas: photo, selection: selection)
        let generated = try color(width: 40, height: 30, red: 1, green: 0, blue: 1)
        try session.commitAIEdit(generated: generated, work: work, kind: .fill, selection: selection)
        #expect(session.document?.layers.count == 1)
        #expect(session.document?.layers.first?.id == layerID)
        #expect(session.document?.layers.first?.name == "Photo")
        let result = try #require(session.activeLayer?.asset?.image)
        let kept = try sample(result, x: 1, y: 1)
        let edited = try sample(result, x: 14, y: 12)
        #expect(kept.g > kept.r)
        #expect(edited.r > edited.g)
    }
}

private func clear(width: Int, height: Int) throws -> CGImage {
    let context = try BrushRaster.context(width: width, height: height, mask: false)
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    return try #require(context.makeImage())
}

private func letterbox(_ image: CGImage, pad: Int) throws -> CGImage {
    let width = image.width + pad * 2
    let height = image.height + pad * 2
    let context = try BrushRaster.context(width: width, height: height, mask: false)
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    BrushRaster.draw(image, in: CGRect(x: pad, y: pad, width: image.width, height: image.height), mask: false, context: context)
    return try #require(context.makeImage())
}

private func framed(width: Int, height: Int, fillRed: CGFloat, fillGreen: CGFloat, fillBlue: CGFloat, frame: CGRect) throws -> CGImage {
    let context = try BrushRaster.context(width: width, height: height, mask: false)
    context.setFillColor(CGColor(red: fillRed, green: fillGreen, blue: fillBlue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.setLineWidth(1)
    context.stroke(frame)
    return try #require(context.makeImage())
}

private func sampleGray(_ image: CGImage, x: Int, y: Int) throws -> CGFloat {
    try sample(try AIImagePipeline.rgbMask(from: image), x: x, y: y).r
}

private func color(width: Int, height: Int, red: CGFloat, green: CGFloat, blue: CGFloat) throws -> CGImage {
    let context = try BrushRaster.context(width: width, height: height, mask: false)
    context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return try #require(context.makeImage())
}

private func sample(_ image: CGImage, x: Int, y: Int) throws -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    var pixel = [UInt8](repeating: 0, count: 4)
    guard let context = CGContext(
        data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    ) else { throw ExportError.render }
    context.interpolationQuality = .none
    context.translateBy(x: -CGFloat(x), y: -CGFloat(image.height - 1 - y))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return (
        r: CGFloat(pixel[0]) / 255,
        g: CGFloat(pixel[1]) / 255,
        b: CGFloat(pixel[2]) / 255,
        a: CGFloat(pixel[3]) / 255
    )
}

private func gray(width: Int, height: Int, value: (Int, Int) -> UInt8) throws -> CGImage {
    let context = try BrushRaster.context(width: width, height: height, mask: true)
    guard let data = context.data else { throw ExportError.render }
    let row = context.bytesPerRow
    for y in 0..<height {
        for x in 0..<width {
            data.storeBytes(of: value(x, y), toByteOffset: y * row + x, as: UInt8.self)
        }
    }
    return try #require(context.makeImage())
}
