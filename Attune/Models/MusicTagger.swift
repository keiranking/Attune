import Foundation
import AppKit

enum TaggingMode: String, CaseIterable {
    case add = "Add to"
    case remove = "Remove from"

    var systemImage: String {
        switch self {
        case .add:      "plus"
        case .remove:   "minus"
        }
    }
}

enum TaggingScope: String, CaseIterable {
    case current = "Current Track"
    case selection = "Selection"
}

final class MusicTagger {
    static let shared = MusicTagger()
    private init() {}

    var currentTrack: Track?
    var selectedTracks: [Track] = []

    private let fieldDelimiter = "|||"
    private let lineDelimiter = "&&&"

    private var isMusicRunning: Bool {
        NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    // MARK: - Public API

    func refreshState() async {
        guard isMusicRunning else {
            currentTrack = nil
            selectedTracks = []
            return
        }

        readCurrentTrack()
        readSelection()
    }

    // MARK: - Current Track (ScriptingBridge)

    private func readCurrentTrack() {
        if let app = MusicApp.shared.app,
           let track = Track(musicTrack: app.currentTrack) {
            currentTrack = track
        } else {
            currentTrack = nil
        }
    }

    // MARK: - Selection (AppleScript)

    private func readSelection() {
        let result = fetchSelectionScript()
        selectedTracks = parseSelection(result)
    }

    private func fetchSelectionScript() -> String {
        let script = """
        tell application id "com.apple.Music"
            set out to ""
            set sel to selection
            repeat with t in sel
                set out to out & (persistent id of t) & "\(fieldDelimiter)" & (name of t) & "\(fieldDelimiter)" & (artist of t) & "\(fieldDelimiter)" & (rating of t) & "\(fieldDelimiter)" & (comment of t) & "\(fieldDelimiter)" & (grouping of t) & "\(fieldDelimiter)" & (genre of t) & "\(lineDelimiter)"
            end repeat
            return out
        end tell
        """
        return run(script)
    }

    private func parseSelection(_ result: String) -> [Track] {
        result
            .components(separatedBy: lineDelimiter)
            .filter { !$0.isEmpty }
            .compactMap(parseTrackLine(_:))
    }

    private func parseTrackLine(_ line: String) -> Track? {
        let parts = line.components(separatedBy: fieldDelimiter)
        guard parts.count == 7 else { return nil }

        return Track(
            id:       parts[0],
            title:    parts[1],
            artist:   parts[2],
            rating:   Int(parts[3]) ?? 0,
            comment:  parts[4],
            grouping: parts[5],
            genre:    parts[6]
        )
    }

    // MARK: - Modify Tracks

    func process(command: String, scope: TaggingScope?, mode: TaggingMode) async {
        await refreshState()

        var tokens = command
            .replacingOccurrences(of: ",", with: " ")
            .split { $0.isWhitespace }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return }

        let ratings = tokens.subtract(where: { Track.ratingRange.contains(Int($0) ?? -1) })
                            .map({ Int($0)! })

        var tracks: [Track] = []
        if scope == .current, let currentTrack { tracks = [currentTrack] }
        else if scope == .selection { tracks = selectedTracks }

        guard !tracks.isEmpty else { return }

        if let rating = ratings.last {
            applyRating(rating, to: tracks)
        }

        if !tokens.isEmpty {
            for i in 0..<tracks.count {
                if mode == .add {
                    tracks[i].add(tokens: tokens)
                } else {
                    tracks[i].remove(tokens: tokens)
                }
            }

            writeMetadata(tracks: tracks)
        }

        if scope == .current { currentTrack = tracks.first }
        else if scope == .selection { selectedTracks = tracks }
    }

    // MARK: - Write to Music via AppleScript

    private func applyRating(_ rating: Int, to tracks: [Track]) {
        guard !tracks.isEmpty else { return }

        let scriptItems = tracks.map { "(\"\($0.id)\")" }.joined(separator: ", ")

        let script = """
        tell application id "com.apple.Music"
            set trackIds to {\(scriptItems)}
            repeat with tId in trackIds
                set bpm of (some track whose persistent id is tId) to \(rating)
                set rating of (some track whose persistent id is tId) to \(rating * 20)
            end repeat
        end tell
        """
        run(script)
    }
    private func writeMetadata(tracks: [Track]) {
        guard !tracks.isEmpty else { return }

        // Generate a list of lists: {{id, comment, grouping, genre}, {id, ...}}

        var dataList = "{"
        for t in tracks {
            let entry = "{\"\(t.id)\", \"\(escape(t.comment))\", \"\(escape(t.grouping))\", \"\(escape(t.genre))\"}"
            dataList += entry + ","
        }
        if dataList.hasSuffix(",") { dataList.removeLast() }
        dataList += "}"

        let script = """
        tell application id "com.apple.Music"
            set trackData to \(dataList)

            repeat with itemData in trackData
                set tId to item 1 of itemData
                set tComment to item 2 of itemData
                set tGrouping to item 3 of itemData
                set tGenre to item 4 of itemData

                set t to (some track whose persistent id is tId)

                if (comment of t) is not tComment then set comment of t to tComment
                if (grouping of t) is not tGrouping then set grouping of t to tGrouping
                if (genre of t) is not tGenre then set genre of t to tGenre
            end repeat
        end tell
        """

        run(script)
    }


    // MARK: - Helpers

    @discardableResult
    private func run(_ source: String) -> String {
        guard let script = NSAppleScript(source: source) else { return "" }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let e = err { NSLog("AppleScript error: \(e)"); return "" }
        return result.stringValue ?? ""
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
