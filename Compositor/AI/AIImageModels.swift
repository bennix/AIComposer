import Foundation

nonisolated enum AIImageModel: String, CaseIterable, Identifiable, Codable, Sendable {
    case gptImage = "openai/gpt-image-2.5-sunburst"
    case qwen = "qwen/qwen-image-3.0-pro"
    case gemini = "google/gemini-3.1-flash-lite-image"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gptImage: L10n.t("GPT Image 2.5 Sunburst")
        case .qwen: L10n.t("Qwen Image 3.0 Pro")
        case .gemini: L10n.t("Gemini 3.1 Flash Lite Image")
        }
    }

    var subtitle: String {
        switch self {
        case .gptImage: L10n.t("OpenAI · detailed edits")
        case .qwen: L10n.t("Qwen · text and layout")
        case .gemini: L10n.t("Google Vertex · fast drafts")
        }
    }

    var usesVertex: Bool { self == .gemini }

    static func resolved(_ raw: String) -> AIImageModel {
        AIImageModel(rawValue: raw) ?? .gptImage
    }
}

nonisolated enum AIImageSize: String, CaseIterable, Identifiable, Sendable {
    case square = "1024x1024"
    case landscape = "1536x1024"
    case portrait = "1024x1536"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .square: "1024 × 1024"
        case .landscape: "1536 × 1024"
        case .portrait: "1024 × 1536"
        }
    }

    var aspectRatio: String {
        switch self {
        case .square: "1:1"
        case .landscape: "3:2"
        case .portrait: "2:3"
        }
    }

    static func matching(width: Int, height: Int) -> AIImageSize {
        let aspect = CGFloat(max(width, 1)) / CGFloat(max(height, 1))
        if aspect > 1.2 { return .landscape }
        if aspect < 0.83 { return .portrait }
        return .square
    }
}

nonisolated enum AIMenuGroup: String, CaseIterable, Sendable {
    case generate = "Generate"
    case transform = "Transform"
    case edit = "Edit"
    case canvas = "Canvas"
}

nonisolated enum AIInputMode: Sendable {
    case none, canvas, selection, canvasOrSelection, expand
}

