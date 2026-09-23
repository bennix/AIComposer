import AppKit
import Foundation

/// Structured type read from a multimodal chat/completions reply.
nonisolated struct AIRecognizedText: Equatable, Sendable {
    var content: String
    var fontName: String?
    var fontSize: CGFloat?
    var alignment: TextAlignment?
    var red: CGFloat?
    var green: CGFloat?
    var blue: CGFloat?

    static func parse(_ text: String) throws -> AIRecognizedText {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIImageError.noTextInResponse }
        if let object = jsonObject(in: trimmed) {
            let content = string(object, keys: ["content", "text", "string"])?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !content.isEmpty else { throw AIImageError.noTextInResponse }
            let (red, green, blue) = color(in: object)
            return AIRecognizedText(
                content: content,
                fontName: string(object, keys: ["fontName", "font", "fontFamily", "family"]),
                fontSize: number(object, keys: ["fontSize", "size", "pointSize"]),
                alignment: alignment(from: string(object, keys: ["alignment", "align", "textAlign"])),
                red: red, green: green, blue: blue
            )
        }
        let plain = strippedFences(trimmed)
        guard !plain.isEmpty else { throw AIImageError.noTextInResponse }
        return AIRecognizedText(content: plain)
    }

    func style(box: CGSize? = nil, fallbackColor: (CGFloat, CGFloat, CGFloat)? = nil) -> LayerTextStyle {
        var style = LayerTextStyle()
        style.content = content
        style.fontName = Self.resolveFont(fontName)
        let estimated: CGFloat
        if let box {
            estimated = max(12, min(2000, box.height - LayerTextStyle.padding * 2))
        } else {
            estimated = 72
        }
        if let fontSize, (1...2000).contains(fontSize) {
            style.fontSize = fontSize
        } else {
            style.fontSize = estimated
        }
        style.alignment = alignment ?? .left
        if let red, let green, let blue,
           [red, green, blue].allSatisfy({ (0...1).contains($0) }) {
            style.red = red; style.green = green; style.blue = blue
        } else if let fallbackColor {
            style.red = fallbackColor.0
            style.green = fallbackColor.1
            style.blue = fallbackColor.2
        }
        if let box {
            style.boxSize = CGSize(
                width: max(16, min(30_000, box.width)),
                height: max(16, min(30_000, box.height))
            )
        }
        return style
    }

    static func resolveFont(_ name: String?) -> String {
        let requested = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !requested.isEmpty else { return LayerTextStyle().fontName }
        if NSFont(name: requested, size: 12) != nil { return requested }
        let families = NSFontManager.shared.availableFontFamilies
        if let family = families.first(where: { $0.caseInsensitiveCompare(requested) == .orderedSame }) {
            return EditorSession.fontFaces(in: family).first?.name ?? family
        }
        if let family = families.first(where: {
            $0.range(of: requested, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                || requested.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }) {
            return EditorSession.fontFaces(in: family).first?.name ?? family
        }
        return LayerTextStyle().fontName
    }

    static func sampleOpaqueColor(from image: CGImage) -> (CGFloat, CGFloat, CGFloat)? {
        let width = min(image.width, 160)
        let height = min(image.height, 160)
        guard width > 0, height > 0, let context = try? BrushRaster.context(width: width, height: height, mask: false) else {
            return nil
        }
        context.interpolationQuality = .low
        BrushRaster.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height), mask: false, context: context)
        guard let data = context.data else { return nil }
        let bytes = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var red = 0, green = 0, blue = 0, count = 0
        for index in stride(from: 0, to: width * height * 4, by: 4) {
            let alpha = Int(bytes[index + 3])
            guard alpha >= 96 else { continue }
            red += Int(bytes[index]) * 255 / max(alpha, 1)
            green += Int(bytes[index + 1]) * 255 / max(alpha, 1)
            blue += Int(bytes[index + 2]) * 255 / max(alpha, 1)
            count += 1
        }
        guard count > 0 else { return nil }
        return (
            min(1, CGFloat(red) / CGFloat(count) / 255),
            min(1, CGFloat(green) / CGFloat(count) / 255),
            min(1, CGFloat(blue) / CGFloat(count) / 255)
        )
    }

    static func parseChatContent(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any] {
            if let text = message["content"] as? String, !text.isEmpty { return text }
            if let parts = message["content"] as? [[String: Any]] {
                let texts = parts.compactMap { $0["text"] as? String }
                if !texts.isEmpty { return texts.joined(separator: "\n") }
            }
        }
        if let candidates = json?["candidates"] as? [[String: Any]] {
            let parts = (candidates.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]] ?? []
            let texts = parts.compactMap { $0["text"] as? String }
            if !texts.isEmpty { return texts.joined(separator: "\n") }
        }
        throw AIImageError.noTextInResponse
    }

    static func chatBody(model: String, imagePNG: Data, extra: String) -> [String: Any] {
        var instruction = """
        Read every letter in this image. Reply with a JSON object only — no markdown — using these keys: \
        content (string, required, keep line breaks), fontName (PostScript or family name if you can tell), \
        fontSize (number, pixels), alignment (left, center, or right), red, green, blue (0–1, the type color). \
        If there is no readable text, return {"content":""}.
        """
        let extra = extra.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extra.isEmpty { instruction += " Additional instruction: " + extra }
        return [
            "model": model,
            "temperature": 0,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": instruction],
                    ["type": "image_url", "image_url": [
                        "url": "data:image/png;base64," + imagePNG.base64EncodedString()
                    ]]
                ]
            ]]
        ]
    }

    private static func jsonObject(in text: String) -> [String: Any]? {
        if let object = decodeJSON(text) { return object }
        if let start = text.range(of: "```") {
            var rest = text[start.upperBound...]
            if rest.lowercased().hasPrefix("json") {
                rest = rest.dropFirst(4)
            }
            if let end = rest.range(of: "```") {
                if let object = decodeJSON(String(rest[..<end.lowerBound])) { return object }
            }
        }
        if let first = text.firstIndex(of: "{"), let last = text.lastIndex(of: "}"), first < last {
            return decodeJSON(String(text[first...last]))
        }
        return nil
    }

    private static func decodeJSON(_ text: String) -> [String: Any]? {
        let data = Data(text.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func strippedFences(_ text: String) -> String {
        var value = text
        if value.hasPrefix("```") {
            value = String(value.drop(while: { $0 != "\n" }).dropFirst())
            if let end = value.range(of: "```") { value = String(value[..<end.lowerBound]) }
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func string(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }

    private static func number(_ object: [String: Any], keys: [String]) -> CGFloat? {
        for key in keys {
            if let value = object[key] as? Double { return CGFloat(value) }
            if let value = object[key] as? Int { return CGFloat(value) }
            if let value = object[key] as? String, let parsed = Double(value.trimmingCharacters(in: .whitespaces)) {
                return CGFloat(parsed)
            }
        }
        return nil
    }

    private static func alignment(from raw: String?) -> TextAlignment? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["left", "leading", "start", "左", "左对齐", "靠左"].contains(value) { return .left }
        if ["center", "centre", "middle", "中", "居中", "置中"].contains(value) { return .center }
        if ["right", "trailing", "end", "右", "右对齐", "靠右"].contains(value) { return .right }
        return nil
    }

    private static func color(in object: [String: Any]) -> (CGFloat?, CGFloat?, CGFloat?) {
        if let hex = string(object, keys: ["color", "hex", "fill"]) {
            if let rgb = hexColor(hex) { return rgb }
        }
        var red = number(object, keys: ["red", "r"])
        var green = number(object, keys: ["green", "g"])
        var blue = number(object, keys: ["blue", "b"])
        if let r = red, let g = green, let b = blue, r > 1 || g > 1 || b > 1 {
            red = min(1, r / 255); green = min(1, g / 255); blue = min(1, b / 255)
        }
        return (red, green, blue)
    }

    private static func hexColor(_ raw: String) -> (CGFloat, CGFloat, CGFloat)? {
        var hex = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        return (
            CGFloat((value >> 16) & 0xFF) / 255,
            CGFloat((value >> 8) & 0xFF) / 255,
            CGFloat(value & 0xFF) / 255
        )
    }
}
