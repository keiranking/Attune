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

    private let storage: Storable
    private let storageKey = "Attune.Whitelist.tags"

    init(storage: Storable = UserDefaults.standard) {
        self.storage = storage
        load()
    }

    func replace(with tags: [Tag]) {
        self.tags = tags
            .filter { !Whitelist.blacklist.contains($0.normalizedName) }
            .uniqued(on: { $0.normalizedName })
            .sorted()
    }

    func category(for tagName: String) -> Tag.Category? {
        let normalized = tagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return tags.first { $0.normalizedName == normalized }?.category
    }

    static var blacklist: [String] = Track.ratingRange.map { "\($0)" }

    private func save() {
        if let encoded = try? JSONEncoder().encode(tags) {
            storage.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        if let data = storage.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Tag].self, from: data) {
            self.tags = decoded.sorted { $0.name < $1.name }
        } else {
            self.tags = []
        }
    }
}
