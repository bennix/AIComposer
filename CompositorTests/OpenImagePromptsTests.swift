import Foundation
import CryptoKit
import Testing
@testable import Compositor

struct OpenImagePromptsTests {
    @Test func allCardsHaveProvenanceAndRealReferenceIDs() throws {
        let cards = try OIPStyleCard.load()
        #expect(cards.count == 39)
        #expect(cards.allSatisfy { !$0.template.isEmpty && $0.source.hasPrefix("https://github.com/NanmiCoder/open-image-prompts/") })
        #expect(cards.contains { $0.experimental })
        #expect(cards.filter { $0.references.isEmpty }.count == 12)
    }

    @Test func fullArchiveCountsAndOriginalBytesArePreserved() async throws {
        let stats = try await OIPArchive.shared.statistics()
        #expect(stats.prompts == 23196)
        #expect(stats.images == 38519)
        let record = try #require(try await OIPArchive.shared.records(ids: ["1902660914786230569"]).first)
        #expect(record.author == "azed_ai")
        #expect(record.source == "https://x.com/azed_ai/status/1902660914786230569")
        #expect(SHA256.hash(data: Data(record.original.utf8)).map { String(format: "%02x", $0) }.joined() == "128a364323fe0501921a807b50ae9edf03513df5bf2dc3cf485df7b1a15c7486")
        #expect(!record.images.isEmpty)
    }

    @Test func availableCardReferencesResolveAndMissingIDsAreExplicit() async throws {
        let cards = try OIPStyleCard.load()
        let ids = Array(Set(cards.flatMap(\.references)))
        let records = try await OIPArchive.shared.records(ids: ids)
        #expect(Set(ids).subtracting(Set(records.map(\.id))) == ["2072542433213391291", "2073830761359372552", "2047968525243826505"])
        #expect(records.allSatisfy { !$0.original.isEmpty && !$0.author.isEmpty && !$0.images.isEmpty })
    }

    @Test func intentRetainsForbiddenRulesAndUnrecognizedSubjects() throws {
        let config = try OIPResources.decode(OIPIntentConfig.self, "Intent")
        let taxonomy = try OIPResources.decode(OIPTaxonomy.self, "Taxonomy")
        let intent = OIPIntent.parse("portrait no text no watermark emerald otter", config: config, taxonomy: taxonomy)
        #expect(intent.must.contains("subject_type:portrait"))
        #expect(intent.forbidden.contains("quality_flags:embedded-text"))
        #expect(intent.forbidden.contains("quality_flags:logo-watermark"))
        #expect(intent.groups.contains(["emerald"]))
        #expect(!OIPIntent.contains("cartography", "art"))
        #expect(OIPIntent.contains("art photography", "art"))
    }

    @Test func searchPreservesSubjectsAndDisclosesSingleMissingFacet() async throws {
        let result = try await OIPArchive.shared.search("portrait no text")
        #expect(!result.exact.isEmpty)
        #expect(result.exact.allSatisfy { $0.tags.contains("subject_type:portrait") && !$0.tags.contains("quality_flags:embedded-text") && $0.missing.isEmpty })
        let impossible = try await OIPArchive.shared.search("impossiblesubjectxyz987 watercolor")
        #expect(impossible.exact.isEmpty && impossible.related.isEmpty)
        let related = try await OIPArchive.shared.search("portrait watercolor neon no watermark")
        #expect(related.related.allSatisfy { $0.missing.count == 1 && $0.tags.contains("subject_type:portrait") && !$0.tags.contains("quality_flags:logo-watermark") })
    }

    @Test func handoffPreservesInvariantsAndDoesNotSendUnfilledTemplate() throws {
        var spec = OIPCreativeSpec(subject: "an otter", use: "book cover")
        spec.styleCardId = "product-white-gallery-high-key"
        spec.invariants = ["exact words: Sea Study"]
        spec.avoid = ["no extra people"]
        spec.aspectRatio = "16:9"
        let object = try #require(JSONSerialization.jsonObject(with: Data(spec.handoff.utf8)) as? [String: Any])
        let payload = try #require(object["creative_spec"] as? [String: Any])
        #expect(payload["style_card_id"] as? String == spec.styleCardId)
        #expect(payload["aspect_ratio"] as? String == "16:9")
        #expect(spec.prompt.contains("an otter") && spec.prompt.contains("Sea Study") && spec.prompt.contains("no extra people"))
        #expect(!spec.prompt.contains("{PRODUCT}"))
    }

