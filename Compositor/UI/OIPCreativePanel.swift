import SwiftUI
import AppKit
import ImageIO

struct OIPCreativePanel: View {
    @Bindable var workflow: OIPWorkflow
    @Binding var images: [AIReferenceImage]
    let subject: String
    let purpose: String
    @State private var tab = 0
    @State private var category = ""
    @State private var cardQuery = ""
    @State private var showExperimental = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workflow.statistics).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Link("Open Image Prompts ↗", destination: URL(string: "https://github.com/NanmiCoder/open-image-prompts")!)
                    .font(.caption)
            }
            Picker("双 Skill 创作流", selection: $tab) {
                Text("① Taste · 视觉方向").tag(0)
                Text("② Prompts · 真实参考").tag(1)
            }.pickerStyle(.segmented)
            if let error = workflow.error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
            if tab == 0 { taste } else { references }
        }
        .onAppear {
            workflow.spec.subject = subject; workflow.spec.use = purpose
            if workflow.query.isEmpty { workflow.query = [subject, purpose].filter { !$0.isEmpty }.joined(separator: " ") }
        }
        .sheet(item: $workflow.browsing) { record in
            OIPRecordDetail(record: record, images: $images, selected: workflow.selected.contains { $0.id == record.id }) {
                workflow.toggle(record)
                return workflow.selected.contains { $0.id == record.id }
            }
        }
    }

    private var taste: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("按视觉语言找风格卡", text: $cardQuery).textFieldStyle(.roundedBorder)
                Picker("领域", selection: $category) {
                    Text("全部领域").tag("")
                    ForEach(Array(Set(workflow.cards.map(\.categoryTitle))).sorted(), id: \.self) { Text($0).tag($0) }
                }.frame(width: 220)
            }
            Toggle("显示实验性方向（语料已复核，生成效果待验证）", isOn: $showExperimental).font(.caption)
            HStack(alignment: .top, spacing: 16) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        Button("不使用风格卡") { workflow.clearCard() }
                        ForEach(workflow.cards.filter {
                            (category.isEmpty || $0.categoryTitle == category) && (!$0.experimental || showExperimental) &&
                            (cardQuery.isEmpty || ($0.nameZh + $0.nameEn + $0.trigger + $0.visualDna).localizedCaseInsensitiveContains(cardQuery))
                        }) { card in
                            Button {
                                Task { await workflow.choose(card) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(card.nameZh).font(.headline)
                                        Text(card.nameEn).font(.caption).foregroundStyle(.secondary)
                                        if card.experimental { Text("实验性方向").font(.caption).foregroundStyle(.orange) }
                                    }
                                    Spacer()
                                    if workflow.card?.id == card.id { Image(systemName: "checkmark.circle.fill") }
                                }.padding(8).frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.bordered)
                        }
                    }
                }.frame(width: 275)
                ScrollView {
                    if let card = workflow.card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(card.nameZh).font(.title3.bold())
                            Text(card.trigger).font(.callout)
                            Text("不适用：\(card.notFor)").font(.caption).foregroundStyle(.secondary)
                            Text(card.visualDna)
                            Text(card.compositionLightColorMaterial).foregroundStyle(.secondary)
                            Text("边界：\(card.boundaries)").font(.caption)
                            if let boundary = card.selectionBoundary { Text(boundary).font(.caption).foregroundStyle(.orange) }
                            if let note = card.pilotNote { Text(note).font(.caption).foregroundStyle(.secondary) }
                            Text("避免：\(card.antiPatterns)").font(.caption).foregroundStyle(.orange)
                            Text("已复核真实语料；尚未完成生成质量验证。").font(.caption).foregroundStyle(.secondary)
                            Button("查看真实参考 / 检索案例 →") { tab = 1 }
                            if card.references.isEmpty {
                                Text("上游未为此卡填写案例 ID；请按自己的创作意图检索真实案例。").font(.caption).foregroundStyle(.orange)
                            } else if !workflow.missingReferenceIDs.isEmpty {
                                Text("当前资料库缺少引用：" + workflow.missingReferenceIDs.joined(separator: "、")).font(.caption).foregroundStyle(.orange)
                            }
                            DisclosureGroup("原始风格模板（含待填参数，不会直接发送）") {
                                Text(card.template).font(.caption).textSelection(.enabled)
                            }
                            if let url = URL(string: card.source) { Link("风格卡原文", destination: url) }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("先比较方向，再选择一张主卡。").font(.headline)
                            Text("风格卡提供构图、光线、配色与质感的视觉语法。主体、用途、比例和禁止项始终由你决定。")
                            Text("选卡后，在「画面语言」阶段细化创作说明；真实案例可以单独浏览，不会自动传给生成模型。").foregroundStyle(.secondary)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var references: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("按原始意图检索，例如：香水广告、夜间电影人像", text: $workflow.query)
                    .textFieldStyle(.roundedBorder).onSubmit { Task { await workflow.search() } }
                    .accessibilityIdentifier("oipSearch")
                Button(workflow.searching ? "检索中…" : "查找真实参考") { Task { await workflow.search() } }
                    .disabled(workflow.searching || workflow.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("oipSearchSubmit")
            }
            Text("原文、作者和来源完整保留。标签与关键词用于匹配，不代表已检查每张图片。可先用简明关键词缩小范围，再看图选择。")
                .font(.caption).foregroundStyle(.secondary)
            if !workflow.results.constraints.isEmpty {
                Text("识别的约束：" + workflow.results.constraints.joined(separator: " · ")).font(.caption)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !workflow.examples.isEmpty {
                        Text("风格卡的真实案例 · 展示视觉语法，不保证与你的主体匹配").font(.headline)
                        recordGrid(workflow.examples)
                    }
                    if !workflow.results.exact.isEmpty {
                        Text("标签 / 关键词匹配 · 共 \(workflow.results.total) 条，显示前 \(workflow.results.exact.count) 条").font(.headline)
                        recordGrid(workflow.results.exact)
                    }
                    if !workflow.results.related.isEmpty {
                        Text("相关参考 · 每条明确缺少一项审美条件").font(.headline)
                        recordGrid(workflow.results.related)
                    }
                    if workflow.results.exact.isEmpty && workflow.results.related.isEmpty && !workflow.searching {
                        Text("没有当前意图的检索结果。可调整检索词；系统不会伪造图片、提示词或作者来源。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !workflow.selected.isEmpty {
                HStack {
                    Text("已选文字参考 \(workflow.selected.count) / 3").font(.caption)
                    ForEach(workflow.selected) { record in
                        Button("@\(record.author) ×") { workflow.toggle(record) }.font(.caption)
                    }
                }
            }
            Text("全部参考图随应用内置，检索与看图无需联网。").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func recordGrid(_ records: [OIPRecord]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
            ForEach(records) { record in
                Button { workflow.browsing = record } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        if let image = record.images.first { OIPImagePreview(image: image).frame(height: 95).clipped() }
                        Text("原文 / 译文节选").font(.caption2).foregroundStyle(.secondary)
                        Text(record.title).font(.caption).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                        Text("@\(record.author)").font(.caption2).foregroundStyle(.secondary)
                        if !record.missing.isEmpty { Text("缺少：" + record.missing.joined(separator: "、")).font(.caption2).foregroundStyle(.orange) }
                        if workflow.selected.contains(where: { $0.id == record.id }) { Text("已选文字参考").font(.caption2).foregroundStyle(Color.accentColor) }
                    }.padding(7).frame(maxWidth: .infinity)
                }.buttonStyle(.bordered)
            }
        }
    }
}

struct OIPImagePreview: View {
    let image: OIPImage
    @State private var bitmap: NSImage?
    @State private var failed = false
    private var store: OIPImageStore { .shared }
    var body: some View {
        Group {
            if let bitmap { Image(nsImage: bitmap).resizable().scaledToFit() }
            else if failed {
                VStack { Image(systemName: "photo.badge.exclamationmark"); Text("内置图片无法读取，请使用完整安装包").font(.caption2) }
                    .foregroundStyle(.secondary)
            } else { ProgressView().controlSize(.small) }
        }
        .frame(maxWidth: .infinity).background(.quaternary.opacity(0.3))
        .task(id: image.id) {
            bitmap = nil; failed = false
            do {
                let data = try await store.data(for: image)
                try Task.checkCancellation()
                let preview = await Task.detached {
                    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil as CGImage? }
                    return CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 800
                    ] as CFDictionary)
                }.value
                try Task.checkCancellation()
                bitmap = preview.map { NSImage(cgImage: $0, size: .zero) }
                failed = bitmap == nil
            } catch is CancellationError {} catch { failed = true }
        }
        .accessibilityLabel("Open Image Prompts 真实参考图 \(image.recordID)")
    }
}

private struct OIPRecordDetail: View {
    @Environment(\.dismiss) private var dismiss
    let record: OIPRecord
    @Binding var images: [AIReferenceImage]
    @State var selected: Bool
    let toggle: () -> Bool
    @State private var activeImage: OIPImage?
    @State private var adding = false
    @State private var error: String?
    @State private var translation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("@\(record.author) · \(record.id)").font(.headline).textSelection(.enabled)
                Spacer()
                if let source = URL(string: record.source), source.scheme == "https" { Link("作者原始来源 ↗", destination: source) }
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            HStack(alignment: .top, spacing: 16) {
                VStack {
                    if let image = activeImage ?? record.images.first {
                        OIPImagePreview(image: image).frame(height: 255)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(record.images) { item in
                                    Button { activeImage = item } label: {
                                        OIPImagePreview(image: item).frame(width: 65, height: 50)
                                    }.buttonStyle(.bordered)
                                }
                            }
                        }
                        Button(adding ? "正在读取图片…" : "将当前图片加入生成参考（\(images.count)/5）") {
                            adding = true; error = nil
                            Task {
                                defer { adding = false }
                                do {
                                    let data = try await OIPImageStore.shared.data(for: image)
                                    guard images.count < AIReferenceImage.limit else { return }
                                    var reference = try AIReferenceImage(data: data)
                                    reference.sourceRecordID = record.id
                                    reference.sourceAuthor = record.author
                                    reference.sourceURL = URL(string: record.source)
                                    images.append(reference)
                                } catch { self.error = "无法读取这张图片：\(error.localizedDescription)" }
                            }
                        }.disabled(adding || images.count >= AIReferenceImage.limit)
                    }
                    Text("只有明确加入的图片才会发给模型；选择文字参考不会自动添加图片。").font(.caption).foregroundStyle(.secondary)
                }.frame(width: 310)
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.missing.isEmpty ? "原始帖子 / 提示词" : "相关参考 · 缺少：" + record.missing.joined(separator: "、")).font(.headline)
                    Text("原文可能包含作者说明，不一定是可直接执行的提示词。译文与新提示词均不是原文。").font(.caption).foregroundStyle(.secondary)
                    Toggle("查看中文译文（与原文分开）", isOn: $translation).disabled(record.zh.isEmpty)
                    ScrollView {
                        Text(translation ? record.zh : record.original).font(.callout).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("复制未改动的原始文本") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(record.original, forType: .string)
                    }
                    if !record.reasons.isEmpty { Text("匹配依据：" + record.reasons.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                    Text(record.tags.joined(separator: " · ")).font(.caption2).foregroundStyle(.tertiary).lineLimit(3)
                    Button(selected ? "移除文字参考" : "作为 AI 整理的文字参考（最多 3 条）") {
                        selected = toggle()
                    }.buttonStyle(.borderedProminent)
                }
            }
            if let error { Text(error).foregroundStyle(.red).font(.caption) }
            Text("资料整理与标签 © Open Image Prompts（CC BY 4.0）；第三方图片与帖子权利归原作者。")
                .font(.caption2).foregroundStyle(.secondary)
        }.padding(20).frame(width: 790, height: 550)
    }
}

