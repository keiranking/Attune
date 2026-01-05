// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@MainActor
@Suite("OverlayViewModel unit tests")
struct OverlayViewModelTests {

    @Test("Defaults are sane on init")
    func defaults() {
        let vm = OverlayViewModel()

        #expect(vm.text == "")
        #expect(vm.mode == .add)
        #expect(vm.scope == nil)
        #expect(vm.state == .ready)
        #expect(vm.outcome == nil)
        #expect(vm.currentTrack == nil)
        #expect(vm.selectedTracks.isEmpty)
        #expect(vm.hasCurrentTrack == false)
        #expect(vm.hasSelectedTracks == false)
    }

    @Test("Reset clears transient state")
    func reset() {
        let vm = OverlayViewModel()
        vm.text = "foo"
        vm.mode = .remove
        vm.scope = .selection
        vm.state = .updating

        vm.reset()

        #expect(vm.text == "")
        #expect(vm.mode == .add)
        #expect(vm.scope == nil)
        #expect(vm.state == .ready)
        #expect(vm.outcome == nil)
    }

    @Test("Inline remove command switches mode")
    func inlineRemoveCommand() {
        let vm = OverlayViewModel()
        vm.text = "x ambient"

        vm.processInlineCommands()

        #expect(vm.mode == .remove)
        #expect(vm.text == "ambient")
    }

    @Test("Inline selection command switches scope")
    func inlineSelectionCommand() {
        let vm = OverlayViewModel()
        vm.text = "s jazz"

        vm.processInlineCommands()

        #expect(vm.scope == .selection)
        #expect(vm.text == "jazz")
    }

    @Test("Default scope prefers current track")
    func defaultScopePrefersCurrent() throws {
        let vm = OverlayViewModel()
        vm.currentTrack = .mock()

        vm.chooseDefaultScope()

        #expect(vm.scope == .current)
    }

    @Test("Default scope falls back to selection")
    func defaultScopeSelectionFallback() throws {
        let vm = OverlayViewModel()
        vm.selectedTracks = [.mock()]

        vm.chooseDefaultScope()

        #expect(vm.scope == .selection)
    }

    @Test("Toggle scope switches when both scopes exist")
    func toggleScopeSwitches() throws {
        let vm = OverlayViewModel()
        vm.currentTrack = .mock(id: "A")
        vm.selectedTracks = [.mock(id: "B")]
        vm.scope = .current

        vm.toggleScope()

        #expect(vm.scope == .selection)
    }

    @Test("Toggle scope does nothing if alternative unavailable")
    func toggleScopeNoOp() throws {
        let vm = OverlayViewModel()
        vm.currentTrack = .mock()
        vm.scope = .current

        vm.toggleScope()

        #expect(vm.scope == .current)
    }

    @Test("Selected track equals current detection")
    func selectedTrackIsCurrent() throws {
        let track = Track.mock()
        let vm = OverlayViewModel()

        vm.currentTrack = track
        vm.selectedTracks = [track]

        #expect(vm.selectedTrackIsCurrent == true)
    }

    @Test("Selected track title recognizes multiple tracks")
    func multipleSelectedTracksTitle() throws {
        let vm = OverlayViewModel()
        vm.selectedTracks = [.mock(id: "A"), .mock(id: "B")]

        #expect(vm.selectedTrackTitle == "2 selected tracks")
    }
}
