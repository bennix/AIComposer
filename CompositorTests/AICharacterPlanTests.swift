import Foundation
import Testing
@testable import Compositor

struct AICharacterPlanTests {
    @Test func composesStackedEditsWithSeparateIdentityAnchors() {
        var plan = AICharacterPlan(enabled: true)
        plan.setCount(2)
        plan.people[0].replaceFace = true
        plan.people[1].replaceFace = true
        plan.people[0].changeClothes = true
        plan.people[0].clothing = "蓝色风衣"
        plan.changeScene = true
        plan.scene = "雨后街角"
        plan.arrangement = "人物 1 在左，人物 2 在右"
        plan.usePose = true
        plan.poseGuidePNG = Data([1])
        let refs = [AICharacterReference(id: UUID(), role: .face, personID: plan.people[0].id),
                    AICharacterReference(id: UUID(), role: .face, personID: plan.people[1].id)]
        #expect(plan.validation(references: refs) == nil)
        let prompt = plan.instructions(references: refs)
        #expect(prompt.contains("恰好 2 人"))
        #expect(prompt.contains("参考图 1 对应人物 1的身份脸图"))
        #expect(prompt.contains("参考图 2 对应人物 2的身份脸图"))
        #expect(prompt.contains("蓝色风衣") && prompt.contains("雨后街角"))
        #expect(prompt.contains("不得平均融合其他人的脸"))
        #expect(prompt.contains("IK 人偶姿态引导图"))
    }

    @Test func removingReferenceRenumbersOtherPersonWithoutReassigningIdentity() {
        var plan = AICharacterPlan(enabled: true)
        plan.setCount(2)
        plan.people[1].replaceFace = true
        let first = AICharacterReference(id: UUID(), role: .inspiration, personID: nil)
        let second = AICharacterReference(id: UUID(), role: .face, personID: plan.people[1].id)
        #expect(plan.instructions(references: [first, second]).contains("参考图 2 对应人物 2"))
        #expect(plan.instructions(references: [second]).contains("参考图 1 对应人物 2"))
        #expect(plan.validation(references: []) != nil)
        let stableID = plan.people[0].id
        plan.poseGuidePNG = Data([1])
        plan.setCount(1)
        #expect(plan.people[0].id == stableID)
        #expect(plan.poseGuidePNG == nil)
        #expect(plan.validation(references: [second]) != nil)
    }

    @Test func requiresExplicitPeopleAndSourcesForStackedChanges() {
        var plan = AICharacterPlan(enabled: true)
        let unassigned = AICharacterReference(id: UUID(), role: .face, personID: nil)
        #expect(plan.validation(references: [unassigned]) != nil)
        plan.people[0].changeClothes = true
        #expect(plan.validation(references: []) != nil)
        plan.people[0].clothing = "白色衬衫"
        plan.changeScene = true
        #expect(plan.validation(references: []) != nil)
        plan.scene = "海边"
        plan.usePose = true
        #expect(plan.validation(references: []) != nil)
        plan.poseGuidePNG = Data([1])
        #expect(plan.validation(references: []) == nil)
        plan.enabled = false
        #expect(plan.instructions(references: [unassigned]).isEmpty)
        #expect(plan.validation(references: [unassigned]) == nil)
    }

    @Test func transportSeparatesBackgroundFiveReferencesAndIKGuide() {
        let credentials = AICredentials(baseURL: "https://example.com/v1", apiKey: "test", defaultModel: AIImageModel.gemini.rawValue)
        let request = AIImageRequest(credentials: credentials, model: .gemini, prompt: "two people", size: .square,
                                     referencePNGs: (1...5).map { Data("ref-\($0)".utf8) }, poseGuidePNG: Data("pose".utf8), imagePNG: Data("background".utf8))
        let mapping = AIImageClient.attachmentInstruction(request)
        #expect(mapping.contains("附图 2 = 用户参考图 1"))
        #expect(mapping.contains("附图 6 = 用户参考图 5"))
        #expect(mapping.contains("附图 7 = IK 人偶姿态引导图"))
        let data = AIImageClient.vertexParts(request).compactMap { ($0["inlineData"] as? [String: String])?["data"] }
        #expect(data.count == 7)
        #expect(data.first == Data("background".utf8).base64EncodedString())
        #expect(data.last == Data("pose".utf8).base64EncodedString())
    }
}
