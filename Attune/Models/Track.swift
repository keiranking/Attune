import Foundation

extension Track {
    typealias PersistentID = String
    typealias StarRating = Int
}

struct Track: Identifiable, Codable, Hashable {
    let id: PersistentID
    let title: String
    let artist: String
    let album: String
    let year: Int
    private(set) var rating: StarRating
    private(set) var tags: Set<Tag>

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
        self.rating = rating.clamped(to: Track.ratingRange)
    }

    mutating func add(tokens: [String]) {
        for token in tokens {
            let category = Whitelist.shared.category(for: token) ?? .comment
            guard let tag = Tag(token, category: category) else { return }
            tags.insert(tag)
        }
    }

    mutating func remove(tokens: [String]) {
        let unwantedTokens = tokens.map { $0.lowercased() }
        tags = tags.filter { !unwantedTokens.contains($0.normalizedName) }
    }

    init(
        id: PersistentID,
        title: String,
        artist: String,
        album: String,
        year: Int,
        rating: StarRating,
        tags: Set<Tag>
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year.clamped(to: Track.yearRange)
        self.rating = rating.clamped(to: Track.ratingRange)
        self.tags = tags
    }

    static let ratingRange: ClosedRange<Int> = 0...5
    static let yearRange: ClosedRange<Int> = 1900...Calendar.current.component(.year, from: Date())
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
        rating: StarRating,
        comment: String,
        grouping: String,
        genre: String
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year.clamped(to: Track.yearRange)
        self.rating = rating.clamped(to: Track.ratingRange)
        self.tags = []

        self.tags.formUnion(Tag.array(from: comment, as: .comment))
        self.tags.formUnion(Tag.array(from: grouping, as: .grouping))
        self.tags.formUnion(Tag.array(from: genre, as: .genre))
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

        let rating = (musicTrack.rating / 20).clamped(to: Track.ratingRange)

        let comment = musicTrack.comment ?? ""
        let grouping = musicTrack.grouping ?? ""
        let genre = musicTrack.genre ?? ""

        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.rating = rating
        self.tags = []

        self.tags.formUnion(Tag.array(from: comment, as: .comment))
        self.tags.formUnion(Tag.array(from: grouping, as: .grouping))
        self.tags.formUnion(Tag.array(from: genre, as: .genre))
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(self, range.upperBound))
    }
}
