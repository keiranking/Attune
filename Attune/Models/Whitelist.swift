import Foundation
import Algorithms

@Observable
final class Whitelist {
    static let shared = Whitelist()

    private(set) var tags: [Tag] = [] {
        didSet { save() }
    }

    var genreTags: [Tag] { tags.filter { $0.category == .genre} }
    var commentTags: [Tag] { tags.filter { $0.category == .comment} }
    var groupingTags: [Tag] { tags.filter { $0.category == .grouping} }

    var suggestions: [String] { tags.map(\.normalizedName) }

    private let storageKey = "Attune.Whitelist.tags"

    init() {
        load()
    }

    // MARK: - CRUD

    func replace(with tags: [Tag]) {
        self.tags = tags
            .filter { !Whitelist.blacklist.contains($0.normalizedName) }
            .uniqued(on: { $0.normalizedName })
            .sorted()
    }

    // MARK: - Helpers

    func category(for tagName: String) -> Tag.Category? {
        let normalized = tagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return tags.first { $0.normalizedName == normalized }?.category
    }

    static func tags(from csv: String, as category: Tag.Category) -> [Tag] {
        csv
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .uniqued(on: { $0.lowercased() })
            .sorted()
            .map { Tag(name: String($0), category: category) }

    }

    static var blacklist: [String] = Track.ratingRange.map { "\($0)" }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Tag].self, from: data) {
            self.tags = decoded.sorted { $0.name < $1.name }
        } else {
            self.tags = Tag.examples
        }
    }
}
