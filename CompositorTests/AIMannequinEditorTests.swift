import AppKit
import WebKit
import Foundation
import Testing
@testable import Compositor

@MainActor struct AIMannequinEditorTests {
    @Test func offlineEditorRendersMultiplePeopleAndExportsModifiedPose() async throws {
        let resource = try #require(Bundle.main.url(forResource: "BodyPoseEditor", withExtension: "bundle"))
        let handler = PoseMessages()
        let config = WKWebViewConfiguration()
        config.userContentController.add(handler, name: "poseEditor")
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 580), configuration: config)
        let window = NSWindow(contentRect: web.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = web
        defer { web.stopLoading(); config.userContentController.removeScriptMessageHandler(forName: "poseEditor"); window.close() }
        web.loadFileURL(resource.appending(path: "index.html"), allowingReadAccessTo: resource)
        var loaded = false
        for _ in 0..<100 {
            if (try? await web.evaluateJavaScript("typeof window.loadPosePlan")) as? String == "function" { loaded = true; break }
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(loaded)
        try #require(loaded)
        _ = try await web.evaluateJavaScript("window.loadPosePlan([{id:'one'},{id:'two'}], ''); window.exportPosePlan();")
        for _ in 0..<100 where handler.saved.isEmpty && handler.error == nil { try await Task.sleep(for: .milliseconds(50)) }
        #expect(handler.error == nil)
        let first = try #require(handler.saved.last)
        let firstBase64 = try #require(first["png"] as? String)
        let firstPNG = try #require(Data(base64Encoded: firstBase64))
        #expect(try AIImagePipeline.image(from: firstPNG).width > 0)
        _ = try await web.evaluateJavaScript("document.getElementById('preset').value='3'; document.getElementById('preset').dispatchEvent(new Event('change')); window.exportPosePlan();")
        for _ in 0..<100 where handler.saved.count < 2 && handler.error == nil { try await Task.sleep(for: .milliseconds(50)) }
        let changed = try #require(handler.saved.last)
        let changedBase64 = try #require(changed["png"] as? String)
        let changedPNG = try #require(Data(base64Encoded: changedBase64))
        #expect(firstPNG != changedPNG)
        #expect(changed["ids"] as? [String] == ["one", "two"])
        let document = try #require(changed["document"] as? String)
        let state = try #require(JSONSerialization.jsonObject(with: Data(document.utf8)) as? [String: Any])
        let figures = try #require(state["figures"] as? [[String: Any]])
        #expect(figures.count == 2)
        let firstPose = try #require(figures[0]["pose"] as? [String: Any])
        let bones = try #require(firstPose["bones"] as? [String: [Double]])
        #expect(bones["hipL"]?.first == -24)
        let secondPose = try #require(figures[1]["pose"] as? [String: Any])
        let secondBones = try #require(secondPose["bones"] as? [String: [Double]])
        #expect(secondBones["hipL"]?.first == 0)
        try changedPNG.write(to: URL(fileURLWithPath: "/tmp/AIComposer-person-pose-preview.png"))
    }
}

@MainActor private final class PoseMessages: NSObject, WKScriptMessageHandler {
    var saved: [[String: Any]] = []
    var error: String?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if body["type"] as? String == "saved" { saved.append(body) }
        if body["type"] as? String == "error" { error = body["message"] as? String }
    }
}
