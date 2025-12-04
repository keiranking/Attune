import Foundation
import AppKit

final class MusicTagger {
    static let shared = MusicTagger()
    private init() {}

    var commentWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .comment) }
    var groupingWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .grouping) }
    var genreWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .genre) }
    let ratingWhitelist: Set<String> = ["0","1","2","3","4","5"]

    // Delimiters for reading/writing multiple fields/tracks via AppleScript
    private let fieldDelimiter = "|||"
    private let trackDelimiter = "&&&"

    private var isMusicRunning: Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String {
        guard isMusicRunning else {
            NSLog("Music is not running. Script aborted.")
            return ""
        }

        let robustSource = source.replacingOccurrences(of: "tell application \"Music\"", with: "tell application id \"com.apple.Music\"")

        guard let script = NSAppleScript(source: robustSource) else { return "" }

        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let e = err { NSLog("AppleScript runtime error: \(e)"); return "" }

        return result.stringValue ?? ""
    }

    func process(command: String) {
        let tokens = command
            .replacingOccurrences(of: ",", with: " ")
            .split { $0.isWhitespace }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return }

        let selCodes = ["s"]
        let delCodes = ["x"]
        let delselCodes = ["xx"] // Retaining original "xx" for remove-from-selection
        let head = tokens[0].lowercased()

        if selCodes.contains(head) {
            let subTokens = Array(tokens.dropFirst())

            if let ratingValue = subTokens.first, ratingWhitelist.contains(ratingValue) {
                if let ratingInt = Int(ratingValue) {
                    setRatingAndBPM(value: ratingInt, forSelection: true)
                }
                return
            }

            applyToSelection(tokens: subTokens)
            return
        }

        if delselCodes.contains(head) {
            removeFromSelection(tokens: Array(tokens.dropFirst()))
            return
        }

        if ratingWhitelist.contains(head) {
            if let ratingInt = Int(head) {
                setRatingAndBPM(value: ratingInt, forSelection: false)
            }
            return
        }

        if delCodes.contains(head) {
            removeFromCurrent(tokens: Array(tokens.dropFirst()))
            return
        }

        addToCurrent(tokens: tokens)
    }

    // MARK: - Actions

    private func setRatingAndBPM(value: Int, forSelection: Bool) {
        let rating = value * 20

        let script: String
        if forSelection {
            // Apply rating and BPM to selection
            script = """
            tell application id "com.apple.Music"
                set sel to selection
                repeat with t in sel
                    set rating of t to \(rating)
                    set bpm of t to \(value)
                end repeat
            end tell
            """
        } else {
            // Apply rating and BPM to current track (only if playing/paused)
            script = """
            tell application id "com.apple.Music"
                if player state is playing or player state is paused then
                    set rating of current track to \(rating)
                    set bpm of current track to \(value)
                end if
            end tell
            """
        }
        runAppleScript(script)
    }

    private func addToCurrent(tokens: [String]) {
        let (comment, grouping, genre) = partition(tokens: tokens)
        if comment.isEmpty && grouping.isEmpty && genre.isEmpty { return }
        runAppleScript(buildMergeScript(target: "current track", comment: comment, grouping: grouping, genre: genre))
    }

    private func removeFromCurrent(tokens: [String]) {
        guard !tokens.isEmpty else { return }

        let read = """
        tell application id "com.apple.Music"
          if player state is playing or player state is paused then
            set t to current track
            return (comment of t as string) & "\(fieldDelimiter)" & (grouping of t as string) & "\(fieldDelimiter)" & (genre of t as string)
          else
            return ""
          end if
        end tell
        """
        let combined = runAppleScript(read)
        if combined.isEmpty { return }

        let parts = combined.components(separatedBy: fieldDelimiter)

        let c = removeList(old: parts[safe: 0] ?? "", remove: tokens)
        let g = removeList(old: parts[safe: 1] ?? "", remove: tokens)
        let ge = removeList(old: parts[safe: 2] ?? "", remove: tokens)

        let write = """
        tell application id "com.apple.Music"
          if player state is playing or player state is paused then
            set t to current track
            set comment of t to "\(escape(c))"
            set grouping of t to "\(escape(g))"
            set genre of t to "\(escape(ge))"
          end if
        end tell
        """
        runAppleScript(write)
    }

    private func applyToSelection(tokens: [String]) {
        let (comment, grouping, genre) = partition(tokens: tokens)
        if comment.isEmpty && grouping.isEmpty && genre.isEmpty { return }

        let script = """
        tell application id "com.apple.Music"
            set sel to selection
            repeat with t in sel
                \(buildMergeBlock(variable: "t", comment: comment, grouping: grouping, genre: genre))
            end repeat
        end tell
        """
        runAppleScript(script)
    }

    private func removeFromSelection(tokens: [String]) {
        guard !tokens.isEmpty else { return }

        let readScript = """
        tell application id "com.apple.Music"
            set trackDataList to {}
            set sel to selection
            repeat with t in sel
                -- Read comment, grouping, and genre, separated by \(fieldDelimiter)
                set c to (comment of t as string)
                set g to (grouping of t as string)
                set ge to (genre of t as string)

                -- Combine fields for one track
                set trackRecord to c & "\(fieldDelimiter)" & g & "\(fieldDelimiter)" & ge
                set end of trackDataList to trackRecord
            end repeat

            -- Combine all track records with \(trackDelimiter) separator
            set AppleScript's text item delimiters to "\(trackDelimiter)"
            set allData to trackDataList as string
            set AppleScript's text item delimiters to ""

            return allData
        end tell
        """
        let allData = runAppleScript(readScript)
        if allData.isEmpty { return }

        let trackRecords = allData.components(separatedBy: trackDelimiter)
        var newTrackData: [(c: String, g: String, ge: String)] = []

        for record in trackRecords {
            let parts = record.components(separatedBy: fieldDelimiter)

            guard parts.count >= 3 else {
                NSLog("Error: Track record did not have 3 fields: \(record)")
                continue
            }

            let oldC = parts[safe: 0] ?? ""
            let oldG = parts[safe: 1] ?? ""
            let oldGE = parts[safe: 2] ?? ""

            let newC = removeList(old: oldC, remove: tokens)
            let newG = removeList(old: oldG, remove: tokens)
            let newGE = removeList(old: oldGE, remove: tokens)

            newTrackData.append((c: newC, g: newG, ge: newGE))
        }

        var writeScriptLines: [String] = []

        writeScriptLines.append("tell application id \"com.apple.Music\"")
        writeScriptLines.append("  set sel to selection")

        for (i, data) in newTrackData.enumerated() {
            let trackIndex = i + 1 // AppleScript index is 1-based, so use i + 1
            let newC = escape(data.c)
            let newG = escape(data.g)
            let newGE = escape(data.ge)

            writeScriptLines.append("  -- Track \(trackIndex)")
            writeScriptLines.append("  set t to item \(trackIndex) of sel")
            writeScriptLines.append("  set comment of t to \"\(newC)\"")
            writeScriptLines.append("  set grouping of t to \"\(newG)\"")
            writeScriptLines.append("  set genre of t to \"\(newGE)\"")
        }

        writeScriptLines.append("end tell")

        runAppleScript(writeScriptLines.joined(separator: "\n"))
    }

    // MARK: - Utilities
    private func partition(tokens: [String]) -> ([String],[String],[String]) {
        var c:[String]=[], g:[String]=[], ge:[String]=[]

        let cList = commentWhitelist.map { $0.lowercased() }
        let gList = groupingWhitelist.map { $0.lowercased() }
        let geList = genreWhitelist.map { $0.lowercased() }

        for t in tokens {
            let lowerT = t.lowercased()

            if cList.contains(lowerT) { c.append(t) }
            else if gList.contains(lowerT) { g.append(t) }
            else if geList.contains(lowerT) { ge.append(t) }
            else { c.append(t) } // fallback
        }
        return (c,g,ge)
    }

    private func buildMergeBlock(variable: String, comment: [String], grouping: [String], genre: [String]) -> String {
        var lines: [String] = []
        if !comment.isEmpty {
            lines.append(mergeFieldScript(obj: variable, prop: "comment", newVal: comment.joined(separator: ", ")))
        }
        if !grouping.isEmpty {
            lines.append(mergeFieldScript(obj: variable, prop: "grouping", newVal: grouping.joined(separator: ", ")))
        }

        if !genre.isEmpty {
            lines.append(mergeFieldScript(obj: variable, prop: "genre", newVal: genre.joined(separator: ", ")))
        }
        return lines.joined(separator: "\n")
    }

    private func mergeFieldScript(obj: String, prop: String, newVal: String) -> String {
        let val = escape(newVal)
        return """
        set curVal to \(prop) of \(obj)
        if curVal is "" then
            set \(prop) of \(obj) to "\(val)"
        else
            -- Use AppleScript's built-in words parser, which separates by whitespace
            set tags to words of curVal
            set newTags to words of "\(val)"
            set changed to false
            repeat with newTag in newTags
                if newTag is not in tags then
                    -- Append new tag separated by a comma and space
                    set curVal to curVal & ", " & newTag
                    set changed to true
                end if
            end repeat
            if changed is true then
                set \(prop) of \(obj) to curVal
            end if
        end if
        """
    }

    private func buildMergeScript(target: String, comment: [String], grouping: [String], genre: [String]) -> String {
        let condition = target == "current track" ? "if player state is playing or player state is paused then" : ""
        let endCondition = target == "current track" ? "end if" : ""
        return """
        tell application id "com.apple.Music"
            \(condition)
                set t to \(target)
                \(buildMergeBlock(variable: "t", comment: comment, grouping: grouping, genre: genre))
            \(endCondition)
        end tell
        """
    }

    private func removeList(old: String, remove: [String]) -> String {
        var parts = old.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let lowerRemove = Set(remove.map { $0.lowercased() })

        parts.removeAll { lowerRemove.contains($0.lowercased()) }

        return parts.joined(separator: ", ")
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}

private extension Array { subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil } }
