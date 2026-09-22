import AppKit

nonisolated enum TextAlignment: String, Codable, CaseIterable, Sendable {
    case left = "Left", center = "Center", right = "Right"
}

/// Photoshop-style warp kept on live text: the letters stay editable; only the raster bends.
nonisolated enum TextWarpKind: String, Codable, CaseIterable, Sendable {
    case none = "None"
    case arc = "Arc"
    case arch = "Arch"
    case wave = "Wave"
    case flag = "Flag"
    case rise = "Rise"
    case bulge = "Bulge"
    case squeeze = "Squeeze"
}

nonisolated struct LayerTextStyle: Codable, Equatable, Sendable {
    var content = "Text"
    var fontName = "Helvetica"
    var fontSize: CGFloat = 72
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alignment: TextAlignment = .left
    var tracking: CGFloat = 0
    /// Baseline to baseline, in layer pixels, as Photoshop's Leading is. 0 is Auto: 120% of the font size.
    var leading: CGFloat = 0
    var autoLeading: CGFloat { fontSize * 1.2 }
    var lineHeight: CGFloat { leading > 0 ? leading : autoLeading }
    /// The gap between the text and its box, in layer pixels — the same for point text and a fixed box, so turning
    /// one into the other doesn't move the text, and wide enough to leave the box's edges easy to grab.
    static let padding: CGFloat = 12
    /// Fixed paragraph bounds in layer pixels. Nil supports older point-text layers.
    var boxSize: CGSize? = nil
    var warp: TextWarpKind = .none
    /// −100…100. Positive lifts the middle on Arc/Arch, or stretches the middle on Bulge.
    var warpBend: CGFloat = 50
    var boxIsValid: Bool {
        guard let boxSize else { return true }
        return boxSize.width.isFinite && boxSize.height.isFinite && (16...30_000).contains(boxSize.width)
            && (16...30_000).contains(boxSize.height) && boxSize.width * boxSize.height <= 100_000_000
    }
    var isValid: Bool {
        content.utf16.count <= 100_000 && boxIsValid
        && fontSize.isFinite && (1...2000).contains(fontSize)
        && [red, green, blue].allSatisfy { $0.isFinite && (0...1).contains($0) }
        && tracking.isFinite && (-100...1000).contains(tracking)
        && leading.isFinite && (0...5000).contains(leading)
        && warpBend.isFinite && (-100...100).contains(warpBend)
    }
    var fontFamily: String {
        (NSFont(name: fontName, size: 12) ?? .systemFont(ofSize: 12)).familyName ?? fontName
    }

    enum CodingKeys: String, CodingKey {
        case content, fontName, fontSize, red, green, blue, alignment, tracking, leading, boxSize, warp, warpBend
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? "Text"
        fontName = try c.decodeIfPresent(String.self, forKey: .fontName) ?? "Helvetica"
        fontSize = try c.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 72
        red = try c.decodeIfPresent(CGFloat.self, forKey: .red) ?? 0
        green = try c.decodeIfPresent(CGFloat.self, forKey: .green) ?? 0
        blue = try c.decodeIfPresent(CGFloat.self, forKey: .blue) ?? 0
        alignment = try c.decodeIfPresent(TextAlignment.self, forKey: .alignment) ?? .left
        tracking = try c.decodeIfPresent(CGFloat.self, forKey: .tracking) ?? 0
        leading = try c.decodeIfPresent(CGFloat.self, forKey: .leading) ?? 0
        boxSize = try c.decodeIfPresent(CGSize.self, forKey: .boxSize)
        warp = try c.decodeIfPresent(TextWarpKind.self, forKey: .warp) ?? .none
        warpBend = try c.decodeIfPresent(CGFloat.self, forKey: .warpBend) ?? 50
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(content, forKey: .content)
        try c.encode(fontName, forKey: .fontName)
        try c.encode(fontSize, forKey: .fontSize)
        try c.encode(red, forKey: .red)
        try c.encode(green, forKey: .green)
        try c.encode(blue, forKey: .blue)
        try c.encode(alignment, forKey: .alignment)
        try c.encode(tracking, forKey: .tracking)
        try c.encode(leading, forKey: .leading)
        try c.encodeIfPresent(boxSize, forKey: .boxSize)
        if warp != .none { try c.encode(warp, forKey: .warp) }
        if warp != .none { try c.encode(warpBend, forKey: .warpBend) }
    }
}

