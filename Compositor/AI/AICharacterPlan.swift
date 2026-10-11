import Foundation

nonisolated enum AIReferenceRole: String, CaseIterable, Identifiable, Sendable {
    case inspiration, face, clothing, scene, pose
    var id: String { rawValue }
    var title: String {
        switch self {
        case .inspiration: "灵感"
        case .face: "身份脸图"
        case .clothing: "服饰"
        case .scene: "场景"
        case .pose: "姿态"
        }
    }
    var targetsPerson: Bool { self == .face || self == .clothing || self == .pose }
}

nonisolated struct AICharacterReference: Sendable {
    var id: UUID
    var role: AIReferenceRole
    var personID: UUID?
    var detail: String = ""
}

nonisolated struct AICharacter: Identifiable, Sendable {
    var id = UUID()
    var description = ""
    var replaceFace = false
    var changeClothes = false
    var clothing = ""
}

nonisolated struct AICharacterPlan: Sendable {
    var enabled = false
    var people: [AICharacter] = [AICharacter()]
    var arrangement = ""
    var changeScene = false
    var scene = ""
    var usePose = false
    var poseGuidePNG: Data?
    var poseDocument = ""

    mutating func setCount(_ count: Int) {
        let count = min(max(count, 1), 5)
        guard count != people.count else { return }
        if count < people.count { people.removeLast(people.count - count) }
        else { people.append(contentsOf: (people.count..<count).map { _ in AICharacter() }) }
        poseGuidePNG = nil
    }

    func validation(references: [AICharacterReference]) -> String? {
        guard enabled else { return nil }
        let ids = Set(people.map(\.id))
        for (index, reference) in references.enumerated() where reference.role.targetsPerson {
            guard let personID = reference.personID, ids.contains(personID) else {
                return "请为参考图 \(index + 1) 的\(reference.role.title)指定当前人物。"
            }
        }
        for (index, person) in people.enumerated() {
            if person.replaceFace && !references.contains(where: { $0.role == .face && $0.personID == person.id }) {
                return "人物 \(index + 1) 换脸需要指定身份脸图。"
            }
            if person.changeClothes && person.clothing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !references.contains(where: { $0.role == .clothing && $0.personID == person.id }) {
                return "请为人物 \(index + 1) 提供服饰参考或换衣描述。"
            }
        }
        if changeScene && scene.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !references.contains(where: { $0.role == .scene }) {
            return "请提供场景参考或换场景描述。"
        }
        if usePose && poseGuidePNG == nil { return "请在 IK 人偶编辑器中保存当前人数的姿态引导图。" }
        return nil
    }

    func instructions(references: [AICharacterReference]) -> String {
        guard enabled else { return "" }
        var lines = ["人物创作：成品中恰好 \(people.count) 人，仅生成一个完整画面，不添加、复制或遗漏人物，不输出分栏、多视角或对照图。"]
        if !arrangement.isEmpty { lines.append("人物空间与互动：\(arrangement)") }
        for (index, person) in people.enumerated() {
            let label = "人物 \(index + 1)"
            if !person.description.isEmpty { lines.append("\(label)：\(person.description)") }
            let assigned = references.enumerated().filter { $0.element.personID == person.id }
            for (offset, reference) in assigned where reference.role.targetsPerson {
                lines.append("参考图 \(offset + 1) 对应\(label)的\(reference.role.title)；\(reference.detail.isEmpty ? "仅用于此指定用途。" : reference.detail)")
            }
            if person.replaceFace {
                let faces = assigned.filter { $0.element.role == .face }.map { String($0.offset + 1) }.joined(separator: "、")
                lines.append("\(label)换脸 / 身份锁定：参考图 \(faces) 是此人物的唯一权威身份来源。严格保持参考脸可见的生物形态特征：头骨与骨相、脸型、额头、发际线、颧骨、下颌与下巴、五官相对位置和比例、眼距、眼形与眼睑、眉形、鼻梁/鼻尖/鼻翼、嘴唇与嘴角、耳形、肤色与可见痣/雀斑等辨识特征。不得平均融合其他人的脸，不美颜改骨相，不改变年龄外观或族裔特征，不借用服装图、场景图、人偶或其他人物的脸。仅调整匹配姿态与场景所需的透视、表情和光照；不可辨认的特征不凭空补成另一张脸。人脸图不决定服装、体态或背景。")
            } else { lines.append("\(label)：已有画面中保留原有身份与面部特征；新创作按此人物的描述确定身份。换衣、换场景或摆姿态不应改变其脸，不混用其他人物的身份。") }
            if person.changeClothes {
                lines.append("\(label)换衣：\(person.clothing.isEmpty ? "依据该人物的服饰参考" : person.clothing)。保持此人物脸部身份与身体比例；按姿态匹配衣服剪裁、褶皱、遮挡与材质。服饰参考只控制衣物，不复制其模特的脸或背景。")
            } else { lines.append("\(label)：已有画面保留原服装；新创作依据主体与此人物描述设计服装，不从身份脸图自动复制衣物。") }
        }
        if changeScene {
            let scenes = references.enumerated().filter { $0.element.role == .scene }.map { "参考图 \($0.offset + 1)" }.joined(separator: "、")
            lines.append("换场景：\(scene)\(scenes.isEmpty ? "" : "；场景来源：" + scenes)。只替换环境，保持各人物的身份、人数、指定姿态与服饰；统一透视、照明、接触阴影与遮挡。场景图内的人物不是新增角色或身份来源。")
        } else { lines.append("已有画面保留原场景；新创作依据主体描述确定环境。场景参考不自动触发背景替换。") }
        if usePose {
            lines.append("另附的『IK 人偶姿态引导图』只控制各编号人物的位置、肢体姿态、朝向和相互遮挡。编号与人物编号一一对应，不把人偶材质、颜色、无五官面部或图上的数字画进成品。已编辑的 IK 姿态优先于其他参考图中的动作，用户姿态参考仅补充未覆盖且不冲突的细节。身份脸图优先决定人脸，服饰参考只决定衣服，场景参考只决定环境；相互不得串用。")
        }
        return lines.joined(separator: "\n")
    }
}
