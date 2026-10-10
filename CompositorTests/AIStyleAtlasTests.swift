import Foundation
import Testing
@testable import Compositor

struct AIStyleAtlasTests {
    private var style: AIStyle {
        AIStyle(id: "baroque", name: ["en": "Baroque", "zh": "巴洛克"], summary: ["en": "Dramatic light"],
                domain: ["en": "Painting"], lineage: ["en": "Classical"], features: [:],
                prompt: "[subject], dramatic chiaroscuro", source: "https://vibeshot.club/lexicon")
    }

    @Test func composesSubjectWithoutLeakingTemplatePlaceholder() {
        let brief = AICreativeBrief(subject: "  a traveler  ", purpose: "Magazine cover", direction: "Cool shadows", style: style)
        #expect(brief.prompt == "a traveler, dramatic chiaroscuro\nMagazine cover\nCool shadows")
        #expect(AICreativeBrief(subject: "  ", style: style).prompt.isEmpty)
    }

    @Test func searchesAcrossLanguagesAndFiltersCategories() {
        #expect(style.matches("巴洛克", category: ""))
        #expect(style.matches("dramatic", category: style.category))
        #expect(!style.matches("Baroque", category: "Photography"))
    }

    @Test func rejectsDuplicateStylesAndIncompleteTemplates() throws {
        let atlas = AIStyleAtlas(source: "test", importedAt: "2026-10-10", total: 2, styles: [style, style])
        let data = try JSONEncoder().encode(atlas)
        #expect(throws: (any Error).self) { try AIStyleAtlas.decode(data) }
    }

    @Test func bundledPreviewIsCompleteAndAttributed() throws {
        let url = try #require(Bundle.main.url(forResource: "StyleAtlas", withExtension: "json"))
        let atlas = try AIStyleAtlas.decode(Data(contentsOf: url))
        #expect(atlas.styles.count == 30)
        #expect(atlas.total == 1617)
        #expect(atlas.styles.allSatisfy { $0.source.hasPrefix("https://vibeshot.club/lexicon/") })
    }
}