/// The cached raster participates in the existing compositor. Pixel edits rasterize the layer;
/// transforms and masks keep the source text editable, just as shape layers keep their source.
nonisolated struct LayerText: Equatable, @unchecked Sendable {
    var style: LayerTextStyle
    let image: CGImage
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.style == rhs.style && lhs.image === rhs.image }
    static func loaded(_ style: LayerTextStyle?, image: CGImage?) -> LayerText? {
        guard let style, style.isValid, let image else { return nil }
        return LayerText(style: style, image: image)
    }
}

extension ImageLayer {
    var liveText: LayerText? {
        guard let text, let image = asset?.image, image === text.image else { return nil }
        return text
    }
}

struct TextDraft: Identifiable {
    let id = UUID()
    let documentID: UUID
    let layerID: UUID?
    var origin: CGPoint
    var transform: LayerTransform? = nil
    var style: LayerTextStyle
}

extension EditorSession {
    func beginText(at point: CGPoint, newLayer: Bool = false) {
        guard canEditLayers, textDraft == nil, let document, point.x.isFinite, point.y.isFinite else { return }
        let visible = document.effectiveVisibleIDs
        let target = newLayer ? nil : document.layers.reversed().first {
            visible.contains($0.id) && $0.liveText != nil && $0.transform.contains(point)
        }
        if let target { selectLayer(target.id) }
        var style = target?.liveText?.style ?? textDefaults
        if target == nil {
            style.content = ""
            // New text starts in the foreground color, the same as every other tool that lays down color.
            if !isMaskSelected {
                style.red = foregroundColor.red; style.green = foregroundColor.green; style.blue = foregroundColor.blue
            }
            // A click makes point text: no box of its own, so what is typed decides how big the layer is. Dragging
            // a box out instead (beginText(in:)) sets boxSize, and so does resizing one by its handles.
            style.boxSize = nil
        }
        tool = .type
        textDraft = TextDraft(documentID: document.id, layerID: target?.id, origin: target?.origin ?? point, transform: target?.transform, style: style)
    }

    func editActiveText() {
        guard canEditLayers, textDraft == nil, let document, let layer = activeLayer, let text = layer.liveText else { return }
        tool = .type
        textDraft = TextDraft(documentID: document.id, layerID: layer.id, origin: layer.origin, transform: layer.transform, style: text.style)
    }

