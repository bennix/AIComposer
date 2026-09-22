import CoreGraphics
import Foundation

/// Which painted layer sits under a document point. Bounding boxes alone are wrong for PSD
/// imports: a layer often covers most of the canvas while only a few pixels are visible.
nonisolated enum LayerHit {
    /// Topmost visible pixel layer whose paint (or mask) is actually there.
    static func layer(under point: CGPoint, in document: CanvasDocument, visible: Set<UUID>) -> UUID? {
        document.renderLayers.reversed().first { covers($0, at: point, visible: visible) }?.id
    }

    static func covers(_ layer: ImageLayer, at point: CGPoint, visible: Set<UUID>, threshold: UInt8 = 16) -> Bool {
        guard visible.contains(layer.id), !layer.isGroup, layer.adjustment == nil else { return false }
        guard layer.transform.contains(point) else { return false }
        if let image = layer.asset?.image {
            guard opaque(image, at: point, transform: layer.transform, threshold: threshold) else { return false }
        } else if layer.text == nil && layer.shape == nil {
            return false
        }
        if let mask = layer.mask?.enabledImage {
            return revealing(mask, at: point, transform: layer.maskTransform, threshold: threshold)
        }
        return true
    }

    private static func opaque(_ image: CGImage, at point: CGPoint, transform: LayerTransform, threshold: UInt8) -> Bool {
        guard let pixel = imagePixel(image, at: point, transform: transform) else { return false }
        return sample(image, x: pixel.x, y: pixel.y, alpha: true) > threshold
    }

    private static func revealing(_ mask: CGImage, at point: CGPoint, transform: LayerTransform, threshold: UInt8) -> Bool {
        guard let pixel = imagePixel(mask, at: point, transform: transform) else { return false }
        return sample(mask, x: pixel.x, y: pixel.y, alpha: false) > threshold
    }

    private static func imagePixel(_ image: CGImage, at point: CGPoint, transform: LayerTransform) -> (x: Int, y: Int)? {
        let mapped = point.applying(BrushRaster.pixelToDocument(transform, width: image.width, height: image.height).inverted())
        let x = Int(floor(mapped.x)), y = Int(floor(mapped.y))
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return nil }
        return (x, y)
    }

    /// One pixel, drawn into RGBA so both color images and grayscale masks share a reader.
    /// `pixelToDocument` uses Core Graphics' bottom-left origin; `CGImage.cropping` is top-left.
    private static func sample(_ image: CGImage, x: Int, y: Int, alpha: Bool) -> UInt8 {
        var pixel = [UInt8](repeating: 0, count: 4)
        return pixel.withUnsafeMutableBytes { bytes in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                          space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                  let tile = image.cropping(to: CGRect(x: x, y: image.height - 1 - y, width: 1, height: 1)) else { return 0 }
            context.interpolationQuality = .none
            context.draw(tile, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return alpha ? bytes[3] : bytes[0]
        }
    }
}
