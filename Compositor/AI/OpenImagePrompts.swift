import Foundation
import SQLite3
import CryptoKit

nonisolated enum OIPResources {
    static func url(_ name: String, _ ext: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "OpenImagePrompts")
                ?? Bundle.main.url(forResource: name, withExtension: ext) else { throw CocoaError(.fileNoSuchFile) }
        return url
    }
    static func decode<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(contentsOf: url(name, "json")))
    }
    static let directory = URL.applicationSupportDirectory.appending(path: "AIComposer/OpenImagePrompts")
}

nonisolated struct OIPStyleCard: Decodable, Identifiable, Sendable {
    let id: String
    let nameZh: String
    let nameEn: String
    let category: String
    let trigger: String
    let notFor: String
    let visualDna: String
    let compositionLightColorMaterial: String
    let boundaries: String
    let antiPatterns: String
    let template: String
    let selectionBoundary: String?
    let pilotNote: String?
    let validationStatus: String
    let references: [String]
    let source: String
    var experimental: Bool { validationStatus.contains("experimental") }
    var categoryTitle: String {
        ["architecture-interior": "建筑与室内", "graphic-abstract": "平面与抽象", "illustration-storytelling": "插画与叙事",
         "landscape-city": "风景与城市", "portrait-photography": "人像摄影", "poster-cover": "海报与封面",
         "print-paint-craft": "绘画与手工", "product-advertising": "产品广告", "sci-fi-fantasy": "科幻与幻想"][category] ?? category
    }
    static func load() throws -> [Self] {
        let cards = try OIPResources.decode([Self].self, "StyleCards")
        guard cards.count == 39, Set(cards.map(\.id)).count == 39 else { throw CocoaError(.fileReadCorruptFile) }
        return cards
    }
}

nonisolated struct OIPCreativeSpec: Codable, Equatable, Sendable {
    var styleCardId: String?
    var subject = ""
    var use = ""
    var composition = ""
    var materialTexture = ""
    var lighting = ""
    var palette = ""
    var mood = ""
    var invariants: [String] = []
    var avoid: [String] = []
    var aspectRatio = "unspecified"

    var prompt: String {
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return ["Subject: \(subject)", "Use: \(use)", "Composition: \(composition)",
                "Material/texture: \(materialTexture)", "Lighting: \(lighting)", "Palette: \(palette)",
                "Mood: \(mood)", "Aspect ratio: \(aspectRatio)", "Must preserve: \(invariants.joined(separator: "; "))",
                "Avoid: \(avoid.joined(separator: "; "))",
                "User subject, required text, invariants and avoid constraints override all style defaults. Do not add unspecified subjects, brands, props or scene metaphors."]
            .filter { !$0.hasSuffix(": ") }.joined(separator: "\n")
    }
    var handoff: String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? String(data: encoder.encode(["creative_spec": self]), encoding: .utf8)) ?? ""
    }
}

nonisolated struct OIPImage: Identifiable, Hashable, Sendable {
    let id: String
    let recordID: String
    let url: String
    let path: String
}
nonisolated struct OIPRecord: Identifiable, Sendable {
    let id: String
    let author: String
    let tool: String
    let source: String
    let original: String
    let zh: String
    let en: String
    let images: [OIPImage]
    let tags: [String]
    var missing: [String] = []
    var reasons: [String] = []
    var title: String { String((zh.isEmpty ? original : zh).prefix(65)).replacingOccurrences(of: "\n", with: " ") }
}
nonisolated struct OIPSearchResults: Sendable {
    var exact: [OIPRecord] = []
    var related: [OIPRecord] = []
    var constraints: [String] = []
    var total = 0
}

nonisolated struct OIPIntentConfig: Decodable, Sendable {
    struct Alias: Decodable, Sendable { let aliases: [String] }
    struct Concept: Decodable, Sendable {
        let id: String
        let aliases: [String]
        let lexical: [String]?
        let requireLexical: Bool?
        let requiredLexicalGroups: [[String]]?
        let requiredImageTags: [String]?
        let verifiedTweetIds: [String]?
        let verifiedOnly: Bool?
        let must: [String]?
        let should: [String]?
        let forbidden: [String]?
    }
    let version: String
    let labelAliases: [String: Alias]
    let negativeAliases: [String: [String]]
    let concepts: [Concept]
    let englishStopwords: [String]
    let chineseStopwords: [String]
}
nonisolated struct OIPTaxonomy: Decodable, Sendable {
    struct Dimension: Decodable, Sendable {
        struct Label: Decodable, Sendable { let key: String; let display: [String: String] }
        let key: String
        let labels: [Label]
    }
    let dimensions: [Dimension]
    var displayNames: [String: String] {
        Dictionary(uniqueKeysWithValues: dimensions.flatMap { dim in
            dim.labels.map { (dim.key + ":" + $0.key, $0.display["zh"] ?? $0.key) }
        })
    }
}

