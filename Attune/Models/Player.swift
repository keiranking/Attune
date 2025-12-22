extension Music {
    struct Player {
        var isPlaying: Bool {
            Music.shared.playbackState == .playing
        }

        var isDisabled: Bool { Music.shared.isClosed }

        func playPause() {
            Music.shared.withApp { $0.playpause() }
        }

        func next() {
            Music.shared.withApp { $0.nextTrack() }
        }

        func previous() {
            Music.shared.withApp { $0.previousTrack() }
        }
    }
}
