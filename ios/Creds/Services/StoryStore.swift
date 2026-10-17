import UIKit

/// One photo on the user's profile story.
struct StoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let habitId: String
    let habitName: String
    let ic: String
    let caption: String?
    let time: String
    let place: String
    let file: String
    let createdAt: Date
}

enum StoryError: LocalizedError {
    case encodeFailed
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodeFailed: return "The photo couldn’t be prepared for saving"
        case .writeFailed(let why): return "It couldn’t be written to this device’s storage (\(why))"
        }
    }
}

/// Saves story photos as JPEGs plus a small JSON index in Application Support.
@MainActor
final class StoryStore {
    private let dir: URL
    private var indexURL: URL { dir.appendingPathComponent("index.json") }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("Stories", isDirectory: true)
    }

    func load() -> [StoryItem] {
        guard let data = try? Data(contentsOf: indexURL),
              let items = try? JSONDecoder().decode([StoryItem].self, from: data) else { return [] }
        return items.filter { FileManager.default.fileExists(atPath: dir.appendingPathComponent($0.file).path) }
    }

    /// Writes the photo, then the updated index. Either both land or nothing is kept.
    func add(_ image: UIImage, habit: Habit, caption: String?, time: String, place: String, to items: [StoryItem]) throws -> StoryItem {
        guard let data = Self.downscaled(image).jpegData(compressionQuality: 0.85) else { throw StoryError.encodeFailed }
        let id = UUID()
        let item = StoryItem(id: id, habitId: habit.id, habitName: habit.name, ic: habit.ic, caption: caption, time: time, place: place,
                             file: id.uuidString + ".jpg", createdAt: Date())
        let photoURL = dir.appendingPathComponent(item.file)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: photoURL, options: [.atomic, .completeFileProtection])
            try writeIndex(items + [item])
        } catch {
            try? FileManager.default.removeItem(at: photoURL)
            throw StoryError.writeFailed(error.localizedDescription)
        }
        return item
    }

    func remove(_ item: StoryItem, from items: [StoryItem]) {
        try? writeIndex(items.filter { $0.id != item.id })
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(item.file))
    }

    func removeAll() { try? FileManager.default.removeItem(at: dir) }

    func image(_ item: StoryItem) -> UIImage? { UIImage(contentsOfFile: dir.appendingPathComponent(item.file).path) }

    private func writeIndex(_ items: [StoryItem]) throws {
        try JSONEncoder().encode(items).write(to: indexURL, options: .atomic)
    }

    static func downscaled(_ image: UIImage, maxSide: CGFloat = 1600) -> UIImage {
        let s = max(image.size.width, image.size.height)
        guard s > maxSide else { return image }
        let k = maxSide / s
        let size = CGSize(width: image.size.width * k, height: image.size.height * k)
        return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
