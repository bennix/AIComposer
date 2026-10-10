import Foundation

nonisolated struct AIStyle: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: [String: String]
    let summary: [String: String]
    let domain: [String: String]
    let lineage: [String: String]
    let features: [String: [String]]
    let prompt: String
    let source: String

    static var language: String {
        let code = Locale.preferredLanguages.first ?? "en"
        return ["zh", "ja", "ko"].first(where: { code.hasPrefix($0) }) ?? "en"
    }

    func text(_ value: [String: String]) -> String {
        value[Self.language] ?? value["en"] ?? value["zh"] ?? ""
    }

    var title: String { text(name) }
    var description: String { text(summary) }
    var category: String { text(domain) }
    var traits: [String] { features[Self.language] ?? features["en"] ?? [] }

    func matches(_ query: String, category: String) -> Bool {
        (category.isEmpty || self.category == category) &&
        (query.isEmpty || (Array(name.values) + Array(summary.values) + Array(lineage.values))
            .contains { $0.localizedCaseInsensitiveContains(query) })
    }
}

nonisolated struct AIStyleAtlas: Codable, Sendable {
    let source: String
    let importedAt: String
    let total: Int
    let styles: [AIStyle]

    static func decode(_ data: Data) throws -> Self {
        let atlas = try JSONDecoder().decode(Self.self, from: data)
        guard !atlas.styles.isEmpty, atlas.total >= atlas.styles.count,
              Set(atlas.styles.map(\.id)).count == atlas.styles.count,
              atlas.styles.allSatisfy({ !$0.id.isEmpty && !$0.title.isEmpty && !$0.prompt.isEmpty }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return atlas
    }

    static var importedURL: URL {
        URL.applicationSupportDirectory.appending(path: "AIComposer/StyleAtlas.json")
    }

    static func load() throws -> Self {
        if FileManager.default.fileExists(atPath: importedURL.path) {
            return try decode(Data(contentsOf: importedURL))
        }
        guard let url = Bundle.main.url(forResource: "StyleAtlas", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }
}

nonisolated struct AICreativeBrief {
    var subject = ""
    var purpose = ""
    var direction = ""
    var style: AIStyle?

    var prompt: String {
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty else { return "" }
        let base = style.map {
            $0.prompt.contains("[subject]")
                ? $0.prompt.replacingOccurrences(of: "[subject]", with: subject)
                : "\(subject). \($0.prompt)"
        } ?? subject
        return ([base] + [purpose, direction].filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }).joined(separator: "\n")
    }
}
