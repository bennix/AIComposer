import SwiftUI
import WebKit

struct AIMannequinEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var plan: AICharacterPlan
    @State private var webView: WKWebView?
    @State private var ready = false
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("人偶姿态 · IK 编辑").font(.title2.bold())
                Spacer()
                Text("\(plan.people.count) 人 · 22 种预设 · 自定义关节操控").foregroundStyle(.secondary)
            }
            MannequinWebView(people: plan.people, document: plan.poseDocument, created: { webView = $0 }, ready: { ready = true }, failure: { error = $0; saving = false }) { png, document in
                plan.poseGuidePNG = png
                plan.poseDocument = document
                plan.usePose = true
                dismiss()
            }
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(saving ? "正在保存…" : "保存姿态引导图") {
                    saving = true
                    webView?.evaluateJavaScript("window.exportPosePlan()") { _, failure in
                        if let failure { error = failure.localizedDescription; saving = false }
                    }
                }.disabled(!ready || saving).buttonStyle(.borderedProminent)
            }
        }.padding(18).frame(width: 1000, height: 720)
    }
}

private struct MannequinWebView: NSViewRepresentable {
    let people: [AICharacter]
    let document: String
    let created: (WKWebView) -> Void
    let ready: () -> Void
    let failure: (String) -> Void
    let saved: (Data, String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "poseEditor")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        DispatchQueue.main.async { created(view) }
        guard let bundle = Bundle.main.url(forResource: "BodyPoseEditor", withExtension: "bundle") else {
            DispatchQueue.main.async { failure("人偶编辑器资源缺失。") }
            return view
        }
        view.loadFileURL(bundle.appending(path: "index.html"), allowingReadAccessTo: bundle)
        return view
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "poseEditor")
        nsView.stopLoading()
    }

    @MainActor final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let owner: MannequinWebView
        init(_ owner: MannequinWebView) { self.owner = owner }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            do {
                let arguments: [Any] = [owner.people.map { ["id": $0.id.uuidString] }, owner.document]
                let data = try JSONSerialization.data(withJSONObject: arguments)
                let json = String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript("window.loadPosePlan(...\(json))") { _, error in
                    if let error { self.owner.failure(error.localizedDescription) }
                }
            } catch { owner.failure(error.localizedDescription) }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { owner.failure(error.localizedDescription) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { owner.failure(error.localizedDescription) }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, let body = message.body as? [String: Any] else { return }
            switch body["type"] as? String {
            case "ready": owner.ready()
            case "error": owner.failure(body["message"] as? String ?? "人偶编辑失败。")
            case "saved":
                guard let ids = body["ids"] as? [String], ids == owner.people.map({ $0.id.uuidString }),
                      let base64 = body["png"] as? String, let data = Data(base64Encoded: base64),
                      let document = body["document"] as? String else {
                    owner.failure("姿态保存失败：人数或图像数据不一致。")
                    return
                }
                do {
                    let image = try AIImagePipeline.scaledForUpload(AIImagePipeline.image(from: data))
                    owner.saved(try AIImagePipeline.pngData(from: image), document)
                } catch { owner.failure(error.localizedDescription) }
            default: break
            }
        }
    }
}
