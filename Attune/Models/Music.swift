import Foundation
import AppKit
import ScriptingBridge

@Observable
final class Music { // core functions, setup
    static let shared = Music()

    var currentTrack: Track? = nil
    var selectedTracks: [Track] = []

    var playbackState: PlaybackState? = nil

    let player = Player()
    let tagger = Tagger()

    var onChange: (() -> Void)?

    private init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlayerInfo),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}

extension Music {
    enum PlaybackState: String {
        case playing = "Playing"
        case paused = "Paused"
        case stopped = "Stopped"
        case interrupted = "Interrupted"
        case seekingForward = "Seeking Forward"
        case seekingBackward = "Seeking Backward"
    }
}

extension Music {
    func withApp<T>(_ work: (MusicApplication) -> T) -> T? {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")

        guard let musicApp = apps.first(where: { !$0.isTerminated })
        else { return nil }

        let pid = musicApp.processIdentifier
        guard let base = SBApplication(processIdentifier: pid),
              let app = unsafeBitCast(base, to: MusicApplication.self) as MusicApplication?
        else { return nil }

        return work(app)
    }

    var isOpen: Bool {
        guard
            let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first
        else { return false }

        return !app.isTerminated && app.processIdentifier != -1
    }

    var isClosed: Bool { !isOpen }
}

extension Music { // respond and update
    @objc private func handlePlayerInfo(_ notification: Notification) {
        if let raw = notification.userInfo?["Player State"] as? String {
            playbackState = PlaybackState(rawValue: raw)
        }

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)

            refresh()
            await MainActor.run { onChange?() }
        }
    }

    func refresh() {
        guard isOpen else {
            reset()
            return
        }

        readCurrentTrack()
        readSelection()
        readPlayerState()
    }

    func reset() {
        currentTrack = nil
        selectedTracks = []
        playbackState = nil
    }

    private func readCurrentTrack() {
        currentTrack = withApp {
            Track(musicTrack: $0.currentTrack)
        } ?? nil
    }

    private func readSelection() {
        selectedTracks = tagger.readSelection()
    }

    private func readPlayerState() {
        playbackState = withApp {
            switch $0.playerState {
            case MusicEPlSPlaying:          .playing
            case MusicEPlSPaused:           .paused
            case MusicEPlSStopped:          .stopped
            case MusicEPlSFastForwarding:   .seekingForward
            case MusicEPlSRewinding:        .seekingBackward
            default: nil
            }
        } ?? nil
    }
}

extension Music { // AppleScript
    @discardableResult
    func run(_ source: String) -> String {
        guard let script = NSAppleScript(source: source) else { return "" }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let e = err { NSLog("AppleScript error: \(e)") }
        return result.stringValue ?? ""
    }
}
