import Foundation
import AppKit
import ScriptingBridge

@Observable
final class Music { // core functions, setup
    static let shared = Music()

    var currentTrack: Track?
    var selectedTracks: [Track] = []

    var playbackState: PlaybackState?

    let player = Player()
    let tagger = Tagger()

    private var proxy: MusicApplication?
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

extension Music { // ensure we can always connect to and control the Music app
    var app: MusicApplication? {
        validateProxy()
        return proxy
    }

    private func validateProxy() {
        if proxy == nil || proxy?.isRunning == false {
            proxy = createProxy()
        }
    }

    private func createProxy() -> MusicApplication? {
        guard let base = SBApplication(bundleIdentifier: "com.apple.Music") else {
            print("MusicApp: SBApplication returned nil.")
            return nil
        }
        return unsafeBitCast(base, to: MusicApplication.self)
    }
}

extension Music { // respond and update
    @objc private func handlePlayerInfo(_ notification: Notification) {
        if let raw = notification.userInfo?["Player State"] as? String {
            playbackState = PlaybackState(rawValue: raw)
        }

        Task {
            try? await Task.sleep(nanoseconds: 20_000_000)
            refresh()
            await MainActor.run { onChange?() }
        }
    }

    func refresh() {
        readCurrentTrack()
        readSelection()
        readPlayerState()
    }

    private func readCurrentTrack() {
        if let musicTrack = app?.currentTrack,
           let track = Track(musicTrack: musicTrack) {
            currentTrack = track
        } else {
            currentTrack = nil
        }
    }

    private func readSelection() {
        selectedTracks = tagger.readSelection()
    }

    private func readPlayerState() {
        guard let state = app?.playerState else { return }

        playbackState = switch state {
        case MusicEPlSPlaying:          .playing
        case MusicEPlSPaused:           .paused
        case MusicEPlSStopped:          .stopped
        case MusicEPlSFastForwarding:   .seekingForward
        case MusicEPlSRewinding:        .seekingBackward
        default: nil
        }
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
