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

    @Test("Outcome equality is stable")
    func outcomeEquality() {
        #expect(Tagging.Outcome.success == .success)
        #expect(Tagging.Outcome.failure != .success)
    }

    @Test("Scope equality is stable")
    func scopeEquality() {
        #expect(Tagging.Scope.current == .current)
        #expect(Tagging.Scope.selection != .current)
    }

    @Test("State equality is stable")
    func stateEquality() {
        #expect(Tagging.State.ready == .ready)
        #expect(Tagging.State.updating != .ready)
    }
}
