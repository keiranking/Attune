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

    var omniboxPrompt: String = ""
    var showOmniboxPrompt: Bool { AppSettings.shared.showOmniboxPrompt }
    var showAutocompletion: Bool { true }

    // MARK: Current track, derived properties

    var currentTrackStatus: ScopeRowView.Status {
        if !hasCurrentTrack { .disabled }
        else { scope == .current ? .active : .inactive }
    }

    var currentTrackIcon: Icon {
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
    private var currentTrackAlternateMetadata: String? {
        guard let currentTrack else { return nil }
        return [
            currentTrack.artist,
            currentTrack.album == "" ? nil : "— \(currentTrack.album)",
            currentTrack.year == 0 ? nil :"(\(currentTrack.year))"
        ]
        .compactMap { $0 }
        .filter { $0 != "" }
        .joined(separator: " ")
    }

    var currentTrackSubtitle: ScopeRowView.SubtitleContent {
        guard let currentTrack else { return .text("Play a track in the Music app") }

        return if showSecondaryInfo {
            .text(currentTrackAlternateMetadata ?? "")
        } else {
            .label(text: currentTrackMetadata ?? "",
                   icon: currentTrack.rating == 0 ? Icon.unrated : Icon.rated)
        }
    }
    var hasCurrentTrack: Bool { currentTrack != nil }

    // MARK: Selected track, derived properties

    private var selectedTracksCount: Int { selectedTracks.count }

    var selectedTrackStatus: ScopeRowView.Status {
        if !hasSelectedTracks { .disabled }
        else { scope == .selection ? .active : .inactive }
    }

    var selectedTrackIcon: Icon {
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
    private var selectedTrackAlternateMetadata: String? {
        guard let firstTrack = selectedTracks.first else { return nil }
        return [
            firstTrack.artist,
            firstTrack.album == "" ? nil : "— \(firstTrack.album)",
            firstTrack.year == 0 ? nil :"(\(firstTrack.year))"
        ]
        .compactMap { $0 }
        .filter { $0 != "" }
        .joined(separator: " ")
    }

    var selectedTrackSubtitle: ScopeRowView.SubtitleContent {
        switch selectedTracks.count {
        case 0:     .text("Select track(s) in the Music app")
        case 1:     if showSecondaryInfo {
                        .text(selectedTrackAlternateMetadata ?? "")
                    } else {
                        .label(text: selectedTrackMetadata ?? "",
                               icon: selectedTracks.first?.rating == 0 ? Icon.unrated : Icon.rated)
                    }
        default:    .none
        }
    }

    var hasSelectedTracks: Bool { !selectedTracks.isEmpty }

    // MARK: Other

    var scopeRowTooltip = "Submit Changes (⏎)"

    // MARK: Omnibox

    func generateOmniboxPrompt() -> String {
        let prefix = Bool.random(weight: 0.25) ? ["x", "s"].shuffled().first! : nil
        let comment = Tag.examples.shuffled().first(where: { $0.category == .comment })?.normalizedName
        let genre = Tag.examples.shuffled().first(where: { $0.category == .genre })?.normalizedName
        let grouping = Tag.examples.shuffled().first(where: { $0.category == .grouping })?.normalizedName
        let rating = Bool.random() ? "\(Int.random(in: Track.ratingRange))" : nil

        var keywords = [comment, genre, grouping, rating].compactMap({ $0 }).shuffled()
        keywords.removeFirst()
        if let prefix { keywords.insert(prefix, at: 0) }

        return keywords.joined(separator: " ")
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

    // MARK: Functions

    func reset() {
        text = ""
        mode = .add
        scope = nil
        state = .ready
        omniboxPrompt = generateOmniboxPrompt()
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

    func toggleMode() { mode.toggle() }
}

struct OverlayView: View {
    @Bindable var viewModel: OverlayViewModel
    @Environment(Music.self) var music

    var onSubmit: (_ text: String, _ dismiss: Bool) -> Void

    @Environment(\.openSettings) private var openSettings
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            omnibox

            ZStack {
                playerControls

                HStack {
                    modeControls

                    Spacer()

                    otherControls
                }
            }

            VStack(spacing: 4) {
                currentRow
                if !viewModel.selectedTrackIsCurrent { selectedRow }
            }
        }
        .tint(.primary)
        .padding(12)
        .frame(width: 600)
        .background { background }
        .task { isFocused = true }
        .overlay { keyboardShortcuts }
        .disabled(music.isClosed)
    }

    var omnibox: some View {
        HStack {
            TextField(
                "",
                text: $viewModel.text,
                prompt: viewModel.showOmniboxPrompt ? Text(viewModel.omniboxPrompt) : nil
            )
            .autocomplete(
                text: $viewModel.text,
                using: Whitelist.shared.suggestions,
                disabled: !viewModel.showAutocompletion
            )
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
            .help("Enter keywords and/or rating")
        }
    }

    var modeControls: some View {
        Toggle("", isOn: Binding(
            get: { viewModel.mode == .add },
            set: { _ in viewModel.toggleMode() }
        ))
        .toggleStyle(SymbolSwitchToggleStyle(
            onSymbol: Icon.add.name,
            offSymbol: Icon.remove.name
        ))
        .help(viewModel.mode == .add ? "Add Mode (⌘+)" :"Remove Mode (⌘-)")
    }

    var playerControls: some View { PlayerControls() }

    var otherControls: some View {
        Button(action: { openSettings() }) {
            Label("Settings", systemImage: Icon.settings.name)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.playerButton)
        .help("Settings")
    }

    var currentRow: some View {
        ScopeRowView(
            status:     viewModel.currentTrackStatus,
            icon:       viewModel.currentTrackIcon,
            title:      viewModel.currentTrackTitle,
            subtitle:   viewModel.currentTrackSubtitle,
            color:      viewModel.mode == .add ? .green : .red,
            isAnimated:
                music.player.isPlaying
                || (viewModel.scope == .current && viewModel.state == .updating)
        )
        .onHover { _ in viewModel.scope = .current }
        .onTapGesture { onSubmit(viewModel.text, true) }
        .disabled(!viewModel.hasCurrentTrack)
        .help(viewModel.hasCurrentTrack ? viewModel.scopeRowTooltip : "")
    }

    var selectedRow: some View {
        ScopeRowView(
            status:     viewModel.selectedTrackStatus,
            icon:       viewModel.selectedTrackIcon,
            title:      viewModel.selectedTrackTitle,
            subtitle:   viewModel.selectedTrackSubtitle,
            color:      viewModel.mode == .add ? .green : .red,
            isAnimated:
                viewModel.scope == .selection && viewModel.state == .updating
        )
        .onHover { _ in viewModel.scope = .selection }
        .onTapGesture { onSubmit(viewModel.text, true) }
        .disabled(!viewModel.hasSelectedTracks)
        .help(viewModel.hasSelectedTracks ? viewModel.scopeRowTooltip : "")
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.regularMaterial)
    }

    var keyboardShortcuts: some View {
        HStack {
            Button("Add Mode") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    viewModel.mode = .add
                }
            }
            .keyboardShortcut("+", modifiers: [.command])

            Button("Remove Mode") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    viewModel.mode = .remove
                }
            }
            .keyboardShortcut("-", modifiers: [.command])

            Button("Apply and Continue") {
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
                Label("Previous Track", systemImage: Icon.previous.name)
                    .help("Previous (F7)")
            }

            Button(action: { music.player.playPause() }) {
                Label(
                    "Play/Pause",
                    systemImage: (music.player.isPlaying ? Icon.pause : Icon.play).name
                )
                .font(.system(size: 24))
                .help((music.player.isPlaying ? "Pause" : "Play") + " (F8)")
            }

            Button(action: { music.player.next() }) {
                Label("Next Track", systemImage: Icon.next.name)
                    .help("Next (F9)")
            }
        }
        .disabled(music.player.isDisabled)
        .buttonStyle(.playerButton)
        .padding(.horizontal, 8)
    }
}