    @Test func rejectsUnsafeImagePathsAndIncompleteDerivedPrompts() {
        #expect(OIPImageStore.safePath("images/123/1.jpg"))
        #expect(!OIPImageStore.safePath("images/../../outside.jpg"))
        #expect(!OIPImageStore.safePath("/tmp/images/1.jpg"))
        #expect(!OIPImageStore.safePath("images/123/../outside.jpg"))
        #expect(throws: (any Error).self) { try OIPDerivedPrompt.parse(#"{"english":"ok","chinese":"","rationale":"x"}"#) }
    }
}

private actor OIPMockSession: AIURLSessioning {
    var request: URLRequest?
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.request = request
        let content = #"{"english":"An otter on ivory paper.","chinese":"米白纸上的水獭。","rationale":"Text adaptation from supplied source."}"#
        let data = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": content]]]])
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

extension OpenImagePromptsTests {
    @Test func adaptationUsesSelectedSourcesAndSeparateBilingualOutput() async throws {
        let session = OIPMockSession()
        let client = AIImageClient(session: session)
        let source = OIPRecord(id: "123", author: "creator", tool: "test", source: "https://x.com/creator/status/123",
                               original: "Original source text.\nKeep this unchanged.", zh: "译文", en: "", images: [], tags: [])
        let spec = OIPCreativeSpec(subject: "an otter", use: "cover")
        let output = try await client.deriveOIPPrompt(credentials: AICredentials(baseURL: "https://example.com/v1", apiKey: "test-key", defaultModel: "test"),
            spec: spec, direction: spec.prompt, sources: [source], referencePNGs: [])
        #expect(output.english == "An otter on ivory paper.")
        #expect(output.chinese == "米白纸上的水獭。")
        #expect(source.original == "Original source text.\nKeep this unchanged.")
        let request = try #require(await session.request)
        let body = try #require(request.httpBody)
        let text = String(decoding: body, as: UTF8.self)
        #expect(text.contains("source_prompt") && text.contains("123") && text.contains("creative_spec"))
        #expect(!text.contains("data:image"))
        #expect(request.url?.path == "/v1/chat/completions")
    }
}

extension OpenImagePromptsTests {
    @MainActor @Test func everyImageIsBuiltInWithNoNetworkFallback() async throws {
        struct Inventory: Decodable {
            struct Image: Decodable { let path: String; let bytes: Int }
            let count: Int
            let images: [Image]
        }
        for (name, count) in [("OpenImagePromptsImages", 38519), ("OpenNanaImages", 5424)] {
            let root = try #require(Bundle.main.url(forResource: name, withExtension: "bundle"))
            let inventory = try JSONDecoder().decode(Inventory.self, from: Data(contentsOf: root.appending(path: "Inventory.json")))
            #expect(inventory.count == count && inventory.images.count == count)
            let missing = inventory.images.filter { image in
                let path = root.appending(path: image.path).path
                let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue
                return size != image.bytes || image.bytes == 0
            }
            #expect(missing.isEmpty)
        }
        let image = OIPImage(id: "missing", recordID: "missing", url: "https://example.invalid/must-not-be-fetched", path: "images/missing/missing.jpg")
        #expect(OIPImageStore.shared.localURL(image) == nil)
        do {
            _ = try await OIPImageStore.shared.data(for: image)
            Issue.record("A missing bundled image must fail locally")
        } catch let error as CocoaError { #expect(error.code == .fileNoSuchFile) }
        catch { Issue.record("Unexpected network/error fallback: \(error)") }
        let gallery = try AIPromptGallery.load()
        #expect(gallery.entries.allSatisfy { $0.bundledThumbnailURL != nil })
    }
}
