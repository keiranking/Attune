import Foundation
import MusicKit
import Combine
import AppKit

@Observable
final class MusicPlayer {
    static let shared = MusicPlayer()

    var isPlaying: Bool = false
    private var currentSong: Song?

    var onSync: (() -> Void)?

    private let player = ApplicationMusicPlayer.shared
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        player.state.objectWillChange // playing, paused, etc
            .sink { [weak self] _ in
                self?.handleStateChange()
            }
            .store(in: &cancellables)

        player.queue.objectWillChange // going from one track to the next
            .sink { [weak self] _ in
                self?.handleQueueChange()
            }
            .store(in: &cancellables)

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

    private func handleStateChange() {
        Task { @MainActor in
            let newIsPlaying = (self.player.state.playbackStatus == .playing)
            if self.isPlaying != newIsPlaying {
                self.isPlaying = newIsPlaying
                self.onSync?()
            }
        }
    }

    private func handleQueueChange() {
        Task { @MainActor in
            let newItem = self.player.queue.currentEntry?.item
            if case let .song(song) = newItem {
                if self.currentSong?.id != song.id {
                    self.currentSong = song
                    self.onSync?()
                }
            } else {
                self.currentSong = nil
                self.onSync?()
            }
        }
    }

    @objc private func handleSystemNotification() {
        Task {
            await forceRefresh()
        }
    }

    private func forceRefresh() async {
        await MainActor.run {
            self.isPlaying = (self.player.state.playbackStatus == .playing)
            if let item = self.player.queue.currentEntry?.item, case let .song(song) = item {
                self.currentSong = song
            }
            self.onSync?()
        }
    }

    // MARK: - Controls

    func togglePlayPause() {
        runAppleScript("tell application id \"com.apple.Music\" to playpause")
    }

    func nextTrack() {
        runAppleScript("tell application id \"com.apple.Music\" to next track")
    }

    func previousTrack() {
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
