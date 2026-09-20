import Foundation
import CryptoKit
import Security

nonisolated struct AICredentials: Codable, Equatable, Sendable {
    var baseURL: String
    var apiKey: String
    var defaultModel: String
    /// Invite URL or code from ZenMux. Used only when the user has no API key yet.
    var inviteLink: String = ""

    static let defaultBaseURL = "https://zenmux.ai/api/v1"

    static var empty: AICredentials {
        AICredentials(baseURL: defaultBaseURL, apiKey: "", defaultModel: AIImageModel.gptImage.rawValue)
    }

    var trimmed: AICredentials {
        AICredentials(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            defaultModel: defaultModel.trimmingCharacters(in: .whitespacesAndNewlines),
            inviteLink: inviteLink.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    var hasAPIKey: Bool { !trimmed.apiKey.isEmpty }

    var endpoint: URL? {
        var text = trimmed.baseURL
        if text.hasSuffix("/") { text.removeLast() }
        return URL(string: text)
    }

    enum CodingKeys: String, CodingKey { case baseURL, apiKey, defaultModel, inviteLink }

    init(baseURL: String, apiKey: String, defaultModel: String, inviteLink: String = "") {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.defaultModel = defaultModel
        self.inviteLink = inviteLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? Self.defaultBaseURL
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        defaultModel = try container.decodeIfPresent(String.self, forKey: .defaultModel) ?? AIImageModel.gptImage.rawValue
        inviteLink = try container.decodeIfPresent(String.self, forKey: .inviteLink) ?? ""
    }
}

nonisolated enum ZenMuxInvite {
    static let host = "zenmux.ai"
    static let keysURL = URL(string: "https://zenmux.ai/settings/keys")!
    static let payAsYouGoURL = URL(string: "https://zenmux.ai/platform/pay-as-you-go")!
    static let subscriptionURL = URL(string: "https://zenmux.ai/platform/subscription")!

    /// Accepts a full invite URL or a bare code such as `C2GQ97`.
    static func url(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme == "https",
           let host = url.host?.lowercased(), host == "zenmux.ai" || host.hasSuffix(".zenmux.ai") {
            return url
        }
        let code = trimmed.replacingOccurrences(of: "/", with: "")
        guard code.range(of: #"^[A-Za-z0-9_-]{4,32}$"#, options: .regularExpression) != nil else { return nil }
        return URL(string: "https://zenmux.ai/invite/\(code)")
    }
}

nonisolated protocol AISecretKeyProviding: Sendable {
    func loadOrCreateKey() throws -> SymmetricKey
}

nonisolated struct InMemoryAISecretKeyStore: AISecretKeyProviding {
    let key: SymmetricKey
    init(key: SymmetricKey = SymmetricKey(size: .bits256)) { self.key = key }
    func loadOrCreateKey() throws -> SymmetricKey { key }
}

/// AES-GCM key kept in the login keychain so the credentials file on disk is not plaintext.
nonisolated struct KeychainAISecretKeyStore: AISecretKeyProviding {
    let service: String
    let account: String

    init(service: String = "com.wonderassembly.compositor.ai-credentials",
         account: String = "aes-gcm-key") {
        self.service = service
        self.account = account
    }

    func loadOrCreateKey() throws -> SymmetricKey {
        if let existing = try read() { return existing }
        let created = SymmetricKey(size: .bits256)
        try write(created)
        return created
    }

    private func read() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw AICredentialError.keychain(status)
        }
        return SymmetricKey(data: data)
    }

    private func write(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw AICredentialError.keychain(status) }
    }
}

nonisolated enum AICredentialError: LocalizedError {
    case keychain(OSStatus)
    case corruptFile
    case missingKey
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .keychain(let status): L10n.format("The API key could not be locked to this Mac (Keychain status %d).", status)
        case .corruptFile: L10n.t("The saved API credentials file is damaged and cannot be read.")
        case .missingKey: L10n.t("Add an API key in Settings before generating or editing images.")
        case .invalidURL: L10n.t("Enter a valid Base URL, such as https://zenmux.ai/api/v1.")
        }
    }
}

/// Encrypted JSON in the user Application Support folder:
/// `{"version":1,"algorithm":"aes-gcm","nonce":"...","ciphertext":"..."}`
nonisolated struct AICredentialsStore: Sendable {
    let fileURL: URL
    let keys: any AISecretKeyProviding

    static func defaultFileURL() throws -> URL {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        let folder = root.appendingPathComponent("Compositor", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ai-credentials.json")
    }

    init(fileURL: URL? = nil, keys: any AISecretKeyProviding = KeychainAISecretKeyStore()) throws {
        self.fileURL = try fileURL ?? Self.defaultFileURL()
        self.keys = keys
    }

    func load() throws -> AICredentials {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        let data = try Data(contentsOf: fileURL)
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        guard envelope.version == 1, envelope.algorithm == "aes-gcm",
              let nonceData = Data(base64Encoded: envelope.nonce),
              let sealedData = Data(base64Encoded: envelope.ciphertext),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw AICredentialError.corruptFile
        }
        let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: sealedData.dropLast(16),
                                        tag: sealedData.suffix(16))
        let plain = try AES.GCM.open(box, using: keys.loadOrCreateKey())
        return try JSONDecoder().decode(AICredentials.self, from: plain)
    }

    func save(_ credentials: AICredentials) throws {
        let value = credentials.trimmed
        guard value.endpoint != nil else { throw AICredentialError.invalidURL }
        let plain = try JSONEncoder().encode(value)
        let sealed = try AES.GCM.seal(plain, using: keys.loadOrCreateKey())
        guard let combined = sealed.combined else { throw AICredentialError.corruptFile }
        let envelope = Envelope(
            version: 1,
            algorithm: "aes-gcm",
            nonce: Data(sealed.nonce).base64EncodedString(),
            ciphertext: combined.dropFirst(12).base64EncodedString()
        )
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try JSONEncoder().encode(envelope).write(to: fileURL, options: .atomic)
    }

    func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private struct Envelope: Codable {
        var version: Int
        var algorithm: String
        var nonce: String
        var ciphertext: String
    }
}
