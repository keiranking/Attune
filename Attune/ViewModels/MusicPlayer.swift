import Foundation
import MusicKit
import Combine
import AppKit

@Observable
final class MusicPlayer {
    static let shared = MusicPlayer()

    var isPlaying: Bool = false

    var onSync: (() -> Void)?

    private let player = ApplicationMusicPlayer.shared
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSystemNotification),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func start() {
        Task {
            let status = await MusicAuthorization.request()
            if status == .authorized {
                await self.forceRefresh()
            }
        }
    }

    // MARK: - Observation Logic

    @objc private func handleSystemNotification() {
        Task {
            await forceRefresh()
        }
    }

    private func forceRefresh() async {
        try? await Task.sleep(nanoseconds: 20_000_000) // 20 ms-delay allows current track to register

        await MainActor.run {
            self.isPlaying = (self.player.state.playbackStatus == .playing)
            self.onSync?()
        }
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
