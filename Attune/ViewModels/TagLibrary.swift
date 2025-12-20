import Foundation
import Combine
import SwiftUI

@Observable
final class TagLibrary {
    static let shared = TagLibrary()

    var tags: [Tag] = [] {
        didSet { save() }
    }

    // MARK: Helpers

    var genreTags: [Tag] { tags.filter { $0.category == .genre} }
    var commentTags: [Tag] { tags.filter { $0.category == .comment} }
    var groupingTags: [Tag] { tags.filter { $0.category == .grouping} }

    private let storageKey = "AttuneTagLibrary"

    init() {
        load()
    }

    // MARK: - CRUD

    func addTag(name: String, category: TagCategory) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !exists(name: name) else { return }
        let newTag = Tag(name: name, category: category)
        tags.append(newTag)
    }

    func deleteTags(at offsets: IndexSet, in category: TagCategory? = nil) {
        if let category = category {
            let categoryTags = tags.enumerated().filter { $0.element.category == category }
            let indicesToDelete = offsets.map { categoryTags[$0].offset }
            tags.remove(atOffsets: IndexSet(indicesToDelete))
        } else {
            tags.remove(atOffsets: offsets)
        }
    }

    func exists(name: String) -> Bool {
        tags.contains { $0.normalizedName == name.trimmingCharacters(in: .whitespaces).lowercased() }
    }

    // MARK: - Helpers

    func category(for tagName: String) -> TagCategory? {
        let normalized = tagName.trimmingCharacters(in: .whitespaces).lowercased()

        if getWhitelist(for: .genre).contains(normalized) { return .genre }
        if getWhitelist(for: .grouping).contains(normalized) { return .grouping }
        if getWhitelist(for: .comment).contains(normalized) { return .comment }

        return nil
    }

    func getWhitelist(for category: TagCategory) -> Set<String> {
        let filtered = tags.filter { $0.category == category }
        return Set(filtered.map { $0.normalizedName })
    }

    static func makeTags(from csv: String, in category: TagCategory) -> [Tag] {
        csv
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { Tag(name: String($0), category: category) }

    }

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
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let defaultComments = [
            "action", "advice", "ballad", "celebration", "clip", "ethnic", "exmas",
            "family", "forgiveness", "friendship", "grand", "heroic", "island", "light",
            "lively", "longing", "lust", "new", "nostalgic", "old", "promise", "rare",
            "regret", "religious", "revenge", "romantic", "running", "sad", "secular",
            "seduction", "self", "sexy", "sinister", "slow", "society", "traditional",
            "theme"
        ]
        let defaultGroupings = [
            "boy", "girl", "vocal", "group", "choir", "acapella", "brass", "chant",
            "guitar", "organ", "pan", "piano", "perc", "strings", "synth", "wind",
            "whistle", "solo", "band", "orchestra"
        ]
        let defaultGenres = [
            "Alternative", "Broadway", "Blues", "Christmas", "Classical", "Country",
            "Electronica", "Folk", "Jazz", "Karaoke", "Latin", "OST", "Personal", "Pop",
            "R&B", "Rap", "Reggae", "Rock", "Soca", "Soul", "Standards"
        ]

        var newTags: [Tag] = []
        newTags.append(contentsOf: defaultComments.map { Tag(name: $0, category: .comment) })
        newTags.append(contentsOf: defaultGroupings.map { Tag(name: $0, category: .grouping) })
        newTags.append(contentsOf: defaultGenres.map { Tag(name: $0, category: .genre) })

        self.tags = newTags.sorted { $0.name < $1.name }
    }
}
