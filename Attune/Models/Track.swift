import Foundation

struct Track: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    var rating: Int
    var tags: Set<Tag>

    var tagDelimiter = ", "
    var comment: String {
        tags.filter { $0.category == .comment}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }
    var grouping: String {
        tags.filter { $0.category == .grouping}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }
    var genre: String {
        tags.filter { $0.category == .genre}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }
    var bpm: Int { rating }
    var starRating: Int { rating * 20 }

    mutating func add(tags: [Tag]) {
        self.tags.formUnion(tags)
    }

    mutating func remove(tags: [Tag]) {
        self.tags.subtract(tags)
    }

    mutating func rate(_ rating: Int) {
        self.rating = rating
    }

    mutating func add(tagNames: [String]) {
        for name in tagNames {
            guard let category = TagLibrary.shared.category(for: name) else { break }
            let tag = Tag(name: name, category: category)
            tags.insert(tag)
        }
    }

    mutating func remove(tagNames: [String]) {
        let toRemove = tagNames.map { $0.lowercased() }
        tags = tags.filter { !toRemove.contains($0.normalizedName) }
    }

    mutating func setRating(_ newRating: Int) {
        self.rating = max(Track.minRating, min(Track.maxRating, newRating))
    }

    static let minRating: Int = 0
    static let maxRating: Int = 5
    static let ratingRange: ClosedRange<Int> = Track.minRating...Track.maxRating
}

extension Track {
    init(id: String, title: String, artist: String, rating: Int, comment: String, grouping: String, genre: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.rating = rating / 20
        self.tags = []

        // Parse existing metadata into Tags
        self.tags.formUnion(Track.parseTags(from: comment, category: .comment))
        self.tags.formUnion(Track.parseTags(from: grouping, category: .grouping))
        self.tags.formUnion(Track.parseTags(from: genre, category: .genre))
    }

    private static func parseTags(from string: String, category: TagCategory) -> Set<Tag> {
        let names = string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Set(names.map { Tag(name: $0, category: category) })
    }
}
