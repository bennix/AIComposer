import Foundation
import CoreGraphics

extension EditorSession {
    var canOpenAIGenerate: Bool {
        !isProjectBusy && !isImporting && !isGeneratingAI && levels == nil && hueSaturation == nil && filterEdit == nil
    }

    func canOpen(_ kind: AISheetKind) -> Bool {
        guard canOpenAIGenerate else { return false }
        switch kind.input {
        case .none: return true
        case .canvas, .canvasOrSelection, .expand: return document != nil
        case .selection: return document != nil && (selection?.isEmpty == false || hasAIObjectTarget)
        }
    }

    var canOpenAIFill: Bool { canOpen(.fill) }
    var canOpenAIRemove: Bool { canOpen(.removeObject) }
    var canOpenAIHandwriting: Bool { canOpen(.handwriting) }
    var canOpenAIExpand: Bool { canOpen(.expand) }

    func openAI(_ kind: AISheetKind) {
        guard canOpen(kind) else {
            if kind.needsSelection { importError = AIImageError.noSelection.localizedDescription }
            return
        }
        commitTransform()
        cancelCrop()
        cancelLasso()
        aiSheet = kind
    }

    func insertGenerated(_ asset: ImportedImage, origin: CGPoint? = nil, atBottom: Bool = false,
                         displaySize: CGSize? = nil) {
        beginEdit(asset.name)
        defer { endEdit() }
        if document == nil {
            document = CanvasDocument(width: asset.image.width, height: asset.image.height)
            viewport.fit(documentSize: document!.size)
        }
        guard let document else { return }
        let layerWidth = displaySize?.width ?? CGFloat(asset.image.width)
        let layerHeight = displaySize?.height ?? CGFloat(asset.image.height)
        let placed = origin ?? CGPoint(
            x: floor((CGFloat(document.width) - layerWidth) / 2),
            y: floor((CGFloat(document.height) - layerHeight) / 2)
        )
        var layer = ImageLayer(asset: asset, origin: placed)
        if let displaySize { layer.transform.size = displaySize }
        layer.parentID = atBottom ? nil : (activeLayer?.isGroup == true ? activeLayerID : activeLayer?.parentID)
        if atBottom {
            self.document?.layers.insert(layer, at: 0)
        } else {
            if let parent = layer.parentID { collapsedGroupIDs.remove(parent) }
            self.document?.layers.append(layer)
        }
        activeLayerID = layer.id
    }

    func runAI(
        kind: AISheetKind,
        prompt: String,
        model: AIImageModel,
        size: AIImageSize,
        expand: (left: Int, right: Int, top: Int, bottom: Int) = (0, 0, 0, 0),
        settings: AISettingsController = .shared
    ) async {
        let credentials = settings.credentials.trimmed
        guard credentials.hasAPIKey else {
            importError = AICredentialError.missingKey.localizedDescription
            return
        }
        if kind.needsSelection, !hasAIEditRegion(for: kind) {
            importError = AIImageError.noSelection.localizedDescription
            return
        }
        if brushStroke != nil { await finishBrush() }
        commitTransform()
        cancelCrop()
        isGeneratingAI = true
        isProjectBusy = true
        defer {
            isGeneratingAI = false
            isProjectBusy = false
        }
        do {
            let client = AIImageClient()
            if kind == .recognizeText {
                try await runAIRecognizeText(extra: prompt, credentials: credentials, client: client)
                return
            }
            let combined = AIImagePipeline.combinedPrompt(
                kind: kind,
                extra: prompt,
                hasSelection: hasAIEditRegion(for: kind)
            )
            if kind.requiresPrompt && combined.isEmpty {
                importError = AIImageError.emptyPrompt.localizedDescription
                return
            }
            switch kind.input {
            case .none:
                let image = try await client.generate(AIImageRequest(
                    credentials: credentials, model: model, prompt: combined, size: size))
                let asset = try AIImagePipeline.asset(from: image.data, name: kind.layerName)
                aiSheet = nil
                insertGenerated(asset)
            case .expand:
                try await runAIExpand(prompt: combined, model: model, size: size, expand: expand,
                                      credentials: credentials, client: client)
            case .canvas, .selection, .canvasOrSelection:
                try await runAIEdit(kind: kind, prompt: combined, model: model, size: size,
                                    credentials: credentials, client: client)
            }
        } catch {
            importError = error.localizedDescription
        }
    }

