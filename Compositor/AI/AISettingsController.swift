import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class AISettingsController {
    static let shared = AISettingsController()

    var credentials = AICredentials.empty
    var lastStatus: String?
    var lastError: String?
    var isTesting = false
    var isSaving = false

    private var store: AICredentialsStore?

    init(store: AICredentialsStore? = nil) {
        self.store = store
        load()
    }

    func load() {
        do {
            let store = try store ?? AICredentialsStore()
            self.store = store
            credentials = try store.load()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func save() {
        isSaving = true
        defer { isSaving = false }
        do {
            let store = try store ?? AICredentialsStore()
            self.store = store
            try store.save(credentials)
            credentials = credentials.trimmed
            lastStatus = credentials.hasAPIKey
                ? L10n.t("API key saved to this Mac.")
                : L10n.t("Invite link saved. After ZenMux creates your key, paste it here.")
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            lastStatus = nil
        }
    }

    func test() async {
        isTesting = true
        defer { isTesting = false }
        do {
            let message = try await AIImageClient().testKey(credentials)
            lastStatus = message
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            lastStatus = nil
        }
    }

    func openInvite() {
        guard let url = ZenMuxInvite.url(from: credentials.inviteLink) else {
            lastError = L10n.t("Paste a ZenMux invite link or invite code first.")
            lastStatus = nil
            return
        }
        lastError = nil
        lastStatus = L10n.t("Opened the invite page. After you register, create an API key and paste it here.")
        NSWorkspace.shared.open(url)
    }

    func openKeyConsole() {
        lastError = nil
        lastStatus = L10n.t("Opened the ZenMux key console.")
        NSWorkspace.shared.open(ZenMuxInvite.keysURL)
    }

    var selectedModel: AIImageModel {
        get { AIImageModel.resolved(credentials.defaultModel) }
        set { credentials.defaultModel = newValue.rawValue }
    }
}
