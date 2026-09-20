import SwiftUI
import AppKit

struct BlendModePicker: NSViewRepresentable {
    let session: EditorSession
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        for mode in LayerBlendMode.allCases {
            let item = NSMenuItem(title: L10n.t(mode.rawValue), action: nil, keyEquivalent: "")
            item.representedObject = mode.rawValue
            button.menu?.addItem(item)
        }
        button.menu?.delegate = context.coordinator
        button.target = context.coordinator
        button.action = #selector(Coordinator.choose(_:))
        button.setAccessibilityLabel(L10n.t("Blend mode"))
        // A capsule like the SwiftUI buttons and menus (`roundedControls`), which don't reach this AppKit pop-up.
        button.borderShape = .capsule
        return button
    }
    func updateNSView(_ button: NSPopUpButton, context: Context) {
        button.isEnabled = session.canEditAppearance
        if !context.coordinator.tracking {
            let mode = session.activeLayer?.blendMode ?? .normal
            if let index = LayerBlendMode.allCases.firstIndex(of: mode) {
                button.selectItem(at: index)
            }
        }
    }
    static func dismantleNSView(_ button: NSPopUpButton, coordinator: Coordinator) {
        if coordinator.tracking { coordinator.session.previewBlendMode(nil, for: nil) }
        button.menu?.delegate = nil
    }
    final class Coordinator: NSObject, NSMenuDelegate {
        let session: EditorSession
        var tracking = false
        private var layerID: UUID?
        private var highlightedMode: LayerBlendMode?
        init(session: EditorSession) { self.session = session }
        func menuWillOpen(_ menu: NSMenu) {
            tracking = true
            layerID = session.activeLayerID
            highlightedMode = nil
        }
        func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
            let mode = item.flatMap { ($0.representedObject as? String).flatMap(LayerBlendMode.init(rawValue:)) }
            if let mode { highlightedMode = mode }
            session.previewBlendMode(mode, for: layerID)
        }
        func menuDidClose(_ menu: NSMenu) {
            tracking = false
            session.previewBlendMode(nil, for: nil)
        }
        @objc func choose(_ button: NSPopUpButton) {
            guard session.activeLayerID == layerID,
                  let mode = highlightedMode ?? button.selectedItem.flatMap({ ($0.representedObject as? String).flatMap(LayerBlendMode.init(rawValue:)) }) else { return }
            session.setLayerBlendMode(mode)
            if let index = LayerBlendMode.allCases.firstIndex(of: mode) {
                button.selectItem(at: index)
            }
            highlightedMode = nil
            session.refreshCanvasPreview?()
        }
    }
}
