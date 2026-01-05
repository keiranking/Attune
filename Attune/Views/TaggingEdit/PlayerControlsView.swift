import SwiftUI

struct PlayerControlsView: View {
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
