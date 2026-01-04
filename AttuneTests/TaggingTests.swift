// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@Suite("Tagging")
struct TaggingTests {

    @Test("Mode toggles deterministically")
    func modeToggle() {
        var mode: Tagging.Mode = .add
        mode.toggle()
        #expect(mode == .remove)

        mode.toggle()
        #expect(mode == .add)
    }

    @Test("Mode covers all cases")
    func modeExhaustive() {
        #expect(Tagging.Mode.allCases.count == 2)
    }
}
