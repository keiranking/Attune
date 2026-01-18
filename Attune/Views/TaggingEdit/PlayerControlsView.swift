import SwiftUI

struct PlayerControlsView: View {
    @Environment(Music.self) var music

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { music.player.previous() }) {
                Label("PlayerControlsView.previousButtonLabel", systemImage: Icon.previous.name)
                    .help("PlayerControlsView.previousButtonTooltip")
            }

            Button(action: { music.player.playPause() }) {
                Label(
                    "PlayerControlsView.playButtonLabel",
                    systemImage: (music.player.isPlaying ? Icon.pause : Icon.play).name
                )
                .font(.system(size: 24))
                .help(
                    music.player.isPlaying
                    ? "PlayerControlsView.playButtonIsPlayingTooltip"
                    : "PlayerControlsView.playButtonIsPausedTooltip"
                )
            }

            Button(action: { music.player.next() }) {
                Label("PlayerControlsView.nextButtonLabel", systemImage: Icon.next.name)
                    .help("PlayerControlsView.nextButtonTooltip")
            }
        }
        .disabled(music.player.isDisabled)
        .buttonStyle(.playerButton)
        .padding(.horizontal, 8)
    }
}
