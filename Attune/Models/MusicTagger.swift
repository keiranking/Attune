import Foundation
import AppKit

final class MusicTagger {
    static let shared = MusicTagger()
    private init() {}

    var commentWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .comment) }
    var groupingWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .grouping) }
    var genreWhitelist: Set<String> { TagLibrary.shared.getWhitelist(for: .genre) }
    let ratingWhitelist: Set<String> = ["0","1","2","3","4","5"]

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
        let delselCodes = ["xx"]
        let head = tokens[0]

        if ratingWhitelist.contains(head) {
            setRatingAndBPM(value: Int(head) ?? 0, forSelection: false)
            return
        }

        if selCodes.contains(head) {
            applyToSelection(tokens: Array(tokens.dropFirst()))
            return
        }

        if delselCodes.contains(head) {
            removeFromSelection(tokens: Array(tokens.dropFirst()))
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
        let target = forSelection ? "selection" : "current track"
        let condition = forSelection ? "" : "if player state is playing or player state is paused then"
        let endCondition = forSelection ? "" : "end if"

        let script: String
        if forSelection {
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
            script = """
            tell application id "com.apple.Music"
                \(condition)
                    set rating of \(target) to \(rating)
                    set bpm of \(target) to \(value)
                \(endCondition)
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
        let read = """
        tell application id "com.apple.Music"
          if player state is playing or player state is paused then
            set t to current track
            return (comment of t) & "|||" & (grouping of t) & "|||" & (genre of t)
          else
            return ""
          end if
        end tell
        """
        let combined = runAppleScript(read)
        if combined.isEmpty { return }

        let parts = combined.components(separatedBy: "|||")
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
        let (c, g, ge) = partition(tokens: tokens)
        var lines: [String] = []
        if !c.isEmpty { lines.append("set comment of t to \"\"") }
        if !g.isEmpty { lines.append("set grouping of t to \"\"") }
        if !ge.isEmpty { lines.append("set genre of t to \"\"") }
        if lines.isEmpty { return }

        let script = """
        tell application id "com.apple.Music"
            set sel to selection
            repeat with t in sel
                \(lines.joined(separator: "\n"))
            end repeat
        end tell
        """
        runAppleScript(script)
    }

    // MARK: - Utilities
    private func partition(tokens: [String]) -> ([String],[String],[String]) {
        var c:[String]=[], g:[String]=[], ge:[String]=[]

        let cList = commentWhitelist
        let gList = groupingWhitelist
        let geList = genreWhitelist

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
            lines.append("set genre of \(variable) to \"\(escape(genre.first ?? ""))\"")
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
        parts.removeAll { remove.contains(String($0)) }
        return parts.joined(separator: ", ")
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
private extension Array { subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil } }
