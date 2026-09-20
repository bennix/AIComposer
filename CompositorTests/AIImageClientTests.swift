import Foundation
import Testing
@testable import Compositor

struct AIImageClientTests {
    @Test func parsesOpenAIBase64AndVertexInlineImage() throws {
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        let openAI = """
        {"data":[{"b64_json":"\(png.base64EncodedString())","revised_prompt":"otter"}]}
        """.data(using: .utf8)!
        let parsed = try AIImageClient.parseOpenAIImage(openAI)
        #expect(parsed.data == png)
        #expect(parsed.revisedPrompt == "otter")

        let vertex = """
        {"candidates":[{"content":{"parts":[{"text":"ok"},{"inlineData":{"mimeType":"image/png","data":"\(png.base64EncodedString())"}}]}}]}
        """.data(using: .utf8)!
        #expect(try AIImageClient.parseVertexImage(vertex).data == png)
    }

    @Test func vertexURLUsesGooglePublisher() {
        let url = AIImageClient.vertexGenerateURL(
            from: URL(string: "https://zenmux.ai/api/v1")!,
            model: .gemini
        )
        #expect(url.absoluteString == "https://zenmux.ai/api/vertex-ai/v1/publishers/google/models/gemini-3.1-flash-lite-image:generateContent")
    }

    @Test func httpErrorReadsNestedMessage() {
        let data = #"{"error":{"message":"invalid api key"}}"#.data(using: .utf8)!
        #expect(AIImageClient.message(from: data, status: 401) == "invalid api key")
    }

    @Test func combinedPromptKeepsGenerateTextAndPrefixesEdits() {
        #expect(AIImagePipeline.combinedPrompt(kind: .generate, extra: "  a cat  ") == "a cat")
        #expect(AIImagePipeline.combinedPrompt(kind: .fill, extra: "").contains("Fill the transparent"))
        #expect(AIImagePipeline.combinedPrompt(kind: .restyle, extra: "oil").contains("Additional instruction: oil"))
        #expect(AIImagePipeline.combinedPrompt(kind: .expand, extra: "").contains("inner rectangle")
            || AIImagePipeline.combinedPrompt(kind: .expand, extra: "").contains("ai.prompt.expandSeam"))
        #expect(AIImageSize.matching(width: 1600, height: 1000) == .landscape)
        #expect(AIImageSize.matching(width: 1000, height: 1600) == .portrait)
        #expect(AIImageSize.matching(width: 1024, height: 1024) == .square)
    }

    @Test func vertexPartsSendBackgroundMaskAndPromptTogether() {
        let image = Data([1, 2, 3])
        let coverage = Data([4, 5, 6])
        let request = AIImageRequest(
            credentials: AICredentials(baseURL: "https://zenmux.ai/api/v1", apiKey: "k", defaultModel: AIImageModel.gemini.rawValue),
            model: .gemini,
            prompt: "add a red bow",
            size: .square,
            imagePNG: image,
            coveragePNG: coverage,
            selectionHint: "The selected region in this image is x=10 y=8 width=12 height=10"
        )
        let parts = AIImageClient.vertexParts(request)
        let texts = parts.compactMap { $0["text"] as? String }
        #expect(texts.contains(L10n.t("ai.prompt.backgroundPhoto")))
        #expect(texts.contains(L10n.t("ai.prompt.selectionMask")))
        #expect(texts.contains("add a red bow"))
        #expect(texts.contains { $0.contains("x=10") })
        #expect(parts.filter { $0["inlineData"] != nil }.count == 2)
    }
}

nonisolated private struct StubSession: AIURLSessioning {
    let data: Data
    let status: Int
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

struct AIImageClientNetworkTests {
    @Test func testKeyCountsModels() async throws {
        let payload = #"{"data":[{"id":"a"},{"id":"b"}]}"#.data(using: .utf8)!
        let client = AIImageClient(session: StubSession(data: payload, status: 200), timeout: 2)
        let credentials = AICredentials(baseURL: "https://zenmux.ai/api/v1", apiKey: "k", defaultModel: AIImageModel.gptImage.rawValue)
        #expect(try await client.testKey(credentials).contains("2 models"))
    }

    @Test func testKeySurfacesUnauthorized() async {
        let payload = #"{"error":{"message":"bad key"}}"#.data(using: .utf8)!
        let client = AIImageClient(session: StubSession(data: payload, status: 401), timeout: 2)
        let credentials = AICredentials(baseURL: "https://zenmux.ai/api/v1", apiKey: "k", defaultModel: AIImageModel.gptImage.rawValue)
        await #expect(throws: AIImageError.self) {
            _ = try await client.testKey(credentials)
        }
    }
}