nonisolated enum AISheetKind: String, CaseIterable, Identifiable, Sendable {
    case generate, variation, pattern, poster
    case restyle, sketch, colorize, relight, enhance, cleanup, restore
    case fill, removeObject, handwriting, removeText
    case replaceBackground, replaceSky, weather, recolor, material, harmonize, shadow
    case expand

    var id: String { rawValue }

    var localizedGroup: String { L10n.t(group.rawValue) }

    var group: AIMenuGroup {
        switch self {
        case .generate, .variation, .pattern, .poster: .generate
        case .restyle, .sketch, .colorize, .relight, .enhance, .cleanup, .restore: .transform
        case .expand: .canvas
        default: .edit
        }
    }

    var input: AIInputMode {
        switch self {
        case .generate, .pattern, .poster: .none
        case .variation: .canvas
        case .fill, .removeObject: .selection
        case .expand: .expand
        default: .canvasOrSelection
        }
    }

    var title: String {
        switch self {
        case .generate: L10n.t("Generate Image")
        case .variation: L10n.t("Variation")
        case .pattern: L10n.t("Pattern / Texture")
        case .poster: L10n.t("Poster / Type")
        case .restyle: L10n.t("Restyle")
        case .sketch: L10n.t("Sketch to Image")
        case .colorize: L10n.t("Colorize")
        case .relight: L10n.t("Relight")
        case .enhance: L10n.t("Enhance / Upscale")
        case .cleanup: L10n.t("Cleanup")
        case .restore: L10n.t("Restore Photo")
        case .fill: L10n.t("Fill Selection")
        case .removeObject: L10n.t("Remove Object")
        case .handwriting: L10n.t("Remove Handwriting")
        case .removeText: L10n.t("Remove Text")
        case .replaceBackground: L10n.t("Replace Background")
        case .replaceSky: L10n.t("Replace Sky")
        case .weather: L10n.t("Weather / Time")
        case .recolor: L10n.t("Recolor")
        case .material: L10n.t("Change Material")
        case .harmonize: L10n.t("Harmonize")
        case .shadow: L10n.t("Contact Shadow")
        case .expand: L10n.t("Generative Expand")
        }
    }

    var layerName: String {
        switch self {
        case .generate: "AI Image"
        case .variation: "AI Variation"
        case .pattern: "AI Pattern"
        case .poster: "AI Poster"
        case .restyle: "AI Style"
        case .sketch: "AI Render"
        case .colorize: "AI Color"
        case .relight: "AI Light"
        case .enhance: "AI Enhance"
        case .cleanup: "AI Cleanup"
        case .restore: "AI Restore"
        case .fill: "AI Fill"
        case .removeObject: "AI Remove"
        case .handwriting: "AI Print"
        case .removeText: "AI Textless"
        case .replaceBackground: "AI Backdrop"
        case .replaceSky: "AI Sky"
        case .weather: "AI Weather"
        case .recolor: "AI Recolor"
        case .material: "AI Material"
        case .harmonize: "AI Harmonize"
        case .shadow: "AI Shadow"
        case .expand: "AI Expand"
        }
    }

    var placeholder: String {
        switch self {
        case .generate: L10n.t("A sunlit studio still life of citrus on linen, soft shadows, 50mm photograph")
        case .variation: L10n.t("Optional: lean warmer, wider, or more cinematic")
        case .pattern: L10n.t("Seamless terrazzo in cream and moss, 8K texture")
        case .poster: L10n.t("A concert poster, bold condensed type, two-color print")
        case .restyle: L10n.t("Oil painting, watercolor, editorial photo, anime…")
        case .sketch: L10n.t("Turn this sketch into a finished product photo")
        case .colorize: L10n.t("Optional: period-accurate 1970s film colors")
        case .relight: L10n.t("Soft window light, rim light, golden hour…")
        case .enhance: L10n.t("Optional: recover fine fabric and type")
        case .cleanup: L10n.t("Optional: keep grain, only remove dust")
        case .restore: L10n.t("Optional: heal tears, keep the original paper")
        case .fill: L10n.t("Optional: what should appear in the selection")
        case .removeObject: L10n.t("Optional: describe the object if the selection is loose")
        case .handwriting: L10n.t("Optional: keep stamps or page texture")
        case .removeText: L10n.t("Optional: keep logos or captions you still need")
        case .replaceBackground: L10n.t("Seamless white studio, cedar forest, marble lobby…")
        case .replaceSky: L10n.t("Clear dusk, storm, sunset with long clouds…")
        case .weather: L10n.t("Rain at night, snowfall, dense fog…")
        case .recolor: L10n.t("Matte sage green, cherry red lacquer…")
        case .material: L10n.t("Brushed aluminum, frosted glass, oak…")
        case .harmonize: L10n.t("Optional: match a cooler moonlight grade")
        case .shadow: L10n.t("Optional: longer late-afternoon shadow")
        case .expand: L10n.t("Optional: what the new borders should become")
        }
    }

    var help: String {
        switch self {
        case .generate: L10n.t("Creates a new layer from a text prompt. With no canvas open, the image becomes the document.")
        case .variation: L10n.t("Paints a new interpretation of the current canvas onto a new layer.")
        case .pattern: L10n.t("Generates a tile-friendly texture or pattern as a new layer.")
        case .poster: L10n.t("Builds a layout-heavy graphic with readable type, good for Qwen.")
        case .restyle: L10n.t("Keeps the composition and redraws it in another medium or look.")
        case .sketch: L10n.t("Turns line work or a rough block-in into a finished picture.")
        case .colorize: L10n.t("Adds plausible color to a black-and-white or faded image.")
        case .relight: L10n.t("Changes the lighting direction and quality without rebuilding the scene.")
        case .enhance: L10n.t("Returns a sharper, higher-resolution layer displayed at the original size.")
        case .cleanup: L10n.t("Removes dust, compression, and mild blur while keeping the photo honest.")
        case .restore: L10n.t("Repairs scratches, stains, and fading on archival photographs.")
        case .fill: L10n.t("Edits the current layer in place. Only the selected pixels change; nothing new is added to the Layers list.")
        case .removeObject: L10n.t("Erases whatever is inside the selection and rebuilds a matching background.")
        case .handwriting: L10n.t("Clears pen marks and signatures. Printed type and graphics are kept.")
        case .removeText: L10n.t("Removes captions, labels, and overlaid type. A selection limits the pass.")
        case .replaceBackground: L10n.t("Keeps the subject and builds a new environment behind it.")
        case .replaceSky: L10n.t("Replaces only the sky and the light it throws on the scene.")
        case .weather: L10n.t("Changes weather and time of day across the frame or the selection.")
        case .recolor: L10n.t("Shifts the color of the selected object while keeping material and shading.")
        case .material: L10n.t("Keeps the object's shape and assigns a new surface.")
        case .harmonize: L10n.t("Matches lighting and color so a composite looks like one photograph.")
        case .shadow: L10n.t("Adds a grounded contact shadow under the subject.")
        case .expand: L10n.t("Grows the canvas and paints the new borders so they continue the picture.")
        }
    }

    var defaultPrompt: String {
        switch self {
        case .generate, .pattern, .poster: ""
        case .variation: L10n.t("ai.prompt.variation")
        case .restyle: L10n.t("ai.prompt.restyle")
        case .sketch: L10n.t("ai.prompt.sketch")
        case .colorize: L10n.t("ai.prompt.colorize")
        case .relight: L10n.t("ai.prompt.relight")
        case .enhance: L10n.t("ai.prompt.enhance")
        case .cleanup: L10n.t("ai.prompt.cleanup")
        case .restore: L10n.t("ai.prompt.restore")
        case .fill: L10n.t("ai.prompt.fill")
        case .removeObject: L10n.t("ai.prompt.removeObject")
        case .handwriting: L10n.t("ai.prompt.handwriting")
        case .removeText: L10n.t("ai.prompt.removeText")
        case .replaceBackground: L10n.t("ai.prompt.replaceBackground")
        case .replaceSky: L10n.t("ai.prompt.replaceSky")
        case .weather: L10n.t("ai.prompt.weather")
        case .recolor: L10n.t("ai.prompt.recolor")
        case .material: L10n.t("ai.prompt.material")
        case .harmonize: L10n.t("ai.prompt.harmonize")
        case .shadow: L10n.t("ai.prompt.shadow")
        case .expand: L10n.t("ai.prompt.expand")
        }
    }

    var requiresPrompt: Bool {
        switch self {
        case .generate, .pattern, .poster, .restyle, .recolor, .weather, .material: true
        default: false
        }
    }

    var showsSizePicker: Bool {
        switch self {
        case .generate, .pattern, .poster: true
        default: false
        }
    }

    var upscaleFactor: CGFloat { self == .enhance ? 2 : 1 }

    var needsSelection: Bool { input == .selection }

    var presets: [String] {
        let keys: [String]
        switch self {
        case .restyle: keys = ["Oil painting", "Watercolor", "Editorial photo", "Anime still", "Risograph poster"]
        case .relight: keys = ["Soft window light", "Dramatic rim light", "Studio three-point", "Golden hour"]
        case .weather: keys = ["Golden hour", "Overcast", "Blue hour", "Rain at night", "Snow", "Fog"]
        case .sketch: keys = ["Photoreal product", "Matte illustration", "Architectural viz"]
        case .replaceBackground: keys = ["Seamless white studio", "Soft gray cyclorama", "Cedar forest", "Marble lobby"]
        case .replaceSky: keys = ["Clear dusk", "Storm", "Sunset streaks", "Night with stars"]
        default: return []
        }
        return keys.map(L10n.t)
    }

    static func inGroup(_ group: AIMenuGroup) -> [AISheetKind] {
        allCases.filter { $0.group == group }
    }
}

nonisolated enum AIImageError: LocalizedError {
    case noDocument
    case noSelection
    case emptyPrompt
    case noImageInResponse
    case http(Int, String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .noDocument: L10n.t("Open or create a canvas first.")
        case .noSelection: L10n.t("Draw a selection first, then run this command.")
        case .emptyPrompt: L10n.t("Enter a prompt describing what you want.")
        case .noImageInResponse: L10n.t("The model returned no image. Try another model or a shorter prompt.")
        case .http(_, let message): message
        case .transport(let message): message
        }
    }
}
