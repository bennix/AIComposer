import SwiftUI
import AppKit

struct TypeControls: View {
    @Bindable var session: EditorSession
    private func value<T>(_ key: WritableKeyPath<LayerTextStyle, T>) -> Binding<T> {
        Binding(get: { session.currentTextStyle[keyPath: key] }, set: { value in
            session.changeTextStyle { $0[keyPath: key] = value }
        })
    }
    private func number(_ key: WritableKeyPath<LayerTextStyle, CGFloat>) -> Binding<Double> {
        Binding(get: { Double(session.currentTextStyle[keyPath: key]) }, set: { value in
            session.changeTextStyle { $0[keyPath: key] = CGFloat(value) }
        })
    }
    var body: some View {
        HStack(spacing: 12) {
            Text("Type").font(ToolHeaderStyle.titleFont)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    TypeFamilyPicker(fontName: value(\.fontName))
                        .frame(width: 160).help(L10n.t("Font family"))
                    TypeFacePicker(fontName: value(\.fontName))
                        .frame(width: 120).help(L10n.t("Typeface style — Regular, Bold, Italic, and other installed faces"))
                    TextField("Size", value: number(\.fontSize), format: .number).frame(width: 52).unitSuffix("px")
                        .arrowSteps(value: { Double(session.currentTextStyle.fontSize) },
                                    change: { stepped in session.changeTextStyle { $0.fontSize = CGFloat(min(2000, max(1, stepped))) } })
                    Button { session.openTextColorPicker() } label: {
                        let color = session.typeColor
                        let swatch = RoundedRectangle(cornerRadius: 3, style: .continuous)
                        swatch.fill(Color(red: color.red, green: color.green, blue: color.blue))
                            .overlay { swatch.strokeBorder(.black.opacity(0.5), lineWidth: 1) }
                            .frame(width: 36, height: 18)
                    }
                    .buttonStyle(.plain).help("Text color").accessibilityLabel("Text color")
                    HStack(spacing: 2) {
                        ForEach(TextAlignment.allCases, id: \.self) { alignment in
                            let selected = session.currentTextStyle.alignment == alignment
                            Button {
                                session.changeTextStyle { $0.alignment = alignment }
                            } label: {
                                Image(systemName: alignment == .left ? "text.alignleft" : alignment == .center ? "text.aligncenter" : "text.alignright")
                                    .frame(width: 30, height: 26)
                                    .background(selected ? Color.white.opacity(0.14) : .clear,
                                                in: RoundedRectangle(cornerRadius: 4))
                                    // Without this the glyph's own strokes are the only thing a click lands on.
                                    .contentShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                            .help("Align " + alignment.rawValue.lowercased())
                            .accessibilityLabel("Align " + alignment.rawValue.lowercased())
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    Text("Tracking")
                    TextField("Tracking", value: number(\.tracking), format: .number).frame(width: 45)
                        .arrowSteps(value: { Double(session.currentTextStyle.tracking) },
                                    change: { stepped in session.changeTextStyle { $0.tracking = CGFloat(stepped) } })
                    Text("Leading")
                    // 0 means Auto: the field is left empty so its "Auto" placeholder shows through.
                    TextField("Leading", text: Binding(get: {
                        let leading = session.currentTextStyle.leading
                        return leading > 0 ? String(Int(leading.rounded())) : ""
                    }, set: { typed in
                        let value = Double(typed.trimmingCharacters(in: .whitespaces)) ?? 0
                        session.changeTextStyle { $0.leading = CGFloat(max(0, min(5000, value))) }
                    }), prompt: Text("Auto"))
                        .frame(width: 52)
                        .arrowSteps(value: { Double(session.currentTextStyle.lineHeight) },
                                    change: { stepped in session.changeTextStyle { $0.leading = CGFloat(max(0, stepped)) } })
                        .help("Line height, baseline to baseline. Empty or 0 is Auto: 120% of the font size.")
                    Text(L10n.t("Warp"))
                    Picker(L10n.t("Warp"), selection: value(\.warp)) {
                        ForEach(TextWarpKind.allCases, id: \.self) { kind in
                            Text(L10n.t(kind.rawValue)).tag(kind)
                        }
                    }
                    .frame(width: 110)
                    .help(L10n.t("Bend the letters while keeping the text editable"))
                    if session.currentTextStyle.warp != .none {
                        TextField(L10n.t("Bend"), value: number(\.warpBend), format: .number)
                            .frame(width: 48)
                            .arrowSteps(value: { Double(session.currentTextStyle.warpBend) },
                                        change: { stepped in session.changeTextStyle { $0.warpBend = CGFloat(min(100, max(-100, stepped))) } })
                            .help(L10n.t("Warp amount from −100 to 100"))
                    }
                }
            }.scrollIndicators(.hidden)
            if session.textDraft != nil {
                Button("Cancel") { session.cancelText() }
                Button("Done") { _ = session.finishText() }
            } else {
                Button("Edit Text") { session.editActiveText() }.disabled(session.activeLayer?.liveText == nil)
            }
        }
        .textFieldStyle(.roundedBorder).padding(.horizontal, 18).toolHeaderBar()
        .disabled(session.document == nil || session.showsBusy)
    }
}

/// Keep the installed-font catalog out of SwiftUI's per-keystroke view updates.
/// The closed control needs only the current name; populate its menu on demand.
private final class FixedWidthPopUpButton: NSPopUpButton {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
    }
}

