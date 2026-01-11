import SwiftUI

struct PlayerControlsView: View {
    @Environment(Music.self) var music

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { music.player.previous() }) {
                Label(.playerControlsViewPreviousButtonLabel, systemImage: Icon.previous.name)
                    .help(.playerControlsViewPreviousButtonTooltip)
            }

            Button(action: { music.player.playPause() }) {
                Label(
                    .playerControlsViewPlayButtonLabel,
                    systemImage: (music.player.isPlaying ? Icon.pause : Icon.play).name
                )
                .font(.system(size: 24))
                .help((music.player.isPlaying
                       ? .playerControlsViewPlayButtonIsPlayingTooltip
                       : .playerControlsViewPlayButtonIsPausedTooltip))
            }

            Button(action: { music.player.next() }) {
                Label(.playerControlsViewNextButtonLabel, systemImage: Icon.next.name)
                    .help(.playerControlsViewNextButtonTooltip)
            }
        }
        .disabled(music.player.isDisabled)
        .buttonStyle(.playerButton)
        .padding(.horizontal, 8)
    }
}
