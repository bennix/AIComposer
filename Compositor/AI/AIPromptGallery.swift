import Foundation

nonisolated struct AIPromptFacet: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let dimension: String
    let title: String
    let instruction: String
}

nonisolated struct AIPromptReference: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let mediaType: String
    let source: String
    let thumbnail: String

    var category: String {
        if mediaType == "video" { return "视频参考" }
        if title.localizedCaseInsensitiveContains("UI") || title.contains("界面") { return "界面设计" }
        if title.contains("海报") || title.contains("封面") { return "海报与版式" }
        if title.contains("人像") || title.contains("肖像") || title.contains("写真") { return "人像摄影" }
        if title.contains("产品") || title.contains("商品") || title.contains("主图") { return "产品与材质" }
        if title.contains("插画") || title.contains("手绘") { return "插画与绘画" }
        return "其他灵感"
    }

    func matches(_ query: String, category: String) -> Bool {
        (category.isEmpty || self.category == category) &&
        (query.isEmpty || title.localizedCaseInsensitiveContains(query))
    }

    // These are new, transferable instructions; no locked prompt is decoded or reproduced.
    var suggestions: [AIPromptFacet] {
        if let recipe = Self.observedRecipes[id] { return recipe }
        return []
    }

    var basis: String {
        Self.observedRecipes[id] == nil
            ? "公开缩略图归纳为可迁移的配方家族；不代表原始提示词。"
            : "依据公开样图人工观察归纳的创作配方；非来源原始提示词。"
    }

    private static func facet(_ id: String, _ dimension: String, _ title: String, _ instruction: String) -> AIPromptFacet {
        AIPromptFacet(id: id, dimension: dimension, title: title, instruction: instruction)
    }

    static let visualOptions: [AIPromptFacet] = [
        facet("minimal", "构图", "克制留白", "Use generous negative space, a clear focal point, and a restrained hierarchy of details."),
        facet("analog", "质感", "复古印刷与颗粒", "Use subtle analog grain, gently softened contrast, and a restrained vintage palette; keep the subject legible."),
        facet("watercolor", "媒介", "透明水彩", "Use transparent watercolor washes, soft pigment edges, and visible textured paper."),
        facet("sketch", "媒介", "手绘线条", "Use expressive hand-drawn contours, varied line weight, and selective color accents."),
        facet("inflated", "材质", "充气软体", "Interpret the subject as inflated soft forms with visible seams, gentle wrinkles, and believable contact shadows."),
        facet("metal", "材质", "金属反射", "Use coherent metallic reflections, controlled specular highlights, and physically plausible surface roughness."),
        facet("glass", "材质", "透明折射", "Use transparent surfaces with realistic refraction, edge highlights, and visible background transmission."),
        facet("realistic", "质感", "真实细节", "Use believable proportions, fine surface detail, and consistent photographic lighting and shadows."),
        facet("cinematic", "光线", "电影层次", "Separate foreground, subject, and background with motivated key light and controlled shadow depth."),
        facet("backlight", "光线", "逆光轮廓", "Use a backlit rim to define the silhouette, preserving detail in the subject's shadowed areas."),
        facet("neon", "配色", "冷暖霓虹", "Use a restrained cool and warm neon contrast, with colored light reflected consistently on nearby surfaces."),
        facet("poster", "版式", "预留文字层级", "Reserve uncluttered space for a headline and supporting copy. Do not invent promotional wording; render only text explicitly supplied by the user."),
        facet("ui", "版式", "界面信息层级", "Organize content on a consistent grid with clear navigation, readable labels, restrained controls, and a distinct primary action.")
    ]

    private static let observedRecipes: [String: [AIPromptFacet]] = [
        "27987": [
            facet("brutal-type", "版式", "超大斜切字形", "Use oversized angular display shapes as the focal point, with a compact headline zone and a small footer zone. Only render user-supplied wording."),
            facet("vermillion", "配色", "朱红 / 黑 / 米白", "Use a vermilion field with black and warm ivory accents, hard graphic shadows, and subtle paper grain.")
        ],
        "27989": [
            facet("retro-diagonal", "构图", "对角线物件序列", "Arrange the subject along a broad diagonal band that leads from lower left to upper right, with staggered scale and clear overlap."),
            facet("retro-gouache", "媒介", "复古不透明绘画", "Use opaque hand-painted color, visible brush texture, a warm ivory ground, deep blue graphic shapes, and restrained red accents.")
        ],
        "27992": [
            facet("soft-sculpture", "材质", "带缝线的软雕塑", "Translate the subject into inflated red fabric sculptures with stitched seams, subtle wrinkles, and soft contact shadows on a warm white floor."),
            facet("studio-space", "构图", "棚拍与上方留白", "Use a frontal studio view, a quiet ivory background, and generous upper negative space for user-supplied typography.")
        ],
        "27996": [
            facet("watercolor-path", "构图", "蜿蜒叙事路线", "Distribute related subject details along a gentle winding path, using small botanical accents to connect the stages and ample surrounding negative space."),
            facet("gentle-paper", "媒介", "纸上生活水彩", "Use delicate watercolor illustration on textured off-white paper, muted greens, warm everyday colors, and deep blue typographic accents.")
        ],
        "27962": [
            facet("food-close", "构图", "整体与细节双层展示", "Present the main subject behind a closer detail view, using depth and scale to reveal its surface and interior structure."),
            facet("food-light", "光线", "暖侧光与深色底", "Use warm directional side light against a dark textured background, preserving rich highlights, natural imperfections, and tactile surface detail.")
        ],
        "27950": [
            facet("editor-grid", "版式", "多栏编辑工作台", "Use a structured desktop workspace: asset rail at left, central preview, property panel at right, and a timeline below. Keep spacing, labels, and selected states coherent."),
            facet("editor-color", "配色", "深色工作区与高亮状态", "Use charcoal workspace panels, a pale inspector, small colorful previews, and a restrained violet accent for active controls.")
        ]
    ]
}

nonisolated struct AIPromptGallery: Codable, Sendable {
    let source: String
    let importedAt: String
    let total: Int
    let scope: String
    let entries: [AIPromptReference]

    static func decode(_ data: Data) throws -> Self {
        let gallery = try JSONDecoder().decode(Self.self, from: data)
        guard gallery.total == gallery.entries.count, !gallery.entries.isEmpty,
              Set(gallery.entries.map(\.id)).count == gallery.entries.count,
              gallery.entries.allSatisfy({ !$0.title.isEmpty && URL(string: $0.source)?.scheme == "https" }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return gallery
    }

    static func load() throws -> Self {
        guard let url = Bundle.main.url(forResource: "OpenNanaGallery", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }
}
