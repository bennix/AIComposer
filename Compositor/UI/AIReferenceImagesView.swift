import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AIReferenceImagesView: View {
    @Binding var images: [AIReferenceImage]
    var people: [AICharacter] = []
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("参考图 \(images.count) / \(AIReferenceImage.limit)").font(.headline)
                Spacer()
                Button("添加图片…", action: chooseImages)
                Button("粘贴参考图", action: pasteImages)
            }
            .disabled(images.count >= AIReferenceImage.limit)
            .accessibilityIdentifier("creativeGuideReferences")
            HStack(spacing: 10) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 3) {
                        Image(nsImage: item.thumbnail).resizable().scaledToFit()
                            .frame(width: 100, height: 80)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    images.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.75))
                                        .font(.system(size: 18))
                                }.buttonStyle(.plain).padding(3)
                                    .accessibilityLabel("删除参考图 \(index + 1)")
                            }
                        Text("参考图 \(index + 1)").font(.caption).foregroundStyle(.secondary)
                        if !people.isEmpty {
                            Picker("用途", selection: $images[index].role) {
                                ForEach(AIReferenceRole.allCases) { Text($0.title).tag($0) }
                            }.labelsHidden().frame(width: 100)
                            if item.role.targetsPerson {
                                Picker("对应人物", selection: $images[index].personID) {
                                    Text("指定人物").tag(nil as UUID?)
                                    ForEach(Array(people.enumerated()), id: \.element.id) { number, person in
                                        Text("人物 \(number + 1)").tag(Optional(person.id))
                                    }
                                }.labelsHidden().frame(width: 100)
                                TextField("图内目标说明", text: $images[index].detail)
                                    .textFieldStyle(.roundedBorder).frame(width: 100)
                            }
                        }
                    }
                }
            }
            if images.isEmpty {
                Text("选择或粘贴图片，最多 5 张。加入后会自动写入提示词，并传给生成模型。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }

    private func append(_ data: [Data]) {
        error = nil
        var failures = 0
        let remaining = AIReferenceImage.limit - images.count
        for value in data.prefix(remaining) {
            do { images.append(try AIReferenceImage(data: value)) }
            catch { failures += 1 }
        }
        if failures > 0 { error = "有 \(failures) 张图片无法读取，请选择有效的图片文件。" }
        if data.count > remaining { error = "最多保留 5 张参考图，超出的图片未加入。" }
    }

    private func chooseImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        var data: [Data] = []
        for url in panel.urls {
            if let value = try? Data(contentsOf: url) { data.append(value) }
            else { error = "无法读取图片：\(url.lastPathComponent)" }
        }
        if !data.isEmpty { append(data) }
    }

    private func pasteImages() {
        let board = NSPasteboard.general
        if let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            append(urls.compactMap { try? Data(contentsOf: $0) })
        } else if let values = board.readObjects(forClasses: [NSImage.self]) as? [NSImage], !values.isEmpty {
            append(values.compactMap(\.tiffRepresentation))
        } else {
            error = "剪贴板中没有可读取的图片。"
        }
    }
}