private struct TypeFamilyPicker: NSViewRepresentable {
    @Binding var fontName: String
    @Environment(\.isEnabled) private var isEnabled

    func makeCoordinator() -> Coordinator { Coordinator(fontName: $fontName) }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = FixedWidthPopUpButton(frame: .zero, pullsDown: false)
        button.addItem(withTitle: LayerTextStyle().fontFamily)
        button.borderShape = .capsule
        button.cell?.lineBreakMode = .byTruncatingTail
        button.cell?.usesSingleLineMode = true
        button.cell?.alignment = .left
        button.setAccessibilityLabel(L10n.t("Font"))
        button.target = context.coordinator
        button.action = #selector(Coordinator.choose(_:))
        button.menu?.delegate = context.coordinator
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.fontName = $fontName
        button.isEnabled = isEnabled
        let family = (NSFont(name: fontName, size: 12) ?? .systemFont(ofSize: 12)).familyName ?? fontName
        guard !context.coordinator.tracking, button.titleOfSelectedItem != family else { return }
        if button.item(withTitle: family) == nil { button.addItem(withTitle: family) }
        button.selectItem(withTitle: family)
    }

    static func dismantleNSView(_ button: NSPopUpButton, coordinator: Coordinator) {
        button.menu?.delegate = nil
        button.target = nil
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var fontName: Binding<String>
        weak var button: NSPopUpButton?
        var tracking = false
        private var loaded = false

        init(fontName: Binding<String>) { self.fontName = fontName }

        func menuNeedsUpdate(_ menu: NSMenu) {
            guard !loaded, let button else { return }
            let selected = (NSFont(name: fontName.wrappedValue, size: 12) ?? .systemFont(ofSize: 12)).familyName
                ?? fontName.wrappedValue
            button.removeAllItems()
            button.addItems(withTitles: NSFontManager.shared.availableFontFamilies)
            button.selectItem(withTitle: selected)
            loaded = true
        }

        func menuWillOpen(_ menu: NSMenu) { tracking = true }
        func menuDidClose(_ menu: NSMenu) { tracking = false }

        @objc func choose(_ button: NSPopUpButton) {
            guard let family = button.titleOfSelectedItem else { return }
            var style = LayerTextStyle()
            style.fontName = fontName.wrappedValue
            EditorSession.setFontFamily(family, on: &style)
            if style.fontName != fontName.wrappedValue { fontName.wrappedValue = style.fontName }
        }
    }
}

private struct TypeFacePicker: NSViewRepresentable {
    @Binding var fontName: String
    @Environment(\.isEnabled) private var isEnabled

    func makeCoordinator() -> Coordinator { Coordinator(fontName: $fontName) }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = FixedWidthPopUpButton(frame: .zero, pullsDown: false)
        button.addItem(withTitle: fontName)
        button.borderShape = .capsule
        button.cell?.lineBreakMode = .byTruncatingTail
        button.cell?.usesSingleLineMode = true
        button.cell?.alignment = .left
        button.setAccessibilityLabel(L10n.t("Typeface"))
        button.target = context.coordinator
        button.action = #selector(Coordinator.choose(_:))
        button.menu?.delegate = context.coordinator
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.fontName = $fontName
        button.isEnabled = isEnabled
        guard !context.coordinator.tracking else { return }
        context.coordinator.reloadFaces(button, selected: fontName)
    }

    static func dismantleNSView(_ button: NSPopUpButton, coordinator: Coordinator) {
        button.menu?.delegate = nil
        button.target = nil
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var fontName: Binding<String>
        weak var button: NSPopUpButton?
        var tracking = false

        init(fontName: Binding<String>) { self.fontName = fontName }

        func menuNeedsUpdate(_ menu: NSMenu) {
            guard let button else { return }
            reloadFaces(button, selected: fontName.wrappedValue)
        }

        func menuWillOpen(_ menu: NSMenu) { tracking = true }
        func menuDidClose(_ menu: NSMenu) { tracking = false }

        func reloadFaces(_ button: NSPopUpButton, selected: String) {
            let family = (NSFont(name: selected, size: 12) ?? .systemFont(ofSize: 12)).familyName ?? selected
            let faces = EditorSession.fontFaces(in: family)
            button.removeAllItems()
            for face in faces {
                let item = NSMenuItem(title: face.title, action: nil, keyEquivalent: "")
                item.representedObject = face.name
                button.menu?.addItem(item)
            }
            if let index = faces.firstIndex(where: { $0.name == selected }) {
                button.selectItem(at: index)
            } else if button.numberOfItems > 0 {
                button.selectItem(at: 0)
            }
        }

        @objc func choose(_ button: NSPopUpButton) {
            guard let name = button.selectedItem?.representedObject as? String,
                  name != fontName.wrappedValue else { return }
            fontName.wrappedValue = name
        }
    }
}