    private func editSelection(for kind: AISheetKind) -> DocumentSelection? {
        switch kind.input {
        case .selection, .canvasOrSelection: selection
        default: nil
        }
    }

    /// Pixel marquee, or the painted pixels of one or more selected objects (including live text).
    var hasAIObjectTarget: Bool { !aiEditableLayers().isEmpty }

    func hasAIEditRegion(for kind: AISheetKind) -> Bool {
        switch kind.input {
        case .selection: selection?.isEmpty == false || hasAIObjectTarget
        case .canvasOrSelection: true
        default: false
        }
    }

    /// Selected pixel / text layers, expanding a selected folder to its painted descendants.
    func aiEditableLayers() -> [ImageLayer] {
        guard let document else { return [] }
        var ids = selectedLayerIDs
        for id in selectedLayerIDs { ids.formUnion(descendantIDs(of: id)) }
        let visible = document.effectiveVisibleIDs
        return document.renderLayers.filter {
            ids.contains($0.id) && visible.contains($0.id) && !$0.isGroup
                && $0.asset != nil && $0.adjustment == nil
        }
    }

    private func runAIEdit(
        kind: AISheetKind,
        prompt: String,
        model: AIImageModel,
        size: AIImageSize,
        credentials: AICredentials,
        client: AIImageClient
    ) async throws {
        guard let snapshot = projectSnapshot() else { throw AIImageError.noDocument }
        let raster = try await ImageExporter.shared.render(snapshot)
        let work = try aiWorkImage(canvas: raster.image, kind: kind)
        let sendImage = try AIImagePipeline.scaledForUpload(work.image)
        let sendMask = try work.mask.map { try AIImagePipeline.scaledForUpload($0) }
        let sendCoverage = try work.coverage.map {
            try AIImagePipeline.sendCoverage(from: $0, selection: work.selectionInWork)
        }
        let maskPNG = try sendMask.map { try AIImagePipeline.pngData(from: $0) }
        let coveragePNG = try sendCoverage.map {
            try AIImagePipeline.pngData(from: try AIImagePipeline.rgbMask(from: try AIImagePipeline.scaledForUpload($0)))
        }
        let matched = AIImageSize.matching(width: work.image.width, height: work.image.height)
        let result = try await client.generate(AIImageRequest(
            credentials: credentials,
            model: model,
            prompt: prompt,
            size: kind.showsSizePicker ? size : matched,
            imagePNG: AIImagePipeline.pngData(from: sendImage),
            maskPNG: maskPNG,
            coveragePNG: coveragePNG,
            selectionHint: AIImagePipeline.selectionHint(for: work)
        ))
        var image = try AIImagePipeline.image(from: result.data)
        let target = CGSize(
            width: CGFloat(work.image.width) * kind.upscaleFactor,
            height: CGFloat(work.image.height) * kind.upscaleFactor
        )
        image = try AIImagePipeline.placed(image, on: target)
        aiSheet = nil
        try commitAIEdit(generated: image, work: work, kind: kind, selection: editSelection(for: kind))
    }

    private func aiWorkImage(canvas: CGImage, kind: AISheetKind) throws -> AIWorkImage {
        if let selection = editSelection(for: kind), !selection.isEmpty {
            return try AIImagePipeline.workImage(canvas: canvas, selection: selection)
        }
        let objects = aiEditableLayers()
        if !objects.isEmpty, kind.input == .selection || kind.input == .canvasOrSelection {
            var coverage = try AIImagePipeline.coverage(
                of: objects,
                canvas: CGSize(width: canvas.width, height: canvas.height)
            )
            if kind.invertsObjectMask, let inverted = AIImagePipeline.invertCoverage(coverage) {
                coverage = inverted
            }
            return try AIImagePipeline.workImage(
                canvas: canvas,
                coverage: coverage,
                selection: AIImagePipeline.bounds(
                    of: objects,
                    canvas: CGSize(width: canvas.width, height: canvas.height)
                )
            )
        }
        return try AIImagePipeline.workImage(canvas: canvas, selection: nil)
    }