nonisolated struct OIPIntent: Sendable {
    var must = Set<String>()
    var should = Set<String>()
    var forbidden = Set<String>()
    var imageTags = Set<String>()
    var groups: [[String]] = []
    var terms: [String] = []
    var verifiedIDs = Set<String>()
    var verifiedOnly = false

    static func normalized(_ text: String) -> String {
        text.precomposedStringWithCompatibilityMapping.lowercased()
    }
    static func contains(_ text: String, _ term: String) -> Bool {
        let term = normalized(term)
        guard !term.isEmpty else { return false }
        if term.unicodeScalars.contains(where: { (0x4e00...0x9fff).contains($0.value) }) {
            return normalized(text).contains(term)
        }
        return normalized(text).range(of: "(?<![a-z0-9])" + NSRegularExpression.escapedPattern(for: term) + "(?![a-z0-9])", options: .regularExpression) != nil
    }
    static func parse(_ text: String, config: OIPIntentConfig, taxonomy: OIPTaxonomy) -> Self {
        var result = Self()
        let originalText = normalized(text)
        var positive = originalText
        var negativeMatches: [String] = []
        for (tag, aliases) in config.negativeAliases {
            for alias in aliases.sorted(by: { $0.count > $1.count }) where contains(originalText, alias) {
                result.forbidden.insert(tag)
                negativeMatches.append(normalized(alias))
            }
        }
        for alias in negativeMatches.sorted(by: { $0.count > $1.count }) { positive = positive.replacingOccurrences(of: alias, with: " ") }
        var matched: [String] = []
        let curated = Set(config.labelAliases.values.flatMap(\.aliases).map(normalized))
        var aliases: [String: Set<String>] = [:]
        for dim in taxonomy.dimensions {
            for label in dim.labels {
                for alias in [label.key.replacingOccurrences(of: "-", with: " ")] + Array(label.display.values) {
                    let key = normalized(alias)
                    if !curated.contains(key) { aliases[key, default: []].insert(dim.key + ":" + label.key) }
                }
            }
        }
        for (alias, tags) in aliases where tags.count == 1 && contains(positive, alias) {
            result.must.formUnion(tags); matched.append(alias)
        }
        for (tag, entry) in config.labelAliases {
            for alias in entry.aliases where contains(positive, alias) {
                result.must.insert(tag); matched.append(normalized(alias))
            }
        }
        for concept in config.concepts where concept.aliases.contains(where: { contains(positive, $0) }) {
            matched += concept.aliases.map(normalized)
            result.must.formUnion(concept.must ?? [])
            result.should.formUnion(concept.should ?? [])
            result.forbidden.formUnion(concept.forbidden ?? [])
            result.imageTags.formUnion(concept.requiredImageTags ?? [])
            result.verifiedIDs.formUnion(concept.verifiedTweetIds ?? [])
            result.verifiedOnly = result.verifiedOnly || concept.verifiedOnly == true
            result.groups += concept.requiredLexicalGroups ?? []
            if concept.requireLexical == true, let group = concept.lexical, !group.isEmpty { result.groups.append(group) }
            result.terms += concept.lexical ?? []
        }
        // Unrecognized literal words remain constraints, rather than disappearing into a guessed aesthetic.
        var remainder = positive
        for alias in matched.sorted(by: { $0.count > $1.count }) { remainder = remainder.replacingOccurrences(of: alias, with: " ") }
        for word in config.chineseStopwords { remainder = remainder.replacingOccurrences(of: word, with: " ") }
        let words = remainder.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 && !config.englishStopwords.contains($0) }
        result.groups += words.map { [$0] }
        result.terms = Array(Set(result.terms + matched + words)).sorted()
        return result
    }
}

