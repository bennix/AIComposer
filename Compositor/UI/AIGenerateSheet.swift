import SwiftUI
import AppKit

struct AIStudioSheet: View {
    @Bindable var session: EditorSession
    let kind: AISheetKind
    var settings: AISettingsController = .shared
    @State private var prompt = ""
    @State private var model: AIImageModel
    @State private var size: AIImageSize = .square
    @State private var left = "256"
    @State private var right = "256"
    @State private var top = "256"
    @State private var bottom = "256"

    init(session: EditorSession, kind: AISheetKind, settings: AISettingsController = .shared) {
        self.session = session
        self.kind = kind
        self.settings = settings
        _model = State(initialValue: settings.selectedModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(kind.title).font(.title2.weight(.semibold))
                Text(kind.help).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if !settings.credentials.hasAPIKey {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No API key yet. Use a ZenMux invite link to register, then paste the key in Settings.")
                        .foregroundStyle(.orange)
                    HStack {
                        Button("Open Invite Link") { settings.openInvite() }
                            .disabled(ZenMuxInvite.url(from: settings.credentials.inviteLink) == nil)
                        Button("AI Settings…") {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }
                }
            }
            if kind.usesMultimodal {
                Text("Uses the multimodal model from Settings.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Picker("Model", selection: $model) {
                    ForEach(AIImageModel.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
            if kind.showsSizePicker {
                Picker("Size", selection: $size) {
                    ForEach(AIImageSize.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
            if kind == .expand {
                HStack(spacing: 12) {
                    expandField("Left", text: $left)
                    expandField("Right", text: $right)
                    expandField("Top", text: $top)
                    expandField("Bottom", text: $bottom)
                }
            }
            if !kind.presets.isEmpty {
                FlowPresets(titles: kind.presets) { prompt = $0 }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(kind.requiresPrompt || kind.input == .none ? "Prompt" : "Extra instruction")
                    .font(.callout.weight(.medium))
                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(minHeight: kind.requiresPrompt ? 110 : 72, maxHeight: 180)
                    .padding(6)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 7))
                    .accessibilityIdentifier("aiPrompt")
                Text(kind.placeholder).font(.callout).foregroundStyle(.tertiary)
            }
            HStack {
                Button("Cancel") { session.aiSheet = nil }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(session.isGeneratingAI ? "Working…" : kind.input == .none ? "Generate" : "Apply") {
                    Task {
                        await session.runAI(
                            kind: kind,
                            prompt: prompt,
                            model: model,
                            size: size,
                            expand: (Int(left) ?? 0, Int(right) ?? 0, Int(top) ?? 0, Int(bottom) ?? 0),
                            settings: settings
                        )
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!canRun)
                .accessibilityIdentifier("aiApply")
            }
        }
        .padding(24)
        .frame(minWidth: 540, idealWidth: 580)
        .disabled(session.isGeneratingAI)
    }

    private var canRun: Bool {
        guard !session.isGeneratingAI, settings.credentials.hasAPIKey else { return false }
        if kind.requiresPrompt { return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if kind == .expand {
            return [left, right, top, bottom].contains { (Int($0) ?? 0) > 0 }
        }
        return true
    }

    private func expandField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.callout.weight(.medium))
            HStack {
                TextField(title, text: text).textFieldStyle(.plain)
                Text("px").foregroundStyle(.secondary)
            }
            .padding(10).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))
        }
    }
}

private struct FlowPresets: View {
    let titles: [String]
    let choose: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets").font(.callout.weight(.medium))
            FlexibleHStack(titles: titles, choose: choose)
        }
    }
}

/// Simple wrapping row of capsule buttons; keeps the sheet off a full flow-layout dependency.
private struct FlexibleHStack: View {
    let titles: [String]
    let choose: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { title in
                        Button(title) { choose(title) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var rows: [[String]] {
        var result: [[String]] = []
        var current: [String] = []
        var width = 0
        for title in titles {
            let next = width + title.count
            if !current.isEmpty && next > 42 {
                result.append(current)
                current = [title]
                width = title.count
            } else {
                current.append(title)
                width = next + 2
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}

struct AIStudioPresentation: ViewModifier {
    @Bindable var session: EditorSession
    func body(content: Content) -> some View {
        content.sheet(item: Binding(get: { session.aiSheet }, set: { session.aiSheet = $0 })) { kind in
            AIStudioSheet(session: session, kind: kind)
        }
    }
}
