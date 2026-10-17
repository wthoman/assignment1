import UIKit

/// Saves the user's profile picture as a single JPEG in Application Support.
@MainActor
final class ProfilePhotoStore {
    private let url: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        url = base.appendingPathComponent("profile.jpg")
    }

    func load() -> UIImage? { UIImage(contentsOfFile: url.path) }

    /// Returns the image as it was saved (downscaled), so what's shown matches what's on disk.
    func save(_ image: UIImage) throws -> UIImage {
        let small = StoryStore.downscaled(image, maxSide: 800)
        guard let data = small.jpegData(compressionQuality: 0.85) else { throw StoryError.encodeFailed }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw StoryError.writeFailed(error.localizedDescription)
        }
        return small
    }

    func remove() { try? FileManager.default.removeItem(at: url) }
}
