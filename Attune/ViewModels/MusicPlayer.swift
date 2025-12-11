import Foundation
import Combine
import AppKit
import ScriptingBridge

extension MusicPlayer {
    enum PlaybackState: String { // reimplement MediaPlayer.MPMusicPlaybackState
        case playing = "Playing"
        case paused = "Paused"
        case stopped = "Stopped"
        case interrupted = "Interrupted"
        case seekingForward = "Seeking Forward"
        case seekingBackward = "Seeking Backward"
    }
}

@Observable
final class MusicPlayer {
    static let shared = MusicPlayer()

    var playbackState: PlaybackState?
    var isPlaying: Bool { playbackState == .playing }

    var musicApp: MusicApplication

    var currentTrackId: String?
    var lastPlayedTrackId: String?

    var onSync: (() -> Void)?

    private init() {
        self.musicApp = unsafeBitCast(
            SBApplication(bundleIdentifier: "com.apple.Music"),
            to: MusicApplication.self
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSystemMusicPlayerNotification),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func start() {
        Task {
            await self.forceRefresh()
        }
    }

    // MARK: - Observation Logic

    @objc private func handleSystemMusicPlayerNotification(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let notificationPlaybackState = userInfo["Player State"] as? String ?? ""
//        let notificationCurrentTrackId = userInfo["PersistentID"] as? String ?? ""

        playbackState = PlaybackState(rawValue: notificationPlaybackState)

        Task {
            await forceRefresh()
        }
    }

    private func forceRefresh() async {
        try? await Task.sleep(nanoseconds: 20_000_000) // 20 ms-delay allows current track to register

        await MainActor.run { self.onSync?() }
    }

    // MARK: - Controls

    func playPauseTrack() { musicApp.playpause() }

    func skipToNextTrack() { musicApp.nextTrack() }

    func skipToPreviousTrack() { musicApp.previousTrack() }
}
