import Foundation
import Combine
import AppKit

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

    var currentTrackId: String?
    var lastPlayedTrackId: String?

    var onSync: (() -> Void)?

    private init() {
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
        let notificationCurrentTrackId = userInfo["PersistentID"] as? String ?? ""

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

    func togglePlayPause() {
        runAppleScript("tell application id \"com.apple.Music\" to playpause")
    }

    func skipToNextTrack() {
        runAppleScript("tell application id \"com.apple.Music\" to next track")
    }

    func skipToPreviousTrack() {
        runAppleScript("tell application id \"com.apple.Music\" to previous track")
    }

    private func runAppleScript(_ source: String) {
        guard let script = NSAppleScript(source: source) else { return }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error = error {
            print("MusicPlayer Control Error: \(error)")
        }
    }
}
