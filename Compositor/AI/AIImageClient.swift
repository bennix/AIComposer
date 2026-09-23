import Foundation

nonisolated struct AIGeneratedImage: Sendable {
    let data: Data
    var revisedPrompt: String?
}

nonisolated struct AIImageRequest: Sendable {
    var credentials: AICredentials
    var model: AIImageModel
    var prompt: String
    var size: AIImageSize
    var quality: String = "auto"
    var imagePNG: Data? = nil
    /// OpenAI Images alpha mask (transparent = edit).
    var maskPNG: Data? = nil
    /// Same-size black/white selection mask for Vertex / Gemini.
    var coveragePNG: Data? = nil
    var selectionHint: String? = nil
}

nonisolated protocol AIURLSessioning: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

nonisolated extension URLSession: AIURLSessioning {}

nonisolated struct AIImageClient: Sendable {
    var session: any AIURLSessioning
    var timeout: TimeInterval

    init(session: any AIURLSessioning = URLSession(configuration: Self.configuration()),
         timeout: TimeInterval = 180) {
        self.session = session
        self.timeout = timeout
    }

    static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 180
        return configuration
    }

    func testKey(_ credentials: AICredentials) async throws -> String {
        let value = credentials.trimmed
        guard let base = value.endpoint else { throw AICredentialError.invalidURL }
        guard value.hasAPIKey else { throw AICredentialError.missingKey }
        var request = URLRequest(url: base.appending(path: "models"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(value.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        let (data, response) = try await session.data(for: request)
        try Self.throwIfFailed(data: data, response: response)
        if let count = Self.modelCount(in: data) {
            return L10n.format("API key works. %d models are visible on this account.", count)
        }
        return L10n.t("API key works.")
    }

    func generate(_ request: AIImageRequest) async throws -> AIGeneratedImage {
        if request.model.usesVertex {
            return try await generateVertex(request)
        }
        if request.imagePNG != nil {
            return try await editOpenAI(request)
        }
        return try await generateOpenAI(request)
    }

    func generateOpenAI(_ request: AIImageRequest) async throws -> AIGeneratedImage {
        let credentials = request.credentials.trimmed
        guard let base = credentials.endpoint else { throw AICredentialError.invalidURL }
        var http = URLRequest(url: base.appending(path: "images/generations"))
        http.httpMethod = "POST"
        http.setValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")
        http.setValue("application/json", forHTTPHeaderField: "Content-Type")
        http.timeoutInterval = timeout
        http.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": request.model.rawValue,
            "prompt": request.prompt,
            "n": 1,
            "size": request.size.rawValue,
            "quality": request.quality
        ])
        let (data, response) = try await session.data(for: http)
        try Self.throwIfFailed(data: data, response: response)
        return try Self.parseOpenAIImage(data)
    }

    func editOpenAI(_ request: AIImageRequest) async throws -> AIGeneratedImage {
        let credentials = request.credentials.trimmed
        guard let base = credentials.endpoint, let image = request.imagePNG else {
            throw AICredentialError.invalidURL
        }
        var prompt = request.prompt
        if let hint = request.selectionHint, !hint.isEmpty, !prompt.contains(hint) {
            prompt += " " + hint
        }
        var form = MultipartForm()
        form.add("model", request.model.rawValue)
        form.add("prompt", prompt)
        form.add("n", "1")
        form.add("size", request.size.rawValue)
        form.addFile("image", filename: "image.png", mime: "image/png", data: image)
        if let mask = request.maskPNG {
            form.addFile("mask", filename: "mask.png", mime: "image/png", data: mask)
        }
        var http = URLRequest(url: base.appending(path: "images/edits"))
        http.httpMethod = "POST"
        http.setValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")
        http.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        http.timeoutInterval = timeout
        http.httpBody = form.finished
        let (data, response) = try await session.data(for: http)
        try Self.throwIfFailed(data: data, response: response)
        return try Self.parseOpenAIImage(data)
    }

    func generateVertex(_ request: AIImageRequest) async throws -> AIGeneratedImage {
        let credentials = request.credentials.trimmed
        guard let openAI = credentials.endpoint else { throw AICredentialError.invalidURL }
        let url = Self.vertexGenerateURL(from: openAI, model: request.model)
        let parts = Self.vertexParts(request)
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": parts]],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"],
                "imageConfig": [
                    "aspectRatio": request.size.aspectRatio,
                    "imageSize": "1K"
                ]
            ]
        ]
        var http = URLRequest(url: url)
        http.httpMethod = "POST"
        http.setValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")
        http.setValue("application/json", forHTTPHeaderField: "Content-Type")
        http.timeoutInterval = timeout
        http.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: http)
        try Self.throwIfFailed(data: data, response: response)
        return try Self.parseVertexImage(data)
    }

    func recognizeText(credentials: AICredentials, imagePNG: Data, extra: String = "") async throws -> AIRecognizedText {
        let value = credentials.trimmed
        guard let base = value.endpoint else { throw AICredentialError.invalidURL }
        guard value.hasAPIKey else { throw AICredentialError.missingKey }
        var http = URLRequest(url: base.appending(path: "chat/completions"))
        http.httpMethod = "POST"
        http.setValue("Bearer \(value.apiKey)", forHTTPHeaderField: "Authorization")
        http.setValue("application/json", forHTTPHeaderField: "Content-Type")
        http.timeoutInterval = timeout
        http.httpBody = try JSONSerialization.data(withJSONObject: AIRecognizedText.chatBody(
            model: value.effectiveMultimodalModel,
            imagePNG: imagePNG,
            extra: extra
        ))
        let (data, response) = try await session.data(for: http)
        try Self.throwIfFailed(data: data, response: response)
        return try AIRecognizedText.parse(AIRecognizedText.parseChatContent(data))
    }

    /// Background photograph, same-size selection mask, and the edit prompt in one request.
    static func vertexParts(_ request: AIImageRequest) -> [[String: Any]] {
        var parts: [[String: Any]] = []
        if let image = request.imagePNG {
            parts.append(["text": L10n.t("ai.prompt.backgroundPhoto")])
            parts.append(["inlineData": ["mimeType": "image/png", "data": image.base64EncodedString()]])
        }
        if let coverage = request.coveragePNG {
            parts.append(["text": L10n.t("ai.prompt.selectionMask")])
            parts.append(["inlineData": ["mimeType": "image/png", "data": coverage.base64EncodedString()]])
        } else if let mask = request.maskPNG {
            parts.append(["text": L10n.t("ai.prompt.mask")])
            parts.append(["inlineData": ["mimeType": "image/png", "data": mask.base64EncodedString()]])
        }
        parts.append(["text": L10n.t("ai.prompt.editInstruction")])
        parts.append(["text": request.prompt])
        if let hint = request.selectionHint, !hint.isEmpty {
            parts.append(["text": hint])
        }
        if request.coveragePNG != nil || request.maskPNG != nil {
            parts.append(["text": L10n.t("ai.prompt.returnEditedPhoto")])
            parts.append(["text": L10n.t("ai.prompt.noBorder")])
        }
        parts.append(["text": L10n.t("ai.prompt.fillFrame")])
        return parts
    }

    static func vertexGenerateURL(from openAIBase: URL, model: AIImageModel) -> URL {
        let slug = model.rawValue.split(separator: "/", maxSplits: 1)
        let provider = slug.first.map(String.init) ?? "google"
        let name = slug.count > 1 ? String(slug[1]) : model.rawValue
        var root = openAIBase.absoluteString
        if root.hasSuffix("/") { root.removeLast() }
        if root.hasSuffix("/v1") { root.removeLast(3) }
        if root.hasSuffix("/api") { root.removeLast(4) }
        return URL(string: "\(root)/api/vertex-ai/v1/publishers/\(provider)/models/\(name):generateContent")!
    }

    static func parseOpenAIImage(_ data: Data) throws -> AIGeneratedImage {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]] ?? []
        guard let first = items.first else { throw AIImageError.noImageInResponse }
        if let b64 = first["b64_json"] as? String, let decoded = Data(base64Encoded: b64) {
            return AIGeneratedImage(data: decoded, revisedPrompt: first["revised_prompt"] as? String)
        }
        if let urlText = first["url"] as? String, let url = URL(string: urlText),
           let downloaded = try? Data(contentsOf: url) {
            return AIGeneratedImage(data: downloaded, revisedPrompt: first["revised_prompt"] as? String)
        }
        throw AIImageError.noImageInResponse
    }

    static func parseVertexImage(_ data: Data) throws -> AIGeneratedImage {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]] ?? []
        let parts = (candidates.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]] ?? []
        for part in parts {
            if let inline = part["inlineData"] as? [String: Any] ?? part["inline_data"] as? [String: Any],
               let b64 = inline["data"] as? String, let decoded = Data(base64Encoded: b64) {
                return AIGeneratedImage(data: decoded)
            }
        }
        throw AIImageError.noImageInResponse
    }

    static func throwIfFailed(data: Data, response: URLResponse) throws {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else {
            throw AIImageError.http(status, message(from: data, status: status))
        }
    }

    static func message(from data: Data, status: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? [String: Any] {
                if let message = error["message"] as? String, !message.isEmpty { return message }
            }
            if let message = json["message"] as? String, !message.isEmpty { return message }
        }
        if let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return "The image service returned HTTP \(status)."
    }

    static func modelCount(in data: Data) -> Int? {
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        if let data = json?["data"] as? [Any] { return data.count }
        return nil
    }
}

nonisolated struct MultipartForm: Sendable {
    let boundary: String
    private(set) var body = Data()

    init(boundary: String = "----CompositorForm\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))") {
        self.boundary = boundary
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func add(_ name: String, _ value: String) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.append("\(value)\r\n")
    }

    mutating func addFile(_ name: String, filename: String, mime: String, data: Data) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mime)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
    }

    var finished: Data {
        var data = body
        data.append("--\(boundary)--\r\n")
        return data
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}

extension MultipartForm {
    var assembled: Data { finished }
}
