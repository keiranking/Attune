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
                    set out to out & (persistent id of t) & "\(fieldDelimiter)" & (name of t) & "\(fieldDelimiter)" & (artist of t) & "\(fieldDelimiter)" & (album of t) & "\(fieldDelimiter)" & (year of t) & "\(fieldDelimiter)" & (rating of t) & "\(fieldDelimiter)" & (comment of t) & "\(fieldDelimiter)" & (grouping of t) & "\(fieldDelimiter)" & (genre of t) & "\(lineDelimiter)"
                end repeat
                return out
            end tell
            """
            return parseSelection(Music.shared.run(script))
        }

        func process(
            command: String,
            scope: Tagging.Scope?,
            mode: Tagging.Mode
        ) async -> Result<Void, Tagger.Error> {

            Music.shared.refresh()

            var tokens = command.tokenized

            let ratings = tokens
                .subtract(where: { Track.ratingRange.contains(Int($0) ?? -1) })
                .map({ Int($0)! })

            let tracks: [Track] =
            switch scope {
            case .current:      Music.shared.currentTrack.map { [$0] } ?? []
            case .selection:    Music.shared.selectedTracks
            default:            []
            }

            guard !tracks.isEmpty else { return .failure(.noTarget) }

            var mutated = tracks

            if let rating = ratings.last {
                for i in mutated.indices { mutated[i].rate(rating) }
                writeRating(mutated)
            }

            if !tokens.isEmpty {
                for i in mutated.indices {
                    if mode == .remove {
                        mutated[i].remove(tokens: tokens)
                    } else {
                        let tags = if AppSettings.shared.enforceWhitelist {
                            Whitelist.shared.tags.filter { tag in
                                tokens
                                    .map { $0.lowercased() }
                                    .contains(tag.normalizedName)
                            }
                        } else {
                            Tag.array(from: tokens.listed, as: .comment)
                        }

                        mutated[i].add(tags: tags)
                    }
                }
                writeMetadata(mutated)
            }

            return await verify(expected: mutated, scope: scope)
        }

        // MARK: - Private

        private func writeRating(_ tracks: [Track]) {
            guard let rating = tracks.first?.rating else { return }

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

        private func parseSelection(_ string: String) -> [Track] {
            string
                .components(separatedBy: lineDelimiter)
                .filter { !$0.isEmpty }
                .compactMap {
                    let p = $0.components(separatedBy: fieldDelimiter)
                    guard p.count == 9 else { return nil }
                    return Track(
                        id:         p[0],
                        title:      p[1],
                        artist:     p[2],
                        album:      p[3],
                        year:       Int(p[4]) ?? 0,
                        rating:     (Int(p[5]) ?? 0) / 20,
                        comment:    p[6],
                        grouping:   p[7],
                        genre:      p[8]
                    )
                }
        }

        private func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
        }

        private func verify(
            expected: [Track],
            scope: Tagging.Scope?
        ) async -> Result<Void, Tagger.Error> {

            let expectedByID = Dictionary(
                uniqueKeysWithValues: expected.map { ($0.id, $0) }
            )

            let sleepTime: Duration = .milliseconds(100)
            let timeOutTime: Duration = .milliseconds(1000)
            let deadline = ContinuousClock.now + timeOutTime

            while ContinuousClock.now < deadline {
                Music.shared.refresh()

                let actual: [Track] =
                    switch scope {
                    case .current:      Music.shared.currentTrack.map { [$0] } ?? []
                    case .selection:    Music.shared.selectedTracks
                    default :           []
                    }

                guard actual.count == expectedByID.count else {
                    try? await Task.sleep(for: sleepTime)
                    continue
                }

                let matches = actual.allSatisfy { expectedByID[$0.id] == $0 }
                if matches { return .success(()) }

                try? await Task.sleep(for: sleepTime)
            }

            return .failure(.timedOut)
        }

        enum Error: Swift.Error {
            case noTarget
            case timedOut
        }
    }
}
