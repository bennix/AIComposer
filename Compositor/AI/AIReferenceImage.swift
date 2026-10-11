import Foundation
import AppKit

struct AIReferenceImage: Identifiable {
    let id = UUID()
    let png: Data
    let thumbnail: NSImage
    var role: AIReferenceRole = .inspiration
    var personID: UUID?
    var detail = ""

    var characterReference: AICharacterReference {
        AICharacterReference(id: id, role: role, personID: personID, detail: detail)
    }

    init(data: Data) throws {
        let image = try AIImagePipeline.image(from: data)
        let scaled = try AIImagePipeline.scaledForUpload(image)
        png = try AIImagePipeline.pngData(from: scaled)
        thumbnail = NSImage(cgImage: try PixelAdjust.thumbnail(of: image), size: .zero)
    }

    static let limit = 5

    static func instruction(count: Int) -> String {
        guard count > 0 else { return "" }
        let numbers = (1...min(count, limit)).map(String.init).joined(separator: "、")
        return "基于参考图 \(numbers)，结合下述主体与创作意图生成新画面；借鉴参考图的视觉特征，保留用户指定内容。参考图按用户所选图片的顺序编号；画布背景与 IK 姿态图另行标记。"
    }

    static func prompt(_ base: String, count: Int) -> String {
        let directive = instruction(count: count)
        return directive.isEmpty ? base : directive + "\n" + base
    }

    static func context(images: [AIReferenceImage], plan: AICharacterPlan) -> String {
        [instruction(count: images.count), plan.instructions(references: images.map(\.characterReference))]
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }

    static func prompt(_ base: String, images: [AIReferenceImage], plan: AICharacterPlan) -> String {
        let context = context(images: images, plan: plan)
        return context.isEmpty ? base : context + "\n" + base
    }

    static func editableBase(_ text: String, images: [AIReferenceImage], plan: AICharacterPlan) -> String {
        let prefix = context(images: images, plan: plan) + "\n"
        return text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
    }

    static func editableBase(_ text: String, count: Int) -> String {
        let prefix = instruction(count: count) + "\n"
        return count > 0 && text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
    }
}