    /// The pixel layer the edit should write back to — never a new "AI Fill" layer.
    func aiTargetLayer() -> ImageLayer? { aiTargetLayers().first }

    func aiTargetLayers() -> [ImageLayer] {
        let objects = aiEditableLayers()
        if !objects.isEmpty { return objects }
        if let layer = activeLayer, !layer.isGroup, layer.asset != nil, layer.adjustment == nil {
            return [layer]
        }
        if let layer = document?.layers.reversed().first(where: {
            !$0.isGroup && $0.isVisible && $0.asset != nil && $0.adjustment == nil
        }) {
            return [layer]
        }
        return []
    }

    func commitAIEdit(
        generated: CGImage,
        work: AIWorkImage,
        kind: AISheetKind,
        selection: DocumentSelection?
    ) throws {
        let hasRegion = work.coverage != nil || selection.map { !$0.isEmpty } == true
        if hasRegion, kind.upscaleFactor <= 1 {
            let coverage: CGImage
            if let local = work.coverage {
                coverage = local
            } else if let selection, !selection.isEmpty {
                let full = try selection.coverage(width: Int(work.canvasSize.width), height: Int(work.canvasSize.height))
                coverage = try AIImagePipeline.crop(
                    full,
                    to: CGRect(origin: work.origin, size: CGSize(width: work.image.width, height: work.image.height))
                )
            } else {
                throw AIImageError.noSelection
            }
            let seam = try AIImagePipeline.compositeCoverage(from: coverage, selection: work.selectionInWork)
            let composited = try AIImagePipeline.compositeIntoOriginal(work.image, generated: generated, coverage: seam)
            try writeComposited(composited, work: work, selection: selection, actionName: kind.layerName)
            return
        }
        if let target = aiTargetLayers().first,
           let index = document?.layers.firstIndex(where: { $0.id == target.id }),
           aiTargetLayers().count == 1 {
            let asset = try AIImagePipeline.asset(from: generated, name: target.name)
            var transform = target.transform
            if kind.upscaleFactor > 1 { transform.size = target.transform.size }
            beginEdit(kind.layerName)
            writeLayerPixels(at: index, target: target, asset: asset, transform: transform)
            endEdit()
            return
        }
        let asset = try AIImagePipeline.asset(from: generated, name: kind.layerName)
        let display = kind.upscaleFactor > 1
            ? CGSize(width: work.image.width, height: work.image.height)
            : nil
        insertGenerated(asset, origin: work.origin, displaySize: display)
    }

    func applyAIPatch(_ patch: CGImage, work: AIWorkImage, actionName: String) throws {
        try writeComposited(patch, work: work, selection: nil, actionName: actionName)
    }

    private func writeComposited(
        _ composited: CGImage,
        work: AIWorkImage,
        selection: DocumentSelection?,
        actionName: String
    ) throws {
        let targets = aiTargetLayers()
        guard !targets.isEmpty else {
            insertGenerated(try AIImagePipeline.asset(from: composited, name: actionName), origin: work.origin)
            return
        }
        beginEdit(actionName)
        for target in targets {
            guard let index = document?.layers.firstIndex(where: { $0.id == target.id }),
                  let original = target.asset?.image else { continue }
            let painted: CGImage
            if AIImagePipeline.layerMatchesWork(target, work: work) {
                painted = composited
            } else {
                let placed = try AIImagePipeline.paint(
                    composited,
                    at: work.origin,
                    workSize: CGSize(width: work.image.width, height: work.image.height),
                    onto: original,
                    layerTransform: target.transform
                )
                if let selection, let document, !selection.isEmpty {
                    let mapping = BrushRaster.pixelToDocument(target.transform, width: original.width, height: original.height)
                    let clip = try selection.clip(canvas: document.size)
                    painted = try PixelAdjust.blend(placed, over: original, through: clip, pixelToDocument: mapping, isMask: false)
                } else {
                    let alpha = try AIImagePipeline.alphaCoverage(from: original)
                    painted = try AIImagePipeline.compositeIntoOriginal(original, generated: placed, coverage: alpha)
                }
            }
            let asset = (try? AIImagePipeline.asset(from: painted, name: target.name))
                ?? ImportedImage(image: painted, thumbnail: painted, name: target.name)
            writeLayerPixels(at: index, target: target, asset: asset, transform: target.transform)
        }
        endEdit()
    }