    @discardableResult
    func applyText(_ draft: TextDraft) -> Bool {
        guard document?.id == draft.documentID, draft.style.isValid else { return false }
        let pending = textDraft
        textDraft = nil
        guard canEditLayers else { textDraft = pending; return false }
        var succeeded = false
        defer { if !succeeded { textDraft = pending } }
        if draft.layerID == nil, draft.style.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            succeeded = true
            return true
        }
        do {
            let image = try Self.textImage(draft.style)
            let text = LayerText(style: draft.style, image: image)
            if let id = draft.layerID {
                guard let index = document?.layers.firstIndex(where: { $0.id == id }),
                      let layer = document?.layers[index], layer.liveText != nil, let asset = layer.asset else { return false }
                if layer.liveText?.style == draft.style && (draft.transform == nil || draft.transform == layer.transform) { succeeded = true; return true }
                let thumbnail = try PixelInvert.thumbnail(of: image)
                var transform = draft.transform ?? layer.transform
                // Keep the transformed upper-left corner and the user's scale, rotation and flips.
                let anchor = transform.point(.zero)
                if draft.transform == nil || draft.style.boxSize == nil {
                    transform.size = CGSize(width: CGFloat(image.width) * transform.size.width / CGFloat(asset.image.width),
                                            height: CGFloat(image.height) * transform.size.height / CGFloat(asset.image.height))
                    let moved = transform.point(.zero)
                    transform.origin.x += anchor.x - moved.x
                    transform.origin.y += anchor.y - moved.y
                }
                guard transform.isValid else { throw ProjectError.tooLarge }
                beginEdit("Edit Text")
                if layer.mask?.placement == nil { document?.layers[index].mask?.placement = layer.maskTransform }
                document?.layers[index].asset = ImportedImage(image: image, thumbnail: thumbnail, name: asset.name)
                document?.layers[index].text = text
                document?.layers[index].transform = transform
                endEdit()
            } else {
                addPixelLayer(image, at: draft.origin, name: Self.layerName(for: draft.style.content), editName: "New Text Layer",
                              dropsSelection: false, text: text)
            }
            succeeded = true
            textDefaults = draft.style
            textDraft = nil
            canvasFocusRequest += 1
            return true
        } catch {
            brushError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func finishText() -> Bool {
        guard let draft = textDraft else { return true }
        return applyText(draft)
    }

    func cancelText() { textDraft = nil; canvasFocusRequest += 1 }

    func beginText(in rect: CGRect) {
        guard canEditLayers, textDraft == nil, rect.width.isFinite, rect.height.isFinite else { return }
        var style = textDefaults
        style.boxSize = CGSize(width: max(16, rect.width.rounded()), height: max(16, rect.height.rounded()))
        guard style.boxIsValid else { brushError = "That text box exceeds the 30,000-pixel or 100-megapixel limit."; return }
        beginText(at: rect.origin, newLayer: true)
        textDraft?.style.boxSize = style.boxSize
    }

    /// Paints a text layer's letters in `color`, keeping it editable text. Used by Fill with Foreground/Background;
    /// false when the layer isn't live text or its pixels couldn't be redrawn, so the caller fills as usual.
    @discardableResult
    func recolorText(_ id: UUID, to color: PaletteColor) -> Bool {
        guard canEditLayers, let index = document?.layers.firstIndex(where: { $0.id == id }),
              let layer = document?.layers[index], let text = layer.liveText, let asset = layer.asset else { return false }
        var style = text.style
        guard style.red != color.red || style.green != color.green || style.blue != color.blue else { return true }
        style.red = color.red; style.green = color.green; style.blue = color.blue
        guard style.isValid, let image = try? Self.textImage(style), let thumbnail = try? PixelInvert.thumbnail(of: image) else { return false }
        finishOpacityEdit()
        beginEdit("Fill Text")
        document?.layers[index].asset = ImportedImage(image: image, thumbnail: thumbnail, name: asset.name)
        document?.layers[index].text = LayerText(style: style, image: image)
        endEdit()
        return true
    }

    var currentTextStyle: LayerTextStyle { textDraft?.style ?? activeLayer?.liveText?.style ?? textDefaults }

    func changeTextStyle(_ change: (inout LayerTextStyle) -> Void) {
        if textDraft == nil, activeLayer?.liveText != nil { editActiveText() }
        if var draft = textDraft {
            change(&draft.style)
            guard draft.style.isValid else { return }
            textDraft = draft
        } else {
            var style = textDefaults
            change(&style)
            if style.isValid { textDefaults = style }
        }
    }

    /// A text layer's name: its first words on one line. Line breaks and runs of spaces become single spaces, so a
    /// paragraph never makes the row in the Layers panel taller than one line.
    static func layerName(for content: String) -> String {
        let flattened = content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).joined(separator: " ")
        return flattened.isEmpty ? "Text" : String(flattened.prefix(40))
    }

