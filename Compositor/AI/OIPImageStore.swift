import Foundation

/// All archive image reads are local. No source-URL fallback or first-run download.
@MainActor final class OIPImageStore {
    static let shared = OIPImageStore()

    nonisolated static func safePath(_ path: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        return path.hasPrefix("images/") && !parts.contains("..") && !parts.contains(".") && !path.contains("\\") && !path.hasPrefix("/")
    }
    func localURL(_ image: OIPImage) -> URL? {
        guard Self.safePath(image.path),
              let root = Bundle.main.url(forResource: "OpenImagePromptsImages", withExtension: "bundle") else { return nil }
        let url = root.appending(path: image.path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    func data(for image: OIPImage) async throws -> Data {
        guard let url = localURL(image) else { throw CocoaError(.fileNoSuchFile) }
        return try await Task.detached { try Data(contentsOf: url) }.value
    }
}
