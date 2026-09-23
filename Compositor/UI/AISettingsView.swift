import SwiftUI

struct AISettingsView: View {
    @Bindable var settings: AISettingsController
    @Bindable private var languages = AppLanguageController.shared
    @State private var revealsKey = false

    init(settings: AISettingsController = .shared) {
        self.settings = settings
    }

    var body: some View {
        Form {
            Section("Language") {
                Picker("Language", selection: $languages.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                Text("Appearance follows the selected language for every control, menu, tooltip, and AI prompt.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Section("Provider") {
                TextField("Base URL", text: $settings.credentials.baseURL)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("aiBaseURL")
                Text("ZenMux OpenAI-compatible endpoint. Gemini Flash Lite Image is sent through the matching Vertex path.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Section("API Key") {
                HStack(spacing: 8) {
                    Group {
                        if revealsKey {
                            TextField("API Key", text: $settings.credentials.apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("API Key", text: $settings.credentials.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .textContentType(.password)
                    .accessibilityIdentifier("aiAPIKey")
                    Button {
                        revealsKey.toggle()
                    } label: {
                        Image(systemName: revealsKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                    .help(revealsKey ? "Hide API key" : "Show API key")
                    .accessibilityIdentifier("aiRevealKey")
                    .accessibilityLabel(revealsKey ? "Hide API key" : "Show API key")
                }
                Text("Stored as AES-GCM encrypted JSON in this Mac’s Application Support folder. The unwrap key stays in the Keychain.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Save") { settings.save() }
                        .keyboardShortcut("s")
                        .disabled(settings.isSaving)
                        .accessibilityIdentifier("aiSaveKey")
                    Button(settings.isTesting ? "Testing…" : "Test API Key") {
                        Task { await settings.test() }
                    }
                    .disabled(!settings.credentials.hasAPIKey || settings.isTesting)
                    .accessibilityIdentifier("aiTestKey")
                }
                if let status = settings.lastStatus {
                    Text(status).foregroundStyle(.green)
                }
                if let error = settings.lastError {
                    Text(error).foregroundStyle(.orange)
                }
            }
            Section("No API key yet") {
                Text("If you do not have a ZenMux API key, open an invite link, register, then create a key and paste it above.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                TextField("Invite link or code", text: $settings.credentials.inviteLink)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("aiInviteLink")
                HStack {
                    Button("Open Invite Link") { settings.openInvite() }
                        .disabled(ZenMuxInvite.url(from: settings.credentials.inviteLink) == nil)
                        .accessibilityIdentifier("aiOpenInvite")
                    Button("Open Key Console") { settings.openKeyConsole() }
                        .accessibilityIdentifier("aiOpenKeyConsole")
                }
                Text("Accepts `https://zenmux.ai/invite/…` or a bare invite code. After signup, create the key at zenmux.ai/settings/keys.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Section("Default model") {
                Picker("Model", selection: $settings.selectedModel) {
                    ForEach(AIImageModel.allCases) { model in
                        Text("\(model.title) · \(model.subtitle)").tag(model)
                    }
                }
                .accessibilityIdentifier("aiDefaultModel")
            }
            Section("Multimodal model") {
                TextField("Model name", text: $settings.credentials.multimodalModel)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("aiMultimodalModel")
                Text("ZenMux chat/completions slug for vision tasks such as converting graphic type into editable text. Example: google/gemini-3.8-flash")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Section("Verification") {
                Text("Key testing is available now. Per-model live checks can be added here later without changing how the key is stored.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, minHeight: 500)
        .padding()
        .onAppear { settings.load() }
    }
}
