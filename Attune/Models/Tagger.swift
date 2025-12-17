import Foundation
import AppKit

extension Music {
    struct Tagger {
        private let fieldDelimiter = "|||"
        private let lineDelimiter = "&&&"

        func readSelection() -> [Track] {
            let script = """
            tell application id "com.apple.Music"
                set out to ""
                repeat with t in selection
                    set out to out & (persistent id of t) & "\(fieldDelimiter)" & (name of t) & "\(fieldDelimiter)" & (artist of t) & "\(fieldDelimiter)" & (rating of t) & "\(fieldDelimiter)" & (comment of t) & "\(fieldDelimiter)" & (grouping of t) & "\(fieldDelimiter)" & (genre of t) & "\(lineDelimiter)"
                end repeat
                return out
            end tell
            """
            return parseSelection(Music.shared.run(script))
        }

        func process(command: String, scope: TaggingScope?, mode: TaggingMode) async {
            Music.shared.refresh()

            var tokens = command
                .replacingOccurrences(of: ",", with: " ")
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)

            let ratings = tokens
                .subtract(where: { Track.ratingRange.contains(Int($0) ?? -1) })
                .map({ Int($0)! })

            let tracks: [Track] =
                scope == .current ? Music.shared.currentTrack.map { [$0] } ?? [] :
                scope == .selection ? Music.shared.selectedTracks : []

            guard !tracks.isEmpty else { return }

            if let rating = ratings.last {
                applyRating(rating, to: tracks)
            }

            guard !tokens.isEmpty else { return }

            var mutated = tracks
            for i in mutated.indices {
                mode == .add
                ? mutated[i].add(tokens: tokens)
                : mutated[i].remove(tokens: tokens)
            }
            writeMetadata(mutated)
        }

        // MARK: - Private

        private func applyRating(_ rating: Int, to tracks: [Track]) {
            let ids = tracks.map { "\"\($0.id)\"" }.joined(separator: ",")
            let script = """
            tell application id "com.apple.Music"
                repeat with pid in {\(ids)}
                    set bpm of (some track whose persistent id is pid) to \(rating)
                    set rating of (some track whose persistent id is pid) to \(rating * 20)
                end repeat
            end tell
            """
            Music.shared.run(script)
        }

        private func writeMetadata(_ tracks: [Track]) {
            let rows = tracks.map {
                "{\"\($0.id)\",\"\(escape($0.comment))\",\"\(escape($0.grouping))\",\"\(escape($0.genre))\"}"
            }.joined(separator: ",")

            let script = """
            tell application id "com.apple.Music"
                repeat with r in {\(rows)}
                    set t to (some track whose persistent id is item 1 of r)
                    set comment of t to item 2 of r
                    set grouping of t to item 3 of r
                    set genre of t to item 4 of r
                end repeat
            end tell
            """
            Music.shared.run(script)
        }

        private func parseSelection(_ s: String) -> [Track] {
            s.components(separatedBy: lineDelimiter)
             .filter { !$0.isEmpty }
             .compactMap {
                 let p = $0.components(separatedBy: fieldDelimiter)
                 guard p.count == 7 else { return nil }
                 return Track(
                     id: p[0], title: p[1], artist: p[2],
                     rating: Int(p[3]) ?? 0,
                     comment: p[4], grouping: p[5], genre: p[6]
                 )
             }
        }

        private func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "\"", with: "\\\"")
        }
    }
}
