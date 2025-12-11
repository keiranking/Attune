import SwiftUI

@Observable
final class OverlayState {
    var text: String = ""
    var scope: TaggingScope?
    var mode: TaggingMode = .add

    var currentTrack: Track?
    var selectedTracks: [Track] = []

    var selectedTrackIsCurrent: Bool { selectedTracks == [currentTrack] }

    var showSecondaryInfo: Bool = false

    var currentTrackTitle: String { currentTrack?.title ?? "No current track" }
    var currentTrackArtist: String? { currentTrack?.artist }
    var currentTrackRating: Int? { currentTrack?.rating }
    var currentTrackMetadata: String? {
        guard let currentTrack else { return nil }
        return [
            "\(currentTrack.rating)",
            currentTrack.genre,
            currentTrack.comment,
            currentTrack.grouping
        ].joined(separator: " • ")
    }
    var currentTrackSubtitle: ScopeRowView.SubtitleContent {
        return if hasCurrentTrack {
            showSecondaryInfo
            ? .text(currentTrackArtist ?? "")
            : .label(text: currentTrackMetadata ?? "",
                     icon: currentTrackRating == 0 ? "star" : "star.fill")
        } else {
            .text("Play a track in the Music app")
        }
    }
    var hasCurrentTrack: Bool { currentTrack != nil }

    var selectedTracksCount: Int { selectedTracks.count }
    var selectedTrackTitle: String {
        switch selectedTracks.count {
        case 0:     "No selected tracks"
        case 1:     selectedTracks.first?.title ?? "1 selected track"
        default:    "\(selectedTracks.count) selected tracks"
        }
    }
    var selectedTrackArtist: String? { selectedTracks.first?.artist }
    var selectedTrackRating: Int? { selectedTracks.first?.rating }
    var selectedTrackMetadata: String? {
        guard let firstTrack = selectedTracks.first else { return nil }
        return [
            "\(firstTrack.rating)",
            firstTrack.genre,
            firstTrack.comment,
            firstTrack.grouping
        ].joined(separator: " • ")
    }
    var selectedTrackSubtitle: ScopeRowView.SubtitleContent {
        switch selectedTracks.count {
        case 0:     .text("Select a track in the Music app")
        case 1:     showSecondaryInfo
                    ? .text(selectedTrackArtist ?? "")
                    : .label(text: selectedTrackMetadata ?? "",
                             icon: selectedTrackRating == 0 ? "star" : "star.fill")
        default:    .none
        }
    }
    var hasSelectedTracks: Bool { !selectedTracks.isEmpty }

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
}

struct OverlayView: View {
    @Bindable var state: OverlayState
    @EnvironmentObject var library: TagLibrary
    var onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("", text: $state.text) {
                    onCommit(state.text)
                }
                .font(.system(size: 24))
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            PlayerControls()

            Picker("", selection: $state.mode) {
                ForEach(TaggingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 60)
            .padding(.bottom, 12)

            VStack(spacing: 4) {
                ScopeRowView(
                    status: !state.hasCurrentTrack ? .disabled : (state.scope == .current ? .active : .inactive),
                    icon: state.hasCurrentTrack ? "waveform" : "waveform.slash",
                    title: state.currentTrackTitle,
                    subtitle: state.currentTrackSubtitle,
                    color: state.mode == .add ? .green : .red
                )
                .onTapGesture { state.scope = .current }
                .disabled(!state.hasCurrentTrack)

                if !state.selectedTrackIsCurrent {
                    ScopeRowView(
                        status: !state.hasSelectedTracks ? .disabled : (state.scope == .selection ? .active : .inactive),
                        icon: "cursorarrow.rays",
                        title: state.selectedTrackTitle,
                        subtitle: state.selectedTrackSubtitle,
                        color: state.mode == .add ? .green : .red
                    )
                    .onTapGesture { state.scope = .selection }
                    .disabled(!state.hasSelectedTracks)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 600)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(12)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .task {
            isFocused = true
        }
    }
}

struct PlayerControls: View {
    @Environment(MusicPlayer.self) var player

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { player.skipToPreviousTrack() }) {
                Image(systemName: "backward.fill")
            }
            Button(action: { player.playPauseTrack() }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
            }
            Button(action: { player.skipToNextTrack() }) {
                Image(systemName: "forward.fill")
            }
        }
        .disabled(player.isDisabled)
        .buttonStyle(.plain)
        .font(.system(size: 16))
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}
