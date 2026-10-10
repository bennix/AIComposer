import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AICreativeGuide: View {
    @Environment(\.dismiss) private var dismiss
    let apply: (String) -> Void
    @State private var brief = AICreativeBrief()
    @State private var atlas: AIStyleAtlas?
    @State private var error: String?
    @State private var step = 0
    @State private var query = ""
    @State private var category = ""
    @State private var preview = ""
    private let steps = ["创作意图", "探索风格", "画面语言", "确认提示词"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack").font(.title).foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("引导式创作").font(.title2.bold())
                    Text("从一个想法，到属于你的视觉表达").foregroundStyle(.secondary)
                }
                Spacer()
                Button("导入风格库…", action: importAtlas)
            }
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    Label(steps[index], systemImage: index < step ? "checkmark.circle.fill" : "\(index + 1).circle")
                        .foregroundStyle(index == step ? Color.accentColor : Color.secondary)
                    if index < steps.count - 1 { Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary); Spacer() }
                }
            }.font(.callout)
            Divider()
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            Group {
                switch step {
                case 0: intent
                case 1: styles
                case 2: direction
                default:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("可以自由修改，确认后进入模型与尺寸设置。")
                        TextEditor(text: $preview).font(.body).accessibilityIdentifier("creativeGuidePreview")
                        Text("生成结果会沿用编辑器现有图层流程，可继续编辑或撤销。").foregroundStyle(.secondary)
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Divider()
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                if step > 0 { Button("上一步") { step -= 1 } }
                Spacer()
                Button(step == 3 ? "使用提示词" : "下一步") {
                    if step == 3 { apply(preview); dismiss() }
                    else { if step == 2 { preview = brief.prompt }; step += 1 }
                }
                .buttonStyle(.borderedProminent)
                .disabled(step == 0 ? brief.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty :
                          step == 3 ? preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : false)
                .accessibilityIdentifier("creativeGuideNext")
            }
        }
        .padding(24).frame(width: 800, height: 650)
        .task {
            do { atlas = try AIStyleAtlas.load() }
            catch { self.error = "风格库加载失败：\(error.localizedDescription)" }
        }
    }

    private var intent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("01 / 你想创作什么？").font(.title3.bold())
            Text("先描述主体与场景，再用风格塑造表达。已有画面重绘时，请描述要保留的内容。")
                .foregroundStyle(.secondary)
            TextField("例如：雨后的东京街角，一位撑伞的旅人", text: $brief.subject)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("creativeGuideSubject")
            Text("作品用途（选填）").font(.headline)
            TextField("例如：旅行杂志封面，顶部预留标题空间", text: $brief.purpose).textFieldStyle(.roundedBorder)
        }
    }

    private var styles: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let atlas {
                HStack {
                    Text("已导入 \(atlas.styles.count) / 来源共 \(atlas.total) 条").foregroundStyle(.secondary)
                    Spacer()
                    Link("引用：Vibe Shot Club 风格图谱", destination: URL(string: "https://vibeshot.club/lexicon")!)
                }.font(.caption)
                if atlas.styles.count < atlas.total {
                    Text("当前为公开预览库；完整库可通过授权 JSON 文件导入。").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    TextField("搜索风格、关键词、谱系", text: $query).textFieldStyle(.roundedBorder)
                    Picker("领域", selection: $category) {
                        Text("全部领域").tag("")
                        ForEach(Array(Set(atlas.styles.map(\.category))).sorted(), id: \.self) { Text($0).tag($0) }
                    }.frame(width: 260)
                }
                HStack(alignment: .top, spacing: 18) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            Button("不指定风格") { brief.style = nil }
                            ForEach(atlas.styles.filter { $0.matches(query, category: category) }) { style in
                                Button { brief.style = style } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(style.title).font(.headline)
                                            Text(style.text(style.lineage)).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if brief.style?.id == style.id { Image(systemName: "checkmark.circle.fill") }
                                    }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(.bordered)
                            }
                            if atlas.styles.filter({ $0.matches(query, category: category) }).isEmpty {
                                Text("没有匹配的风格，请更换关键词或领域。").foregroundStyle(.secondary)
                            }
                        }
                    }.frame(width: 320)
                    ScrollView {
                        if let style = brief.style {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(style.title).font(.title2.bold())
                                Text(style.description)
                                ForEach(style.traits, id: \.self) { Text("• \($0)").foregroundStyle(.secondary) }
                                Text(style.prompt).font(.caption).textSelection(.enabled)
                                if let url = URL(string: style.source), url.scheme == "https" {
                                    Link("查看来源原文", destination: url)
                                }
                            }
                        } else { Text("选择一个风格，了解它的画面特征与提示词。也可以保持自由创作。").foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var direction: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("03 / 把风格变成你的画面").font(.title3.bold())
            Text(brief.style.map { "已选择：\($0.title)。模板会提供基础视觉语言，你可以补充构图、光线、配色和需要避免的元素。" } ?? "补充构图、光线、配色和需要避免的元素。")
                .foregroundStyle(.secondary)
            TextEditor(text: $brief.direction).frame(height: 150)
                .border(.quaternary).accessibilityIdentifier("creativeGuideDirection")
            Text("例如：低机位，暖色窗光与冷色街道形成对比；保留伞的轮廓，避免文字与水印。")
                .font(.callout).foregroundStyle(.secondary)
            Text("提示词预览").font(.headline)
            ScrollView { Text(brief.prompt).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
        }
    }

    private func importAtlas() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let imported = try AIStyleAtlas.decode(data)
            try FileManager.default.createDirectory(at: AIStyleAtlas.importedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: AIStyleAtlas.importedURL, options: .atomic)
            atlas = imported
            brief.style = nil
            category = ""
            query = ""
            error = nil
        } catch { self.error = "导入失败，原风格库已保留：\(error.localizedDescription)" }
    }
}
