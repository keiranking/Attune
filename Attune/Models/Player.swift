extension Music {
    struct Player {
        var isPlaying: Bool {
            Music.shared.playbackState == .playing
        }

        var isDisabled: Bool {
            Music.shared.app == nil
        }

        func playPause() {
            Music.shared.app?.playpause()
        }

        func next() {
            Music.shared.app?.nextTrack()
        }

        func previous() {
            Music.shared.app?.previousTrack()
        }
    }
}