    static func textAttributes(_ style: LayerTextStyle) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = style.alignment == .left ? .left : style.alignment == .center ? .center : .right
        let font = NSFont(name: style.fontName, size: style.fontSize) ?? NSFont.systemFont(ofSize: style.fontSize)
        // Leading is the line's whole height, so the lines close up (and eventually overlap) as it comes down,
        // exactly as Photoshop's does. Auto is 120% of the size.
        _ = font
        paragraph.minimumLineHeight = style.lineHeight
        paragraph.maximumLineHeight = style.lineHeight
        paragraph.lineBreakMode = .byWordWrapping
        return [.font: NSFont(name: style.fontName, size: style.fontSize) ?? NSFont.systemFont(ofSize: style.fontSize),
                .foregroundColor: NSColor(srgbRed: style.red, green: style.green, blue: style.blue, alpha: 1),
                .paragraphStyle: paragraph, .kern: style.tracking]
    }

    /// How big point text is: what it measures, plus its padding. A caret's worth of width so an empty line still
    /// has somewhere to type.
    static func textBoxSize(_ style: LayerTextStyle) -> CGSize {
        if let boxSize = style.boxSize { return boxSize }
        let string = NSAttributedString(string: style.content, attributes: textAttributes(style))
        let padding = LayerTextStyle.padding
        let measured = string.boundingRect(with: CGSize(width: 100_000, height: 100_000),
                                           options: [.usesLineFragmentOrigin, .usesFontLeading])
        let line = ceil(style.lineHeight)
        return CGSize(width: max(16, ceil(measured.width + padding * 2 + style.fontSize * 0.1)),
                      height: max(16, ceil(max(measured.height, line) + padding * 2)))
    }

    static func textImage(_ style: LayerTextStyle) throws -> CGImage {
        guard style.isValid else { throw ProjectError.invalid }
        let string = NSAttributedString(string: style.content, attributes: textAttributes(style))
        let padding = LayerTextStyle.padding
        let size = textBoxSize(style)
        let width = ceil(size.width), height = ceil(size.height)
        guard width.isFinite, height.isFinite, width >= 1, height >= 1,
              width <= 30_000, height <= 30_000, width * height <= 100_000_000 else { throw ProjectError.tooLarge }
        let context = try BrushRaster.context(width: Int(width), height: Int(height), mask: false)
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        let storage = NSTextStorage(attributedString: string)
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: max(1, width - 2 * padding), height: max(1, height - 2 * padding)))
        container.lineFragmentPadding = 0
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        let glyphs = layout.glyphRange(for: container)
        layout.drawGlyphs(forGlyphRange: glyphs, at: CGPoint(x: padding, y: padding))
        guard let flat = context.makeImage() else { throw ExportError.render }
        return try warpText(flat, kind: style.warp, bend: style.warpBend)
    }

    /// Installed faces in `family` as (PostScript name, face title).
    static func fontFaces(in family: String) -> [(name: String, title: String)] {
        let members = NSFontManager.shared.availableMembers(ofFontFamily: family) ?? []
        let faces = members.compactMap { row -> (String, String)? in
            guard let name = row.first as? String else { return nil }
            let title = (row.dropFirst().first as? String)?.trimmingCharacters(in: .whitespaces)
            return (name, (title?.isEmpty == false ? title! : name))
        }
        return faces.isEmpty ? [(family, family)] : faces
    }

    static func setFontFamily(_ family: String, on style: inout LayerTextStyle) {
        let faces = fontFaces(in: family)
        if faces.contains(where: { $0.name == style.fontName }) { return }
        style.fontName = faces.first?.name ?? family
    }

    /// Bend live-text pixels. The source stays editable; only this raster is deformed.
    static func warpText(_ image: CGImage, kind: TextWarpKind, bend: CGFloat) throws -> CGImage {
        guard kind != .none, abs(bend) > 0.5 else { return image }
        let amount = max(-1, min(1, bend / 100))
        let width = image.width, height = image.height
        let padY = max(8, Int(CGFloat(height) * abs(amount) * 0.55))
        let destH = height + padY * 2
        let destW = width
        let context = try BrushRaster.context(width: destW, height: destH, mask: false)
        context.clear(CGRect(x: 0, y: 0, width: destW, height: destH))
        let strips = max(32, width)
        for i in 0..<strips {
            let x = i
            let t = (CGFloat(x) + 0.5) / CGFloat(max(1, width)) * 2 - 1
            let sample = warpSample(t: t, kind: kind, amount: amount)
            let destY = CGFloat(padY) + sample.dy * CGFloat(height)
            let destHeight = max(1, CGFloat(height) * sample.scaleY)
            guard let tile = image.cropping(to: CGRect(x: x, y: 0, width: 1, height: height)) else { continue }
            BrushRaster.draw(tile, in: CGRect(x: CGFloat(x), y: destY, width: 1, height: destHeight),
                             mask: false, context: context)
        }
        guard let warped = context.makeImage() else { throw ExportError.render }
        return warped
    }

    private static func warpSample(t: CGFloat, kind: TextWarpKind, amount: CGFloat) -> (dy: CGFloat, scaleY: CGFloat) {
        let u = max(-1, min(1, t))
        switch kind {
        case .none: return (0, 1)
        case .arc: return (amount * (1 - u * u) * 0.42, 1)
        case .arch: return (amount * cos(u * .pi / 2) * 0.42, 1)
        case .wave: return (amount * sin(u * .pi * 2) * 0.28, 1)
        case .flag: return (amount * sin((u * 0.5 + 0.5) * .pi) * 0.32, 1)
        case .rise: return (amount * u * 0.38, 1)
        case .bulge: return (0, max(0.2, 1 + amount * (1 - u * u) * 0.55))
        case .squeeze: return (0, max(0.2, 1 - amount * (1 - u * u) * 0.55))
        }
    }
}
