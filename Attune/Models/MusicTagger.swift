import Foundation
import AppKit

final class MusicTagger {
    static let shared = MusicTagger()
    private init() {}

    // Whitelists (Strict: unknown words are ignored)
    let commentWhitelist: Set<String> = ["action","advice","ballad","celebration","clip","ethnic","exmas","family","forgiveness","friendship","grand","heroic","island","light","lively","longing","lust","new","nostalgic","old","promise","rare","regret","religious","revenge","romantic","running","sad","secular","seduction","self","sexy","sinister","slow","society","traditional","theme"]
    let groupingWhitelist: Set<String> = ["boy","girl","vocal","group","choir","acapella","brass","chant","guitar","organ","pan","piano","perc","strings","synth","wind","whistle","solo","band","orchestra"]
    let genreWhitelist: Set<String> = ["Alternative","Broadway","Blues","Christmas","Classical","Country","Electronica","Folk","Jazz","Karaoke","Latin","OST","Personal","Pop","R&B","Rap","Reggae","Rock","Soca","Soul","Standards"]
    let ratingWhitelist: Set<String> = ["0","1","2","3","4","5"]

    // MARK: - State Check

    private var isMusicRunning: Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    // MARK: - AppleScript Runner

    @discardableResult
    private func runAppleScript(_ source: String) -> String {
        guard isMusicRunning else {
            NSLog("Music is not running. Script aborted.")
            return ""
        }

        // Use the bundle ID explicitly for robustness
        let robustSource = source.replacingOccurrences(of: "tell application \"Music\"", with: "tell application id \"com.apple.Music\"")

        NSLog("Running AppleScript:\n\(robustSource)")

        guard let script = NSAppleScript(source: robustSource) else {
            NSLog("AppleScript compile error")
            return ""
        }

        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)

        if let e = err {
            // This is where the -1743 error occurs if permission is denied
            NSLog("AppleScript runtime error: \(e)")
            return ""
        }

        return result.stringValue ?? ""
    }

    // MARK: - Command Parser

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

        // Rating
        if ratingWhitelist.contains(head) {
            setRatingAndBPM(value: Int(head) ?? 0, forSelection: false)
            return
        }

        // Selection add
        if selCodes.contains(head) {
            applyToSelection(tokens: Array(tokens.dropFirst()))
            return
        }

        // Selection remove specific tags
        if delselCodes.contains(head) {
            removeFromSelection(tokens: Array(tokens.dropFirst()))
            return
        }

        // Delete from current
        if delCodes.contains(head) {
            removeFromCurrent(tokens: Array(tokens.dropFirst()))
            return
        }

        // Default: add tags to current
        addToCurrent(tokens: tokens)
    }

    // MARK: - Actions

    private func setRatingAndBPM(value: Int, forSelection: Bool) {
        let rating = value * 20

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
                if player state is playing or player state is paused then
                    set rating of current track to \(rating)
                    set bpm of current track to \(value)
                end if
            end tell
            """
        }
        runAppleScript(script)
    }

    // MARK: - Current Track Logic (Read-Modify-Write)

    private func addToCurrent(tokens: [String]) {
        let (comment, grouping, genre) = partition(tokens: tokens)
        if comment.isEmpty && grouping.isEmpty && genre.isEmpty { return }

        let script = buildMergeScript(target: "current track", comment: comment, grouping: grouping, genre: genre)
        runAppleScript(script)
    }

    private func removeFromCurrent(tokens: [String]) {
        // Read current tags from Music
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

        // Swift-side processing to remove tokens
        let parts = combined.components(separatedBy: "|||")
        let c = removeList(old: parts[safe: 0] ?? "", remove: tokens)
        let g = removeList(old: parts[safe: 1] ?? "", remove: tokens)
        let ge = removeList(old: parts[safe: 2] ?? "", remove: tokens)

        // Write back the modified tags
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

    // MARK: - Selection Logic (Batch Processing)

    private func applyToSelection(tokens: [String]) {
        let (comment, grouping, genre) = partition(tokens: tokens)
        if comment.isEmpty && grouping.isEmpty && genre.isEmpty { return }

        // Generates a script that iterates over selection and merges tags
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
        // Simple 'xx' implementation: wipe fields that match the types of tokens provided.

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

    // MARK: - AppleScript Builders

    // Builds a block of AppleScript that reads a field, checks if new tags exist, and appends them.
    private func buildMergeBlock(variable: String, comment: [String], grouping: [String], genre: [String]) -> String {
        var lines: [String] = []

        if !comment.isEmpty {
            let tags = comment.joined(separator: ", ")
            lines.append(mergeFieldScript(obj: variable, prop: "comment", newVal: tags))
        }
        if !grouping.isEmpty {
            let tags = grouping.joined(separator: ", ")
            lines.append(mergeFieldScript(obj: variable, prop: "grouping", newVal: tags))
        }
        if !genre.isEmpty {
            // Genre is typically a single, primary tag, so we overwrite.
            let tag = genre.first ?? ""
            lines.append("set genre of \(variable) to \"\(escape(tag))\"")
        }
        return lines.joined(separator: "\n")
    }

    private func mergeFieldScript(obj: String, prop: String, newVal: String) -> String {
        // AppleScript helper to append if not present
        let val = escape(newVal)
        return """
        set curVal to \(prop) of \(obj)
        if curVal is "" then
            set \(prop) of \(obj) to "\(val)"
        else
            -- Check for exact match of comma-separated tags and append if new
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

    // MARK: - Utilities

    private func partition(tokens: [String]) -> ([String],[String],[String]) {
        var c:[String]=[], g:[String]=[], ge:[String]=[]
        for t in tokens {
            if commentWhitelist.contains(t) { c.append(t) }
            else if groupingWhitelist.contains(t) { g.append(t) }
            else if genreWhitelist.contains(t) { ge.append(t) }
            else {
                // Fallback: If unknown, treat as comment
                c.append(t)
            }
        }
        return (c,g,ge)
    }

    private func removeList(old: String, remove: [String]) -> String {
        var parts = old
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        parts.removeAll { remove.contains(String($0)) }
        return parts.joined(separator: ", ")
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// safe index helper
private extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
