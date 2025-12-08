import Foundation
import AppKit

enum TaggingMode: String, CaseIterable {
    case add = "Add to"
    case remove = "Remove from"
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
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    // MARK: - Fetching

    func refreshState() async {
        guard isMusicRunning else {
            currentTrack = nil
            selectedTracks = []
            return
        }

        // Fetch once to minimize overhead
        let script = """
        tell application id "com.apple.Music"
            set resultString to ""

            -- 1. Get Current Track
            if player state is playing or player state is paused then
                set t to current track
                set resultString to resultString & (persistent id of t) & "\(fieldDelimiter)" & (name of t) & "\(fieldDelimiter)" & (artist of t) & "\(fieldDelimiter)" & (rating of t) & "\(fieldDelimiter)" & (comment of t) & "\(fieldDelimiter)" & (grouping of t) & "\(fieldDelimiter)" & (genre of t)
            else
                set resultString to resultString & "missing"
            end if

            set resultString to resultString & "\(lineDelimiter)"

            -- 2. Get Selection (Limit to 500 to prevent timeout)
            set sel to selection
            set selCount to count of sel
            if selCount > 500 then set selCount to 500

            repeat with i from 1 to selCount
                set t to item i of sel
                set resultString to resultString & (persistent id of t) & "\(fieldDelimiter)" & (name of t) & "\(fieldDelimiter)" & (artist of t) & "\(fieldDelimiter)" & (rating of t) & "\(fieldDelimiter)" & (comment of t) & "\(fieldDelimiter)" & (grouping of t) & "\(fieldDelimiter)" & (genre of t) & "\(lineDelimiter)"
            end repeat

            return resultString
        end tell
        """

        let result = runAppleScript(script)
        parseScriptResult(result)
    }

    private func parseScriptResult(_ result: String) {
        let lines = result.components(separatedBy: lineDelimiter).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }

        if let firstLine = lines.first, firstLine != "missing" {
            currentTrack = trackFromLine(firstLine)
        } else {
            currentTrack = nil
        }

        let selectionLines = lines.dropFirst()
        selectedTracks = selectionLines.compactMap { trackFromLine($0) }
    }

    private func trackFromLine(_ line: String) -> Track? {
        let parts = line.components(separatedBy: fieldDelimiter)
        guard parts.count >= 7 else { return nil }

        return Track(
            id: parts[0],
            title: parts[1],
            artist: parts[2],
            rating: Int(parts[3]) ?? 0,
            comment: parts[4],
            grouping: parts[5],
            genre: parts[6]
        )
    }

    // MARK: - Modification Logic

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

            writeBack(tracks: tracks)
        }

        if scope == .current { currentTrack = tracks.first }
        else if scope == .selection { selectedTracks = tracks }
    }

    // MARK: - Writing (via AppleScript and Music) to music file

    private func applyRating(_ rating: Int, to tracks: [Track]) {
        guard !tracks.isEmpty else { return }

        // Write by Database ID for safety
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
        runAppleScript(script)
    }

    private func writeBack(tracks: [Track]) {
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

        runAppleScript(script)
    }

    // MARK: - Helpers

    @discardableResult
    private func runAppleScript(_ source: String) -> String {
        guard let script = NSAppleScript(source: source) else { return "" }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let e = err { NSLog("AppleScript Error: \(e)"); return "" }
        return result.stringValue ?? ""
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
