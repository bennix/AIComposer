import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AICreativeGuide: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var referenceImages: [AIReferenceImage]
    @Binding var characterPlan: AICharacterPlan
    let apply: (String) -> Void
    @State private var visualLibrary: AIPromptVisualLibrary?
    @State private var brief = AICreativeBrief()
    @State private var atlas: AIStyleAtlas?
    @State private var gallery: AIPromptGallery?
    @State private var reference: AIPromptReference?
    @State private var exploration = 0
    @State private var galleryQuery = ""
    @State private var galleryCategory = ""
    @State private var visibleReferences = 100
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
                case 1:
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("探索方式", selection: $exploration) {
                            Text("风格图谱").tag(0)
                            Text("图库灵感").tag(1)
                        }.pickerStyle(.segmented)
                        if exploration == 0 { styles } else { inspirations }
                    }
                case 2: direction
                default:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("可以自由修改，确认后进入模型与尺寸设置。")
                        TextEditor(text: referencePromptBinding).font(.body).accessibilityIdentifier("creativeGuidePreview")
                        if let error = characterPlan.validation(references: referenceImages.map(\.characterReference)) {
                            Text(error).foregroundStyle(.orange)
                        }
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
                          step == 3 ? preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || characterPlan.validation(references: referenceImages.map(\.characterReference)) != nil : false)
                .accessibilityIdentifier("creativeGuideNext")
            }
        }
        .padding(24).frame(width: 800, height: 650)
        .task {
            do { atlas = try AIStyleAtlas.load() }
            catch { self.error = "风格库加载失败：\(error.localizedDescription)" }
            do {
                let loaded = try AIPromptGallery.load()
                gallery = loaded
                visualLibrary = try AIPromptVisualLibrary.load(gallery: loaded)
            }
            catch { self.error = "图库索引加载失败：\(error.localizedDescription)" }
        }
    }

    private var referencePromptBinding: Binding<String> {
        Binding(get: { AIReferenceImage.prompt(preview, images: referenceImages, plan: characterPlan) },
                set: { preview = AIReferenceImage.editableBase($0, images: referenceImages, plan: characterPlan) })
    }

    private var intent: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("01 / 你想创作什么？").font(.title3.bold())
            Text("先描述主体与场景，再用风格塑造表达。已有画面重绘时，请描述要保留的内容。")
                .foregroundStyle(.secondary)
            TextField("例如：雨后的东京街角，一位撑伞的旅人", text: $brief.subject)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("creativeGuideSubject")
            AICharacterGuideView(plan: $characterPlan, references: referenceImages)
            AIReferenceImagesView(images: $referenceImages, people: characterPlan.enabled ? characterPlan.people : [])
            Text("作品用途（选填）").font(.headline)
            TextField("例如：旅行杂志封面，顶部预留标题空间", text: $brief.purpose).textFieldStyle(.roundedBorder)
        }
        }
    }

    private var styles: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let atlas {
                HStack {
                    Text("已导入 \(atlas.styles.count) / 来源共 \(atlas.total) 条").foregroundStyle(.secondary)
                    Spacer()
                    if let url = URL(string: atlas.source), url.scheme == "https" {
                        Link("查看风格库来源", destination: url)
                    }
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

    private var filteredReferences: [AIPromptReference] {
        gallery?.entries.filter { $0.matches(galleryQuery, category: galleryCategory) } ?? []
    }

    private var inspirations: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let gallery {
                HStack {
                    Text("OpenNana · \(gallery.total) 条公开案例索引 · \(gallery.importedAt)")
                    Spacer()
                    Link("来源图库", destination: URL(string: gallery.source)!)
                }.font(.caption).foregroundStyle(.secondary)
                Text("付费案例通过公开样图反推为新提示词，保留你的主体与用途。原始锁定文本不包含在索引中。")
                    .font(.caption).foregroundStyle(.secondary)
                if let visualLibrary {
                    Text("已看图归纳 \(visualLibrary.assignments.count) / \(gallery.total) · \(visualLibrary.recipes.count) 类画面配方")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    TextField("搜索案例标题，例如：水彩、充气、海报", text: $galleryQuery)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("creativeGuideGallerySearch")
                    Picker("类别", selection: $galleryCategory) {
                        Text("全部类别").tag("")
                        ForEach(Array(Set(gallery.entries.map(\.category))).sorted(), id: \.self) { Text($0).tag($0) }
                    }.frame(width: 200)
                }
                HStack(alignment: .top, spacing: 18) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            Text("匹配 \(filteredReferences.count) 条 · 类别按标题归纳").font(.caption).foregroundStyle(.secondary)
                            Button("不使用图库参考") { reference = nil }
                            ForEach(Array(filteredReferences.prefix(visibleReferences))) { entry in
                                Button { reference = entry } label: {
                                    HStack {
                                        Text(entry.title).multilineTextAlignment(.leading)
                                        Spacer()
                                        if reference?.id == entry.id { Image(systemName: "checkmark.circle.fill") }
                                    }.padding(8).frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(.bordered)
                            }
                            if filteredReferences.isEmpty {
                                Text("没有匹配案例，请更换关键词。").foregroundStyle(.secondary)
                            } else if visibleReferences < filteredReferences.count {
                                Button("显示更多案例") { visibleReferences += 100 }
                            }
                        }
                    }.frame(width: 320)
                    ScrollView {
                        if let reference {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(reference.title).font(.headline)
                                AsyncImage(url: URL(string: reference.thumbnail)) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Text("公开样图预览；网络不可用时可打开来源查看").font(.caption).foregroundStyle(.secondary)
                                }.frame(maxHeight: 190).accessibilityLabel("图库公开样图")
                                Text("公开样图归纳 · 可迁移的配方家族").font(.caption).foregroundStyle(.secondary)
                                if let recipe = visualLibrary?.recipe(for: reference) {
                                    Text(recipe.summary).font(.callout)
                                }
                                if reference.mediaType == "video" {
                                    Text("视频案例用于静态画面灵感，当前引导生成图片。").font(.caption)
                                }
                                if facets(for: reference).isEmpty {
                                    Text("配方未加载，请查看加载错误；也可填写自己的画面描述。")
                                }
                                ForEach(facets(for: reference)) { facet in
                                    Text("\(facet.dimension) · \(facet.title)")
                                }
                                Link("查看案例与原始提示词入口", destination: URL(string: reference.source)!)
                            }
                        } else {
                            Text("选择一个与你的创作意图接近的案例，借鉴画面方法，再创作自己的内容。")
                                .foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onChange(of: galleryQuery) { visibleReferences = 100 }
        .onChange(of: galleryCategory) { visibleReferences = 100 }
    }

    private func facets(for reference: AIPromptReference) -> [AIPromptFacet] {
        visualLibrary?.facets(for: reference) ?? reference.suggestions
    }

    private var direction: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            Text("03 / 把风格变成你的画面").font(.title3.bold())
            Text(brief.style.map { "已选择：\($0.title)。模板会提供基础视觉语言，你可以补充构图、光线、配色和需要避免的元素。" } ?? "补充构图、光线、配色和需要避免的元素。")
                .foregroundStyle(.secondary)
            if let reference {
                Text("灵感参考：\(reference.title)").font(.headline)
                Text(visualLibrary?.recipe(for: reference)?.summary ?? reference.basis)
                    .font(.caption).foregroundStyle(.secondary)
                Button("使用这套画面语言") { brief.useFacets(facets(for: reference)) }
                    .disabled(facets(for: reference).isEmpty)
                ForEach(facets(for: reference)) { facet in facetButton(facet) }
            }
            DisclosureGroup("更多可组合画面语言") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(AIPromptReference.visualOptions) { facet in facetButton(facet) }
                }
            }
            if !brief.facets.isEmpty {
                Text("已组合：" + brief.facets.map(\.title).joined(separator: "、"))
                    .font(.caption).foregroundStyle(.secondary)
                Button("清除画面语言选择") { brief.facets = [] }
            }
            TextEditor(text: $brief.direction).frame(height: 100)
                .border(.quaternary).accessibilityIdentifier("creativeGuideDirection")
            Text("例如：低机位，暖色窗光与冷色街道形成对比；保留伞的轮廓，避免文字与水印。")
                .font(.callout).foregroundStyle(.secondary)
            Text("提示词预览").font(.headline)
            ScrollView { Text(AIReferenceImage.prompt(brief.prompt, images: referenceImages, plan: characterPlan)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
        }
        }
    }

    private func facetButton(_ facet: AIPromptFacet) -> some View {
        Button { brief.toggleFacet(facet) } label: {
            Label("\(facet.dimension) · \(facet.title)", systemImage: brief.facets.contains(facet) ? "checkmark.circle.fill" : "plus.circle")
        }.buttonStyle(.bordered)
        .help(facet.instruction)
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