actor OIPArchive {
    static let shared = OIPArchive()
    private var config: OIPIntentConfig?
    private var taxonomy: OIPTaxonomy?
    private var database: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    deinit { sqlite3_close(database) }

    private func open() throws {
        if database != nil { return }
        struct Provenance: Decodable { let archiveSHA256: String }
        // This file is generated by our importer, with its original camel-case keys.
        let provenance = try JSONDecoder().decode(Provenance.self, from: Data(contentsOf: OIPResources.url("Provenance", "json")))
        let path = OIPResources.directory.appending(path: "archive-\(provenance.archiveSHA256).sqlite")
        if !FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
            let packed = try Data(contentsOf: OIPResources.url("Archive", "oip"))
            guard SHA256.hash(data: packed).map({ String(format: "%02x", $0) }).joined() == provenance.archiveSHA256 else { throw CocoaError(.fileReadCorruptFile) }
            let unpacked = try (packed as NSData).decompressed(using: .lzfse)
            try unpacked.write(to: path, options: .atomic)
        }
        guard sqlite3_open_v2(path.path, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
            sqlite3_close(database); database = nil
            throw CocoaError(.fileReadCorruptFile)
        }
        sqlite3_create_function_v2(database, "oip_contains", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nil, { context, _, arguments in
            guard let arguments, let first = sqlite3_value_text(arguments[0]), let second = sqlite3_value_text(arguments[1]) else { sqlite3_result_int(context, 0); return }
            let text = String(decoding: UnsafeBufferPointer(start: first, count: Int(sqlite3_value_bytes(arguments[0]))), as: UTF8.self)
            let term = String(cString: second)
            sqlite3_result_int(context, OIPIntent.contains(text, term) ? 1 : 0)
        }, nil, nil, nil)
        config = try OIPResources.decode(OIPIntentConfig.self, "Intent")
        taxonomy = try OIPResources.decode(OIPTaxonomy.self, "Taxonomy")
        guard try rows("SELECT value FROM metadata WHERE key='taxonomy'").first?["value"] == "oip-visual-v2" else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    private func rows(_ sql: String, _ values: [String] = []) throws -> [[String: String]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { throw CocoaError(.fileReadCorruptFile) }
        defer { sqlite3_finalize(statement) }
        for (index, value) in values.enumerated() { sqlite3_bind_text(statement, Int32(index + 1), value, -1, transient) }
        var result: [[String: String]] = []
        while true {
            let state = sqlite3_step(statement)
            if state == SQLITE_DONE { break }
            guard state == SQLITE_ROW else { throw CocoaError(.fileReadCorruptFile) }
            var row: [String: String] = [:]
            for i in 0..<sqlite3_column_count(statement) {
                let key = String(cString: sqlite3_column_name(statement, i))
                row[key] = sqlite3_column_text(statement, i).map { String(decoding: UnsafeBufferPointer(start: $0, count: Int(sqlite3_column_bytes(statement, i))), as: UTF8.self) } ?? ""
            }
            result.append(row)
        }
        return result
    }

    func statistics() throws -> (prompts: Int, images: Int, version: String) {
        try open()
        return (Int(try rows("SELECT COUNT(*) AS n FROM records").first?["n"] ?? "") ?? 0,
                Int(try rows("SELECT COUNT(*) AS n FROM images").first?["n"] ?? "") ?? 0,
                try rows("SELECT value FROM metadata WHERE key='version'").first?["value"] ?? "")
    }

    func records(ids: [String]) throws -> [OIPRecord] {
        try open()
        return try ids.compactMap { id in
            guard let row = try rows("SELECT * FROM records WHERE id=?", [id]).first else { return nil }
            return try record(row)
        }
    }

    private func record(_ input: [String: String]) throws -> OIPRecord {
        let id = input["id"] ?? ""
        let row = input["original"] == nil ? try rows("SELECT * FROM records WHERE id=?", [id]).first ?? input : input
        let images = try rows("SELECT * FROM images WHERE record_id=? ORDER BY id", [id]).map {
            OIPImage(id: $0["id"] ?? "", recordID: id, url: $0["url"] ?? "", path: $0["path"] ?? "")
        }
        return OIPRecord(id: id, author: row["author"] ?? "", tool: row["tool"] ?? "", source: row["source"] ?? "",
                         original: row["original"] ?? "", zh: row["zh"] ?? "", en: row["en"] ?? "", images: images,
                         tags: try rows("SELECT DISTINCT tag FROM tags WHERE record_id=? ORDER BY tag", [id]).compactMap { $0["tag"] })
    }

    func search(_ query: String, limit: Int = 24) throws -> OIPSearchResults {
        try open()
        guard let config, let taxonomy else { throw CocoaError(.fileReadCorruptFile) }
        let intent = OIPIntent.parse(query, config: config, taxonomy: taxonomy)
        var result = OIPSearchResults(constraints: intent.must.sorted().map { taxonomy.displayNames[$0] ?? $0 })
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return result }
        let exact = try candidates(intent: intent)
        result.total = exact.count
        result.exact = try exact.prefix(limit).map { row in
            var item = try record(row)
            item.reasons = result.constraints + intent.groups.map { "关键词：" + $0.joined(separator: " / ") }
            return item
        }
        // A related result may omit one aesthetic dimension only, never subject, use, scene, or an avoid rule.
        let aesthetic = ["visual_style:", "lighting:", "color_palette:", "mood:", "composition:"]
        let exactIDs = Set(result.exact.map(\.id))
        var seen = exactIDs
        for missing in intent.must.sorted() where aesthetic.contains(where: { missing.hasPrefix($0) }) {
            if result.related.count >= 8 { break }
            var relatedIntent = intent
            relatedIntent.must.remove(missing)
            relatedIntent.forbidden.insert(missing)
            relatedIntent.forbidden.formUnion(["quality_flags:screenshot-ui", "quality_flags:multi-panel-layout", "quality_flags:logo-watermark", "quality_flags:typography-heavy", "quality_flags:embedded-text"].filter { !intent.must.contains($0) })
            let candidates = try candidates(intent: relatedIntent, imageEvidence: true)
            for row in candidates.prefix(16) where !seen.contains(row["id"] ?? "") {
                var item = try record(row)
                item.missing = [taxonomy.displayNames[missing] ?? missing]
                item.reasons = result.constraints.filter { !item.missing.contains($0) }
                result.related.append(item); seen.insert(item.id)
                if result.related.count >= 8 { break }
            }
        }
        return result
    }

    private func candidates(intent: OIPIntent, imageEvidence: Bool = false) throws -> [[String: String]] {
        var clauses = ["EXISTS(SELECT 1 FROM images WHERE record_id=r.id)"]
        var values: [String] = []
        for tag in intent.must.sorted() {
            clauses.append("EXISTS(SELECT 1 FROM tags WHERE record_id=r.id AND tag=?\(imageEvidence ? " AND image=1" : ""))")
            values.append(tag)
        }
        for tag in intent.forbidden.sorted() {
            clauses.append("NOT EXISTS(SELECT 1 FROM tags WHERE record_id=r.id AND tag=?)"); values.append(tag)
        }
        for tag in intent.imageTags.sorted() {
            clauses.append("EXISTS(SELECT 1 FROM tags WHERE record_id=r.id AND tag=? AND image=1)"); values.append(tag)
        }
        if intent.verifiedOnly {
            guard !intent.verifiedIDs.isEmpty else { return [] }
            clauses.append("r.id IN (" + intent.verifiedIDs.map { _ in "?" }.joined(separator: ",") + ")")
            values += intent.verifiedIDs.sorted()
        }
        for group in intent.groups where !group.isEmpty {
            clauses.append("(" + group.map { _ in "CASE WHEN instr(r.search_text, ?)>0 THEN oip_contains(r.search_text, ?) ELSE 0 END = 1" }.joined(separator: " OR ") + ")")
            values += group.flatMap { [OIPIntent.normalized($0), OIPIntent.normalized($0)] }
        }
        try Task.checkCancellation()
        var scores = ["0.0"]
        for tag in intent.should.sorted() {
            scores.append("COALESCE((SELECT MAX(confidence) FROM tags WHERE record_id=r.id AND tag=?),0) * 6")
            values.append(tag)
        }
        return try rows("SELECT r.id FROM records r WHERE " + clauses.joined(separator: " AND ") + " ORDER BY (" + scores.joined(separator: " + ") + ") DESC, r.id DESC", values)
    }
}
