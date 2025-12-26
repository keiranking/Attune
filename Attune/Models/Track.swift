import Foundation

extension Track {
    typealias PersistentID = String
}

struct Track: Identifiable, Codable, Hashable {
    let id: PersistentID
    let title: String
    let artist: String
    let album: String
    let year: Int
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

    mutating func add(tags: [Tag]) {
        self.tags.formUnion(tags)
    }

    mutating func remove(tags: [Tag]) {
        self.tags.subtract(tags)
    }

    mutating func rate(_ rating: Int) {
        self.rating = rating
    }

    mutating func add(tokens: [String]) {
        for token in tokens {
            let category = Whitelist.shared.category(for: token) ?? .comment
            let tag = Tag(name: token, category: category)
            tags.insert(tag)
        }
    }

    mutating func remove(tokens: [String]) {
        let unwantedTokens = tokens.map { $0.lowercased() }
        tags = tags.filter { !unwantedTokens.contains($0.normalizedName) }
    }

    static let minRating: Int = 0
    static let maxRating: Int = 5
    static let ratingRange: ClosedRange<Int> = Track.minRating...Track.maxRating
}

extension Track: Equatable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
        && lhs.rating == rhs.rating
        && lhs.tags == rhs.tags
    }
}

extension Track {
    init(
        id: PersistentID,
        title: String,
        artist: String,
        album: String,
        year: Int,
        rating: Int,
        comment: String,
        grouping: String,
        genre: String
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.rating = rating / 20
        self.tags = []

        self.tags.formUnion(Track.parseTags(from: comment, category: .comment))
        self.tags.formUnion(Track.parseTags(from: grouping, category: .grouping))
        self.tags.formUnion(Track.parseTags(from: genre, category: .genre))
    }

    private static func parseTags(from string: String, category: Tag.Category) -> Set<Tag> {
        let names = string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Set(names.map { Tag(name: $0, category: category) })
    }
}

extension Track {
    init?(musicTrack: MusicTrack) {
        guard
            let id = musicTrack.persistentID,
            let title = musicTrack.name,
            let artist = musicTrack.artist
        else {
            return nil
        }

        let album = musicTrack.album ?? ""
        let year = musicTrack.year

        let starRating = musicTrack.rating / 20

        let comment = musicTrack.comment ?? ""
        let grouping = musicTrack.grouping ?? ""
        let genre = musicTrack.genre ?? ""

        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.rating = starRating
        self.tags = []

        self.tags.formUnion(Track.parseTags(from: comment, category: .comment))
        self.tags.formUnion(Track.parseTags(from: grouping, category: .grouping))
        self.tags.formUnion(Track.parseTags(from: genre, category: .genre))
    }
}

extension Track {
    static let example = Track(
        id: "EC31D92EF18EB40Z",
        title: "Sleep Well, Little Children",
        artist: "Juan Modelo",
        album: "An Exemplary Christmas",
        year: 2007,
        rating: 3,
        tags: Set(Tag.examples.randomElements(5))
    )
}
