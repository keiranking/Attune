import SwiftUI

@Observable
final class OverlayViewModel {
    var text: String = ""
    var scope: Tagging.Scope?
    var mode: Tagging.Mode = .add
    var state: Tagging.State = .ready
    var outcome: Tagging.Outcome? = nil

    var currentTrack: Track?
    var selectedTracks: [Track] = []

    var selectedTrackIsCurrent: Bool { selectedTracks == [currentTrack] }

    var showSecondaryInfo: Bool = false

    var textPlaceholder: String {
        Whitelist.shared.tags.count < 5 ? "Enter space-separated tags" : ""
    }

    // MARK: Current track, derived properties

    var currentTrackIcon: String {
        if scope == .current, let outcome {
            return outcome == .success ? Icon.success : Icon.failure
        }

        let base = hasCurrentTrack
            ? (Music.shared.player.isPlaying ? Icon.currentPlaying : Icon.currentPaused)
            : Icon.currentDisabled

        guard scope == .current else { return base }

        return state == .updating ? Icon.updating : base
    }

    var currentTrackTitle: String { currentTrack?.title ?? "No current track" }
    private var currentTrackArtist: String? { currentTrack?.artist }
    private var currentTrackRating: Int? { currentTrack?.rating }
    private var currentTrackMetadata: String? {
        guard let currentTrack else { return nil }
        return [
            "\(currentTrack.rating)",
            currentTrack.genre,
            currentTrack.comment,
            currentTrack.grouping
        ]
            .compactMap { $0 }
            .filter { $0 != "" }
            .joined(separator: " • ")
    }
    var currentTrackSubtitle: ScopeRowView.SubtitleContent {
        return if hasCurrentTrack {
            showSecondaryInfo
            ? .text(currentTrackArtist ?? "")
            : .label(text: currentTrackMetadata ?? "",
                     icon: currentTrackRating == 0 ? Icon.unrated : Icon.rated)
        } else {
            .text("Play a track in the Music app")
        }
    }
    var hasCurrentTrack: Bool { currentTrack != nil }

    // MARK: Selected track, derived properties

    private var selectedTracksCount: Int { selectedTracks.count }

    var selectedTrackIcon: String {
        if scope == .selection, let outcome {
            return outcome == .success ? Icon.success : Icon.failure
        }

        let base = Icon.selected

        guard scope == .selection else { return base }

        return state == .updating ? Icon.updating : base
    }

    var selectedTrackTitle: String {
        switch selectedTracks.count {
        case 0:     "No selected tracks"
        case 1:     selectedTracks.first?.title ?? "1 selected track"
        default:    "\(selectedTracks.count) selected tracks"
        }
    }
    private var selectedTrackArtist: String? { selectedTracks.first?.artist }
    private var selectedTrackRating: Int? { selectedTracks.first?.rating }
    private var selectedTrackMetadata: String? {
        guard let firstTrack = selectedTracks.first else { return nil }
        return [
            "\(firstTrack.rating)",
            firstTrack.genre,
            firstTrack.comment,
            firstTrack.grouping
        ]
            .compactMap { $0 }
            .filter { $0 != "" }
            .joined(separator: " • ")
    }
    var selectedTrackSubtitle: ScopeRowView.SubtitleContent {
        switch selectedTracks.count {
        case 0:     .text("Select track(s) in the Music app")
        case 1:     showSecondaryInfo
                    ? .text(selectedTrackArtist ?? "")
                    : .label(text: selectedTrackMetadata ?? "",
                             icon: selectedTrackRating == 0 ? Icon.unrated : Icon.rated)
        default:    .none
        }
    }
    var hasSelectedTracks: Bool { !selectedTracks.isEmpty }

    // MARK: Functions

    func reset() {
        text = ""
        mode = .add
        scope = nil
        state = .ready
    }

    func chooseDefaultScope() {
        if hasCurrentTrack { scope = .current }
        else if hasSelectedTracks { scope = .selection }
        else { scope = nil }
    }

    func toggleScope() {
        switch scope {
        case .current:
            hasSelectedTracks && !selectedTrackIsCurrent ? (scope = .selection) : ()
        case .selection:
            hasCurrentTrack ? (scope = .current) : ()
        case nil:
            break
        }
    }