    private func replaceLayerPixels(at index: Int, target: ImageLayer, image: CGImage, actionName: String) {
        let asset = (try? AIImagePipeline.asset(from: image, name: target.name))
            ?? ImportedImage(image: image, thumbnail: image, name: target.name)
        beginEdit(actionName)
        writeLayerPixels(at: index, target: target, asset: asset, transform: target.transform)
        endEdit()
    }

    /// Writes pixels in place and drops live text: the raster no longer matches the source letters.
    private func writeLayerPixels(at index: Int, target: ImageLayer, asset: ImportedImage, transform: LayerTransform) {
        document?.layers[index] = ImageLayer(
            id: target.id, asset: asset, name: target.name,
            isVisible: target.isVisible, transform: transform,
            parentID: target.parentID, isGroup: false,
            opacity: target.opacity, blendMode: target.blendMode,
            mask: target.mask, maskSourceID: target.maskSourceID,
            adjustment: target.adjustment, shape: target.shape
        )
    }

    private func runAIRecognizeText(
        extra: String,
        credentials: AICredentials,
        client: AIImageClient
    ) async throws {
        if let selection, !selection.isEmpty, let snapshot = projectSnapshot() {
            let raster = try await ImageExporter.shared.render(snapshot)
            let work = try AIImagePipeline.workImage(canvas: raster.image, selection: selection)
            let style = try await recognizeStyle(
                from: work.image,
                box: CGSize(width: work.image.width, height: work.image.height),
                extra: extra,
                credentials: credentials,
                client: client
            )
            let image = try Self.textImage(style)
            aiSheet = nil
            addPixelLayer(
                image,
                at: work.origin,
                name: Self.layerName(for: style.content),
                editName: AISheetKind.recognizeText.layerName,
                text: LayerText(style: style, image: image)
            )
            editActiveText()
            return
        }
        let targets = aiEditableLayers().filter { $0.liveText == nil && $0.asset != nil }
        guard !targets.isEmpty else {
            if aiEditableLayers().contains(where: { $0.liveText != nil }) {
                throw AIImageError.transport(L10n.t("The selected type is already editable text."))
            }
            throw AIImageError.noSelection
        }
        var converted: [(ImageLayer, LayerTextStyle)] = []
        for target in targets {
            guard let image = target.asset?.image else { continue }
            let style = try await recognizeStyle(
                from: image,
                box: target.transform.size,
                extra: extra,
                credentials: credentials,
                client: client
            )
            converted.append((target, style))
        }
        guard !converted.isEmpty else { throw AIImageError.noTextInResponse }
        aiSheet = nil
        beginEdit(AISheetKind.recognizeText.layerName)
        for (layer, style) in converted {
            try writeLiveText(on: layer, style: style)
        }
        endEdit()
        if let first = converted.first {
            selectLayer(first.0.id)
            editActiveText()
        }
    }

    private func recognizeStyle(
        from image: CGImage,
        box: CGSize,
        extra: String,
        credentials: AICredentials,
        client: AIImageClient
    ) async throws -> LayerTextStyle {
        let send = try AIImagePipeline.scaledForUpload(image)
        let recognized = try await client.recognizeText(
            credentials: credentials,
            imagePNG: AIImagePipeline.pngData(from: send),
            extra: extra
        )
        return recognized.style(box: box, fallbackColor: AIRecognizedText.sampleOpaqueColor(from: image))
    }

