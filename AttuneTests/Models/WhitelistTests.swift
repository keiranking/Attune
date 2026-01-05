// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@Suite("Whitelist unit tests")
struct WhitelistTests {

    fileprivate let storage = TestStorage()

    @Test("Whitelist starts empty")
    func emptyWhitelistStartsEmpty() {
        let whitelist = Whitelist(storage: storage)
        #expect(whitelist.tags.isEmpty)
    }

    @Test("Replacing tags replaces the whitelist")
    func replacingTags() throws {
        let tag = try #require(Tag("ambient"))
        let whitelist = Whitelist(storage: storage)

        whitelist.replace(with: [tag])

        #expect(whitelist.tags == [tag])
    }

    @Test("Duplicate tags are ignored")
    func duplicateTags() throws {
        let tag = try #require(Tag("ambient"))
        let whitelist = Whitelist(storage: storage)

        whitelist.replace(with: [tag, tag])

        #expect(whitelist.tags.count == 1)
    }

    @Test("Duplicate tags are ignored, regardless of case")
    func duplicateTagsDifferentCases() throws {
        let tagA = try #require(Tag("ambient"))
        let tagB = try #require(Tag("Ambient"))
        let whitelist = Whitelist(storage: storage)

        whitelist.replace(with: [tagA, tagB])

        #expect(whitelist.tags.count == 1)
    }

    @Test("Finding category for tag works")
    func lookupCategory() throws {
        let tag = try #require(Tag("Jazz", category: .genre))
        let whitelist = Whitelist(storage: storage)
        whitelist.replace(with: [tag])

        #expect(whitelist.category(for: "Jazz") == .genre)
    }

    @Test("Finding category for non-existent tag fails")
    func lookupCategoryForMissingTag() throws {
        let whitelist = Whitelist(storage: storage)

        #expect(whitelist.category(for: "Jazz") == nil)
    }
}