    func toggleMode() {
        mode = (mode == .add) ? .remove : .add
    }

    func processInlineCommands() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("x ") {
            mode = .remove
            text = String(trimmed.dropFirst(2))
            return
        }

        if trimmed.hasPrefix("s ") {
            scope = .selection
            text = String(trimmed.dropFirst(2))
            return
        }
    }
}

struct OverlayView: View {
    @Bindable var viewModel: OverlayViewModel
    @Environment(Music.self) var music

    var onSubmit: (_ text: String, _ dismiss: Bool) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            omniBar
                .padding(.bottom, 8)

            ZStack {
                playerControls

                HStack {
                    modeControls
                        .frame(width: 150)

                    Spacer()
                }
            }
            .padding(.bottom, 12)

            VStack(spacing: 4) {
                currentRow
                if !viewModel.selectedTrackIsCurrent { selectedRow }
            }
        }
        .padding(16)
        .frame(width: 600)
        .background { background }
        .task { isFocused = true }
        .overlay { keyboardShortcuts }
        .disabled(music.isClosed)
    }

    var omniBar: some View {
        HStack {
            TextField("", text: $viewModel.text, prompt: Text(viewModel.textPlaceholder))
            .onSubmit {
                onSubmit(viewModel.text, true)
            }
            .onChange(of: viewModel.text) {
                viewModel.processInlineCommands()
            }
            .font(.system(size: 24))
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color.antiprimary.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .focused($isFocused)
        }
    }

    var playerControls: some View { PlayerControls() }

    var modeControls: some View {
        Picker("", selection: $viewModel.mode) {
            ForEach(Tagging.Mode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.systemImage)
                    .labelStyle(.iconOnly)
                    .help(mode.rawValue)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    var currentRow: some View {
        ScopeRowView(
            status: !viewModel.hasCurrentTrack
                    ? .disabled
                    : (viewModel.scope == .current ? .active : .inactive),
            icon: viewModel.currentTrackIcon,
            title: viewModel.currentTrackTitle,
            subtitle: viewModel.currentTrackSubtitle,
            color: viewModel.mode == .add ? .green : .red,
            isAnimated:
                music.player.isPlaying
                || (viewModel.scope == .current && viewModel.state == .updating)
        )
        .onTapGesture { viewModel.scope = .current }
        .disabled(!viewModel.hasCurrentTrack)
        .help("Apply changes to current track")
    }

    var selectedRow: some View {
        ScopeRowView(
            status: !viewModel.hasSelectedTracks
                    ? .disabled
                    : (viewModel.scope == .selection ? .active : .inactive),
            icon: viewModel.selectedTrackIcon,
            title: viewModel.selectedTrackTitle,
            subtitle: viewModel.selectedTrackSubtitle,
            color: viewModel.mode == .add ? .green : .red,
            isAnimated:
                viewModel.scope == .selection && viewModel.state == .updating
        )
        .onTapGesture { viewModel.scope = .selection }
        .disabled(!viewModel.hasSelectedTracks)
        .help("Apply changes to selected track(s)")
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.regularMaterial)
    }

    var keyboardShortcuts: some View {
        HStack {
            Button("Add to") { viewModel.mode = .add }
                .keyboardShortcut("+", modifiers: [.command])

            Button("Remove from") { viewModel.mode = .remove }
                .keyboardShortcut("-", modifiers: [.command])

            Button("Submit and Continue") {
                let text = viewModel.text
                onSubmit(text, false)
            }
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .hidden()
    }
}

struct PlayerControls: View {
    @Environment(Music.self) var music

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { music.player.previous() }) {
                Label("Previous Track", systemImage: Icon.previous)
                    .help("Skip to previous")
            }

            Button(action: { music.player.playPause() }) {
                Label(
                    "Play/Pause",
                    systemImage: music.player.isPlaying ? Icon.pause : Icon.play
                )
                .font(.system(size: 24))
                .help(music.player.isPlaying ? "Pause" : "Play")
            }

            Button(action: { music.player.next() }) {
                Label("Next Track", systemImage: Icon.next)
                    .help("Skip to next")
            }
        }
        .disabled(music.player.isDisabled)
        .buttonStyle(.playerButton)
        .padding(.horizontal, 8)
    }
}