struct OIPDirectionEditor: View {
    @Bindable var workflow: OIPWorkflow
    @Binding var images: [AIReferenceImage]
    @State private var settings = AISettingsController.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Open Image Prompts · 创作说明").font(.headline)
            Text("参考 \(workflow.selected.count) 条原始记录；\(images.filter { $0.sourceRecordID != nil }.count) 张已明确添加的真实图片。构图、材质、比例均可修改，用户约束优先。").font(.caption).foregroundStyle(.secondary)
            field("构图", text: $workflow.spec.composition)
            field("材质与质感", text: $workflow.spec.materialTexture)
            field("光线", text: $workflow.spec.lighting)
            field("配色", text: $workflow.spec.palette)
            field("氛围", text: $workflow.spec.mood)
            field("画幅比例", text: $workflow.spec.aspectRatio)
            field("必须保留（每行一项）", text: Binding(get: { workflow.spec.invariants.joined(separator: "\n") }, set: { workflow.spec.invariants = $0.components(separatedBy: "\n").filter { !$0.isEmpty } }))
            field("避免（每行一项）", text: Binding(get: { workflow.spec.avoid.joined(separator: "\n") }, set: { workflow.spec.avoid = $0.components(separatedBy: "\n").filter { !$0.isEmpty } }))
            HStack {
                Button("使用当前创作说明") { workflow.outputLanguage = 0 }
                Button(workflow.deriving ? "正在整理…" : "AI 整理中英文新提示词") {
                    Task { await workflow.derive(credentials: settings.credentials, images: images) }
                }.disabled(workflow.deriving || !settings.credentials.hasAPIKey)
            }
            Text("AI 整理将使用设置中的多模态模型，发送当前创作说明、已选原始文本和已加入的 OIP 图片；会产生模型调用。也可直接使用创作说明，无需 API Key。")
                .font(.caption).foregroundStyle(.secondary)
            if let error = workflow.error { Text(error).font(.caption).foregroundStyle(.red) }
            if !workflow.english.isEmpty {
                Text("新提示词 · English（可编辑）").font(.headline)
                TextEditor(text: $workflow.english).frame(height: 100).border(.quaternary)
                Button("使用英文新提示词") { workflow.outputLanguage = 1 }
                Text("新提示词 · 简体中文（可编辑）").font(.headline)
                TextEditor(text: $workflow.chinese).frame(height: 100).border(.quaternary)
                Button("使用中文新提示词") { workflow.outputLanguage = 2 }
                Text(workflow.rationale).font(.caption).textSelection(.enabled)
            }
            DisclosureGroup("creative_spec 交接数据") { Text(workflow.spec.handoff).font(.caption).textSelection(.enabled) }
        }
    }
    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text, axis: .vertical).lineLimit(1...5).textFieldStyle(.roundedBorder)
        }
    }
}
