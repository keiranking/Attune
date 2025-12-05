import Foundation
import AppKit

// MARK: - Enums for UI State
enum TaggingMode: String, CaseIterable {
    case add = "Add to"
    case remove = "Remove from"
}

enum TaggingScope: String, CaseIterable {
    case current = "Current Track"
    case selection = "Selection"
}

struct MusicContextState {
    var currentTrackTitle: String
    var currentTrackArtist: String
    var selectionCount: Int
    var isPlaying: Bool
}

final class MusicTagger {
    static let shared = MusicTagger()
    private init() {}

    var commentWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .comment) }
    var groupingWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .grouping) }
    var genreWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .genre) }
    let ratingWhitelist: Set<String> = ["0","1","2","3","4","5"]

    private let fieldDelimiter = "|||"
    private let trackDelimiter = "&&&"

    private var isMusicRunning: Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    // MARK: - Data Fetching for UI

    func fetchContextState() -> MusicContextState {
        guard isMusicRunning else {
            return MusicContextState(currentTrackTitle: "Music not running", currentTrackArtist: "", selectionCount: 0, isPlaying: false)
        }

        let script = """
        tell application id "com.apple.Music"
            set tTitle to ""
            set tArtist to ""
            set isPl to false

            if player state is playing or player state is paused then
                set t to current track
                set tTitle to name of t
                set tArtist to artist of t
                set isPl to true
            end if

            set selCount to count of items of selection

            return tTitle & "\(fieldDelimiter)" & tArtist & "\(fieldDelimiter)" & (selCount as string) & "\(fieldDelimiter)" & (isPl as string)
        end tell
        """

        let result = runAppleScript(script)
        let parts = result.components(separatedBy: fieldDelimiter)

        return MusicContextState(
            currentTrackTitle: parts[safe: 0] ?? "No Track",
            currentTrackArtist: parts[safe: 1] ?? "",
            selectionCount: Int(parts[safe: 2] ?? "0") ?? 0,
            isPlaying: (parts[safe: 3] ?? "false") == "true"
        )
    }

    // MARK: - Processing

    func process(command: String, scope: TaggingScope, mode: TaggingMode) {
        let tokens = command
            .replacingOccurrences(of: ",", with: " ")
            .split { $0.isWhitespace }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return }

        // Check for Rating (Ratings ignore Mode and just 'Set')
        // We assume the first token being a number 0-5 implies a rating command
        if let first = tokens.first, ratingWhitelist.contains(first), let ratingInt = Int(first) {
            setRatingAndBPM(value: ratingInt, forSelection: (scope == .selection))
            return
        }

        // Tagging
        switch (scope, mode) {
        case (.current, .add):
            addToCurrent(tokens: tokens)
        case (.current, .remove):
            removeFromCurrent(tokens: tokens)
        case (.selection, .add):
            applyToSelection(tokens: tokens)
        case (.selection, .remove):
            removeFromSelection(tokens: tokens)
        }
    }

    // MARK: - AppleScript Runner (Private)

    @discardableResult
    private func runAppleScript(_ source: String) -> String {
        guard isMusicRunning else { return "" }
        let robustSource = source.replacingOccurrences(of: "tell application \"Music\"", with: "tell application id \"com.apple.Music\"")
        guard let script = NSAppleScript(source: robustSource) else { return "" }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let e = err { NSLog("AppleScript runtime error: \(e)"); return "" }
        return result.stringValue ?? ""
    }

    // MARK: - Actions (Refactored)

    private func setRatingAndBPM(value: Int, forSelection: Bool) {
        let rating = value * 20
        let script: String

        if forSelection {
            script = """
            tell application id "com.apple.Music"
                repeat with t in selection
                    set rating of t to \(rating)
                    set bpm of t to \(value)
                end repeat
            end tell
            """
        } else {
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
        let escapedTokens = tokens.map{ escape($0) }.joined(separator: "\",\"")

        let script = """
        tell application id "com.apple.Music"
            set sel to selection
            set tagsToRemoveList to {"\(escapedTokens)"}

            repeat with t in sel
                set c to comment of t
                set g to grouping of t
                set ge to genre of t

                set newC to joinList(removeList(c, tagsToRemoveList))
                set newG to joinList(removeList(g, tagsToRemoveList))
                set newGE to joinList(removeList(ge, tagsToRemoveList))

                if newC is not c then set comment of t to newC
                if newG is not g then set grouping of t to newG
                if newGE is not ge then set genre of t to newGE
            end repeat
        end tell

        on removeList(oldTags, tokensToRemove)
            set newTags to {}
            set AppleScript's text item delimiters to ", "
            set oldTagList to text items of oldTags
            set AppleScript's text item delimiters to ""

            repeat with t in oldTagList
                set trimmedT to trim(t)
                set lowerTokensToRemove to {}
                repeat with token in tokensToRemove
                    set end of lowerTokensToRemove to (trim(token) as string)
                end repeat

                if (trimmedT as string) is not in lowerTokensToRemove and trimmedT is not "" then
                    set end of newTags to trimmedT
                end if
            end repeat
            return newTags
        end removeList

        on joinList(aList)
            set tid to text item delimiters
            set text item delimiters to ", "
            set t to aList as string
            set text item delimiters to tid
            return t
        end joinList
        
        on trim(theText)
            set AppleScript's text item delimiters to space
            set wordList to text items of theText
            set AppleScript's text item delimiters to ""
            return wordList as string
        end trim
        """
        runAppleScript(script)
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
            else { c.append(t) }
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
            set tags to words of curVal
            set newTags to words of "\(val)"
            set changed to false
            repeat with newTag in newTags
                if newTag is not in tags then
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
        var parts = old.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let lowerRemove = Set(remove.map { $0.lowercased() })
        parts.removeAll { lowerRemove.contains($0.lowercased()) }
        return parts.joined(separator: ", ")
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}

private extension Array { subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil } }
