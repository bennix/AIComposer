import Foundation
import Testing
@testable import Compositor

struct AIPromptGalleryTests {
    @Test func entireSnapshotHasObservedRecipesAndAttribution() throws {
        let gallery = try AIPromptGallery.load()
        let library = try AIPromptVisualLibrary.load(gallery: gallery)
        #expect(gallery.entries.count == 5424)
        #expect(library.assignments.count == 5424)
        #expect(library.recipes.count == 24)
        #expect(gallery.entries.allSatisfy {
            !library.facets(for: $0).isEmpty && $0.source.hasPrefix("https://opennana.com/awesome-prompt-gallery/")
        })
        let reference = try #require(gallery.entries.first)
        var brief = AICreativeBrief(subject: "一位撑伞的旅人", purpose: "杂志封面")
        brief.useFacets(library.facets(for: reference))
        #expect(brief.prompt.contains("一位撑伞的旅人"))
        #expect(brief.prompt.contains("杂志封面"))
        #expect(!brief.prompt.contains("双11"))
        #expect(!brief.prompt.contains("[subject]"))
    }

    @Test func rejectsIncompleteReviewMapping() throws {
        let gallery = try AIPromptGallery.load()
        let library = try AIPromptVisualLibrary.load(gallery: gallery)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(library)) as? [String: Any])
        object["assignments"] = [:] as [String: String]
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) { try AIPromptVisualLibrary.decode(data, gallery: gallery) }
    }

    @Test func rejectsChangedSampleImageInRefreshedCatalogue() throws {
        let gallery = try AIPromptGallery.load()
        let library = try AIPromptVisualLibrary.load(gallery: gallery)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(gallery)) as? [String: Any])
        var entries = try #require(object["entries"] as? [[String: Any]])
        entries[0]["thumbnail"] = "https://example.com/replaced.jpg"
        object["entries"] = entries
        let changed = try AIPromptGallery.decode(JSONSerialization.data(withJSONObject: object))
        let data = try JSONEncoder().encode(library)
        #expect(throws: (any Error).self) { try AIPromptVisualLibrary.decode(data, gallery: changed) }
    }

    @Test func facetChangesReplaceDimensionAndPreserveIntent() {
        let first = AIPromptFacet(id: "a", dimension: "光线", title: "暖光", instruction: "Warm light")
        let second = AIPromptFacet(id: "b", dimension: "光线", title: "冷光", instruction: "Cool light")
        var brief = AICreativeBrief(subject: "旅人", purpose: "封面", direction: "保留伞")
        brief.toggleFacet(first)
        brief.toggleFacet(second)
        #expect(brief.facets == [second])
        brief.useFacets([first])
        #expect(brief.facets == [first])
        #expect(brief.subject == "旅人" && brief.purpose == "封面" && brief.direction == "保留伞")
        brief.toggleFacet(first)
        #expect(brief.facets.isEmpty)
    }
}

struct AIReferenceImageTests {
    @Test func promptRenumbersAfterDeletionWithoutDuplicatingDirective() {
        let base = "画一座山，保留我修改的描述"
        let three = AIReferenceImage.prompt(base, count: 3)
        #expect(three.contains("参考图 1、2、3"))
        let editable = AIReferenceImage.editableBase(three, count: 3)
        let two = AIReferenceImage.prompt(editable, count: 2)
        #expect(two.contains("参考图 1、2"))
        #expect(!two.contains("1、2、3"))
        #expect(two.hasSuffix(base))
        #expect(AIReferenceImage.prompt(editable, count: 0) == base)
    }

    @Test func vertexReferencesKeepNumberedOrderSeparateFromBackground() throws {
        let credentials = AICredentials(baseURL: "https://example.com/v1", apiKey: "test", defaultModel: AIImageModel.gemini.rawValue)
        let request = AIImageRequest(credentials: credentials, model: .gemini, prompt: "mountain", size: .square,
                                     referencePNGs: [Data("one".utf8), Data("two".utf8)], imagePNG: Data("background".utf8))
        let parts = AIImageClient.vertexParts(request)
        let images = parts.compactMap { ($0["inlineData"] as? [String: String])?["data"] }
        #expect(images == ["background", "one", "two"].map { Data($0.utf8).base64EncodedString() })
        #expect(parts.compactMap { $0["text"] as? String }.contains { $0.hasPrefix("参考图 2") })
    }

    @Test func rejectsMoreThanFiveReferencesBeforeNetworking() async {
        let credentials = AICredentials(baseURL: "https://example.com/v1", apiKey: "test", defaultModel: AIImageModel.gemini.rawValue)
        let request = AIImageRequest(credentials: credentials, model: .gemini, prompt: "mountain", size: .square,
                                     referencePNGs: Array(repeating: Data("image".utf8), count: 6))
        await #expect(throws: AIImageError.self) {
            _ = try await AIImageClient(session: ReferenceRequestSession()).generate(request)
        }
    }

    @Test func openAIReferenceGenerationUsesImageEditEndpointAndAllImages() async throws {
        let credentials = AICredentials(baseURL: "https://example.com/v1", apiKey: "test", defaultModel: AIImageModel.gptImage.rawValue)
        let request = AIImageRequest(credentials: credentials, model: .gptImage, prompt: "mountain", size: .square,
                                     referencePNGs: [Data("first-image".utf8), Data("second-image".utf8)])
        _ = try await AIImageClient(session: ReferenceRequestSession()).generate(request)
    }
}

nonisolated private struct ReferenceRequestSession: AIURLSessioning {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #expect(request.url?.path == "/v1/images/edits")
        let body = String(decoding: request.httpBody ?? Data(), as: UTF8.self)
        #expect(body.components(separatedBy: "name=\"image[]\"").count == 3)
        #expect(body.contains("first-image") && body.contains("second-image"))
        let data = Data(#"{"data":[{"b64_json":"aW1hZ2U="}]}"#.utf8)
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
