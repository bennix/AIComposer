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
        case .selection: return document != nil && selection?.isEmpty == false
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
        let combined = AIImagePipeline.combinedPrompt(
            kind: kind,
            extra: prompt,
            hasSelection: editSelection(for: kind)?.isEmpty == false
        )
        if kind.requiresPrompt && combined.isEmpty {
            importError = AIImageError.emptyPrompt.localizedDescription
            return
        }
        if kind.needsSelection, selection?.isEmpty != false {
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
        let work = try AIImagePipeline.workImage(canvas: raster.image, selection: editSelection(for: kind))
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

    /// The pixel layer the edit should write back to — never a new "AI Fill" layer.
    func aiTargetLayer() -> ImageLayer? {
        if let layer = activeLayer, !layer.isGroup, layer.asset != nil, layer.adjustment == nil {
            return layer
        }
        return document?.layers.reversed().first {
            !$0.isGroup && $0.isVisible && $0.asset != nil && $0.adjustment == nil
        }
    }

    func commitAIEdit(
        generated: CGImage,
        work: AIWorkImage,
        kind: AISheetKind,
        selection: DocumentSelection?
    ) throws {
        let hasSelection = selection.map { !$0.isEmpty } == true
        if hasSelection, kind.upscaleFactor <= 1, let selection {
            let coverage: CGImage
            if let local = work.coverage {
                coverage = local
            } else {
                let full = try selection.coverage(width: Int(work.canvasSize.width), height: Int(work.canvasSize.height))
                coverage = try AIImagePipeline.crop(
                    full,
                    to: CGRect(origin: work.origin, size: CGSize(width: work.image.width, height: work.image.height))
                )
            }
            let seam = try AIImagePipeline.compositeCoverage(from: coverage, selection: work.selectionInWork)
            let composited = try AIImagePipeline.compositeIntoOriginal(work.image, generated: generated, coverage: seam)
            try writeComposited(composited, work: work, selection: selection, actionName: kind.layerName)
            return
        }
        if let target = aiTargetLayer(),
           let index = document?.layers.firstIndex(where: { $0.id == target.id }) {
            let asset = try AIImagePipeline.asset(from: generated, name: target.name)
            var transform = target.transform
            if kind.upscaleFactor > 1 { transform.size = target.transform.size }
            beginEdit(kind.layerName)
            document?.layers[index] = ImageLayer(
                id: target.id, asset: asset, name: target.name,
                isVisible: target.isVisible, transform: transform,
                parentID: target.parentID, isGroup: false,
                opacity: target.opacity, blendMode: target.blendMode,
                mask: target.mask, maskSourceID: target.maskSourceID,
                adjustment: target.adjustment, shape: target.shape
            )
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
        guard let target = aiTargetLayer(),
              let index = document?.layers.firstIndex(where: { $0.id == target.id }),
              let original = target.asset?.image else {
            insertGenerated(try AIImagePipeline.asset(from: composited, name: actionName), origin: work.origin)
            return
        }
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
                painted = placed
            }
        }
        replaceLayerPixels(at: index, target: target, image: painted, actionName: actionName)
    }

    private func replaceLayerPixels(at index: Int, target: ImageLayer, image: CGImage, actionName: String) {
        let asset = (try? AIImagePipeline.asset(from: image, name: target.name))
            ?? ImportedImage(image: image, thumbnail: image, name: target.name)
        beginEdit(actionName)
        document?.layers[index] = ImageLayer(
            id: target.id, asset: asset, name: target.name,
            isVisible: target.isVisible, transform: target.transform,
            parentID: target.parentID, isGroup: false,
            opacity: target.opacity, blendMode: target.blendMode,
            mask: target.mask, maskSourceID: target.maskSourceID,
            adjustment: target.adjustment, shape: target.shape
        )
        endEdit()
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
