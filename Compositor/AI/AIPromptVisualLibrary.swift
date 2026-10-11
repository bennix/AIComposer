import Foundation
import CryptoKit

nonisolated struct AIVisualRecipe: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let facets: [AIPromptFacet]
}

nonisolated struct AIPromptVisualLibrary: Codable, Sendable {
    let source: String
    let reviewedAt: String
    let method: String
    let scope: String
    let thumbnailDigest: String
    let recipes: [AIVisualRecipe]
    let assignments: [String: String]

    func recipe(for reference: AIPromptReference) -> AIVisualRecipe? {
        guard let id = assignments[reference.id] else { return nil }
        return recipes.first { $0.id == id }
    }

    func facets(for reference: AIPromptReference) -> [AIPromptFacet] {
        reference.suggestions.isEmpty ? recipe(for: reference)?.facets ?? [] : reference.suggestions
    }

    static func decode(_ data: Data, gallery: AIPromptGallery) throws -> Self {
        let library = try JSONDecoder().decode(Self.self, from: data)
        let ids = Set(library.recipes.map(\.id))
        let snapshot = gallery.entries.sorted { $0.id < $1.id }
            .map { $0.id + "\t" + $0.thumbnail + "\n" }.joined()
        let digest = SHA256.hash(data: Data(snapshot.utf8)).map { String(format: "%02x", $0) }.joined()
        guard library.method == "public-thumbnail-visual-review",
              library.source == gallery.source,
              library.thumbnailDigest == digest,
              ids.count == library.recipes.count, !ids.isEmpty,
              Set(library.assignments.keys) == Set(gallery.entries.map(\.id)),
              Set(library.assignments.values).isSubset(of: ids),
              library.recipes.allSatisfy({ recipe in
                  !recipe.title.isEmpty && !recipe.summary.isEmpty && !recipe.facets.isEmpty &&
                  Set(recipe.facets.map(\.id)).count == recipe.facets.count &&
                  Set(recipe.facets.map(\.dimension)).count == recipe.facets.count &&
                  recipe.facets.allSatisfy { !$0.instruction.isEmpty && !$0.instruction.contains("[subject]") }
              }) else { throw CocoaError(.fileReadCorruptFile) }
        return library
    }

    static func load(gallery: AIPromptGallery) throws -> Self {
        guard let url = Bundle.main.url(forResource: "OpenNanaVisualRecipes", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url), gallery: gallery)
    }
}
