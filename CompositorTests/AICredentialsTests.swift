import Foundation
import CryptoKit
import Testing
@testable import Compositor

struct AICredentialsTests {
    @Test func encryptsAndReloadsFromUserFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let keys = InMemoryAISecretKeyStore()
        let store = try AICredentialsStore(fileURL: url, keys: keys)
        let saved = AICredentials(
            baseURL: "https://zenmux.ai/api/v1",
            apiKey: "sk-test-secret",
            defaultModel: AIImageModel.qwen.rawValue
        )
        try store.save(saved)
        let raw = try String(contentsOf: url, encoding: .utf8)
        #expect(!raw.contains("sk-test-secret"))
        #expect(raw.contains("aes-gcm"))
        let loaded = try store.load()
        #expect(loaded == saved)
    }

    @Test func missingFileReturnsEmptyCredentials() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        let store = try AICredentialsStore(fileURL: url, keys: InMemoryAISecretKeyStore())
        #expect(try store.load() == .empty)
    }

    @Test func inviteLinkAcceptsURLOrCode() {
        #expect(ZenMuxInvite.url(from: "https://zenmux.ai/invite/C2GQ97")?.absoluteString == "https://zenmux.ai/invite/C2GQ97")
        #expect(ZenMuxInvite.url(from: "C2GQ97")?.absoluteString == "https://zenmux.ai/invite/C2GQ97")
        #expect(ZenMuxInvite.url(from: "https://example.com/invite/x") == nil)
        #expect(ZenMuxInvite.url(from: "") == nil)
    }

    @Test func wrongKeyFailsToOpen() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        try AICredentialsStore(fileURL: url, keys: InMemoryAISecretKeyStore()).save(.empty)
        #expect(throws: Error.self) {
            try AICredentialsStore(fileURL: url, keys: InMemoryAISecretKeyStore()).load()
        }
    }
}
