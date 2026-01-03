// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@MainActor
private extension Track {
    static func mock(
        id: PersistentID = "mock-id",
        title: String = "",
        artist: String = "",
        album: String = "",
        year: Int = 0,
        rating: Int = 0,
        tags: [Attune.Tag] = []
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            year: year,
            rating: rating,
            tags: Set(tags)
        )
    }
}

@MainActor
@Suite("Track boundary and invalid values")
struct TrackBoundaryTests {

    @Test("Track initializes with empty tag strings")
    func emptyTagInputs() {
        let track = Track.mock()

        #expect(track.tags.isEmpty)
    }

    @Test("Invalid tag tokens are ignored when adding")
    func invalidTokensIgnored() {
        var track = Track.example
        track.add(tokens: ["", "   ", "\n"])

        #expect(track.tags == Track.example.tags)
    }

    @Test("Rating above bounds is clamped")
    func ratingAboveIsClamped() {
        var trackA = Track.example
        trackA.rate(10)

        let trackB = Track.mock(rating: 10)

        #expect(trackA.rating == 5)
        #expect(trackB.rating == 5)
    }

    @Test("Rating below bounds is clamped")
    func ratingBelowIsClamped() {
        var trackA = Track.example
        trackA.rate(-10)

        let trackB = Track.mock(rating: -10)

        #expect(trackA.rating == 0)
        #expect(trackB.rating == 0)
    }

    @Test("Year above bounds is clamped")
    func yearAboveIsClamped() {
        let track = Track.mock(year: 5000)
        let currentYear = Calendar.current.component(.year, from: Date.now)

        #expect(track.year == currentYear)
    }
}

@MainActor
@Suite("Track uniqueness and deduplication")
struct TrackUniquenessTests {

    @Test("Duplicate tags collapse in Set")
    func duplicateTagsDeduplicate() throws {
        let tagA = try #require(Tag("ambient", category: .comment))
        let tagB = try #require(Tag("Ambient", category: .genre))

        var track = Track.mock()
        track.add(tags: [tagA, tagB])

        #expect(track.tags.count == 1)
    }

    @Test("Removing tags by token removes matching normalized names")
    func removeByToken() {
        var track = Track.mock()
        track.add(tokens: ["Jazz"])

        track.remove(tokens: ["jazz"])
        #expect(track.tags.allSatisfy { $0.normalizedName != "jazz" })
    }
}

@MainActor
@Suite("Track persistence round-trip")
struct TrackRoundTripTests {

    func roundTrip(_ track: Track) throws -> Track {
        let data = try JSONEncoder().encode(track)
        return try JSONDecoder().decode(Track.self, from: data)
    }

    @Test("Encoding and decoding preserves equality")
    func equalityPreserved() throws {
        let original = Track.example
        let decoded = try roundTrip(original)

        #expect(original == decoded)
    }

    @Test("Tags survive round-trip with set semantics intact")
    func tagsPreserved() throws {
        let decoded = try roundTrip(Track.example)
        #expect(decoded.tags == Track.example.tags)
    }
}