    private func writeLiveText(on layer: ImageLayer, style: LayerTextStyle) throws {
        guard let index = document?.layers.firstIndex(where: { $0.id == layer.id }) else { return }
        let image = try Self.textImage(style)
        let thumbnail = try PixelInvert.thumbnail(of: image)
        document?.layers[index] = ImageLayer(
            id: layer.id,
            asset: ImportedImage(image: image, thumbnail: thumbnail, name: Self.layerName(for: style.content)),
            name: Self.layerName(for: style.content),
            isVisible: layer.isVisible,
            transform: layer.transform,
            parentID: layer.parentID,
            isGroup: false,
            opacity: layer.opacity,
            blendMode: layer.blendMode,
            mask: layer.mask,
            maskSourceID: layer.maskSourceID,
            adjustment: nil,
            shape: nil,
            effects: layer.effects,
            text: LayerText(style: style, image: image)
        )
    }

    private func runAIExpand(
        prompt: String,
        model: AIImageModel,
        size _: AIImageSize,
        expand: (left: Int, right: Int, top: Int, bottom: Int),
        credentials: AICredentials,
        client: AIImageClient
    ) async throws {
        guard document != nil, let snapshot = projectSnapshot() else { throw AIImageError.noDocument }
        let left = max(0, expand.left), right = max(0, expand.right)
        let top = max(0, expand.top), bottom = max(0, expand.bottom)
        guard left + right + top + bottom > 0 else {
            throw AIImageError.transport("Enter at least one side to expand.")
        }
        let raster = try await ImageExporter.shared.render(snapshot)
        let work = try AIImagePipeline.expand(canvas: raster.image, left: left, right: right, top: top, bottom: bottom)
        let sendImage = try AIImagePipeline.scaledForUpload(work.image)
        let sendMask = try work.mask.map { try AIImagePipeline.scaledForUpload($0) }
        let sendCoverage = try work.coverage.map { try AIImagePipeline.scaledForUpload($0) }
        let maskPNG = try sendMask.map { try AIImagePipeline.pngData(from: $0) }
        let coveragePNG = try sendCoverage.map {
            try AIImagePipeline.pngData(from: try AIImagePipeline.rgbMask(from: $0))
        }
        let matched = AIImageSize.matching(width: Int(work.canvasSize.width), height: Int(work.canvasSize.height))
        let result = try await client.generate(AIImageRequest(
            credentials: credentials,
            model: model,
            prompt: prompt,
            size: matched,
            imagePNG: AIImagePipeline.pngData(from: sendImage),
            maskPNG: maskPNG,
            coveragePNG: coveragePNG,
            selectionHint: L10n.t("ai.prompt.expandSeam")
        ))
        var image = try AIImagePipeline.image(from: result.data)
        image = try AIImagePipeline.placed(image, on: work.canvasSize)
        let original = CGRect(x: left, y: top, width: raster.image.width, height: raster.image.height)
        let overlap = AIImagePipeline.expandOverlap(
            original: CGSize(width: raster.image.width, height: raster.image.height),
            left: left, right: right, top: top, bottom: bottom
        )
        let border = try AIImagePipeline.expandBorder(from: image, original: original, overlap: overlap)
        let options = CanvasSizeOptions(
            width: Int(work.canvasSize.width),
            height: Int(work.canvasSize.height),
            anchor: 4,
            fill: nil,
            contentOffset: CGPoint(x: left, y: top)
        )
        let resized = try await CanvasResizer.shared.resize(snapshot, to: options)
        aiSheet = nil
        applyDocumentSize(resized, actionName: AISheetKind.expand.layerName)
        insertGenerated(try AIImagePipeline.asset(from: border, name: AISheetKind.expand.layerName),
                        origin: .zero)
    }
}
