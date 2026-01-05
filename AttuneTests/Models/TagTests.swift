// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@Suite("Tag values")
struct TagValueTests {

    @Test("Tags with same value are equal")
    func equality() {
        let a = Tag("ambient")
        let b = Tag("ambient")

        #expect(a != nil && b != nil)
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    @Test("Tags with same values, but different cases are equal")
    func caseInsensitiveEquality() {
        let a = Tag("ambient")
        let b = Tag("Ambient")

        #expect(a != nil && b != nil)
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    @Test("Tags with same values, but different categories are equal")
    func categoryAgnosticEquality() {
        let a = Tag("ambient", category: .comment)
        let b = Tag("ambient", category: .grouping)

        #expect(a != nil && b != nil)
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    @Test("Empty tag is rejected or normalized")
    func emptyInput() {
        #expect(Tag("") == nil)
    }

    @Test("Whitespace-only input cannot become a Tag")
    func whitespaceOnly() {
        #expect(Tag("   ") == nil)
        #expect(Tag("\n\t") == nil)
    }

    @Test("Whitespace is trimmed")
    func trimmingWhitespace() {
        let tag = Tag("  jazz  ")
        #expect(tag?.name == "jazz")
    }
}

@MainActor
@Suite("Tag round-trip consistency")
struct TagRoundTripTests {

    func roundTrip(_ tag: Attune.Tag) throws -> Attune.Tag {
        let data = try JSONEncoder().encode(tag)
        return try JSONDecoder().decode(Tag.self, from: data)
    }

    @Test("Encoding and decoding preserves equality")
    func equalityPreserved() throws {
        let original = try #require(Tag("Classical", category: .genre))
        let decoded = try roundTrip(original)

        #expect(original == decoded)
    }

    @Test("Category survives round-trip")
    func categoryPreserved() throws {
        let original = try #require(Tag("brass", category: .grouping))
        let decoded = try roundTrip(original)

        #expect(decoded.category == .grouping)
    }

    @Test("Name survives round-trip")
    func namePreserved() throws {
        let original = try #require(Tag("R&B"))
        let decoded = try roundTrip(original)

        #expect(decoded.name == original.name)
        #expect(decoded.normalizedName == original.normalizedName)
    }

    @Test("Decoded tags deduplicate correctly in sets")
    func setSemanticsAfterDecode() throws {
        let a = try roundTrip(#require(Tag("ambient", category: .comment)))
        let b = try roundTrip(#require(Tag("Ambient", category: .genre)))

        let set = Set([a, b])
        #expect(set.count == 1)
    }
}
