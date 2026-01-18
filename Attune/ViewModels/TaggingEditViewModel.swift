import Foundation

extension TaggingEditView {
    @Observable
    final class ViewModel {
        var text: String = ""
        var scope: Tagging.Scope?
        var mode: Tagging.Mode = .add
        var state: Tagging.State = .ready
        var outcome: Tagging.Outcome? = nil

        var currentTrack: Track?
        var selectedTracks: [Track] = []

        var selectedTrackIsCurrent: Bool { selectedTracks == [currentTrack] }

        var showSecondaryInfo: Bool = false

        var omniboxPrompt: String = ""
        var showOmniboxPrompt: Bool { AppSettings.shared.showOmniboxPrompt }
        var showAutocompletion: Bool { AppSettings.shared.showAutocompletion }

        // MARK: Current track, derived properties

        var currentTrackStatus: ScopeRowView.Status {
            if !hasCurrentTrack { .disabled }
            else { scope == .current ? .active : .inactive }
        }

        var currentTrackIcon: Icon {
            if scope == .current, let outcome {
                return outcome == .success ? Icon.success : Icon.failure
            }

            let base = hasCurrentTrack
            ? (Music.shared.player.isPlaying ? Icon.currentPlaying : Icon.currentPaused)
            : Icon.currentDisabled

            guard scope == .current else { return base }

            return state == .updating ? Icon.updating : base
        }

        var currentTrackTitle: String {
            currentTrack?.title ?? String(localized: "TaggingEditView.noCurrentTrackLabel")
        }

        private var currentTrackMetadata: String? {
            guard let currentTrack else { return nil }
            return [
                "\(currentTrack.rating)",
                currentTrack.genre,
                currentTrack.comment,
                currentTrack.grouping
            ]
                .compactMap { $0 }
                .filter { $0 != "" }
                .joined(separator: " • ")
        }
        private var currentTrackAlternateMetadata: String? {
            guard let currentTrack else { return nil }
            return [
                currentTrack.artist,
                currentTrack.album == "" ? nil : "— \(currentTrack.album)",
                currentTrack.year == 0 ? nil :"(\(currentTrack.year))"
            ]
                .compactMap { $0 }
                .filter { $0 != "" }
                .joined(separator: " ")
        }

        var currentTrackSubtitle: ScopeRowView.SubtitleContent {
            guard let currentTrack else {
                return .text(String(localized: "TaggingEditView.noCurrentTrackCaption"))
            }

            return if showSecondaryInfo {
                .text(currentTrackAlternateMetadata ?? "")
            } else {
                .label(text: currentTrackMetadata ?? "",
                       icon: currentTrack.rating == 0 ? Icon.unrated : Icon.rated)
            }
        }
        var hasCurrentTrack: Bool { currentTrack != nil }

        // MARK: Selected track, derived properties

        private var selectedTracksCount: Int { selectedTracks.count }

        var selectedTrackStatus: ScopeRowView.Status {
            if !hasSelectedTracks { .disabled }
            else { scope == .selection ? .active : .inactive }
        }

        var selectedTrackIcon: Icon {
            if scope == .selection, let outcome {
                return outcome == .success ? Icon.success : Icon.failure
            }

            let base = Icon.selected

            guard scope == .selection else { return base }

            return state == .updating ? Icon.updating : base
        }

        var selectedTrackTitle: String {
            switch selectedTracks.count {
            case 0:     String(localized: "TaggingEditView.noSelectedTracksLabel")
            case 1:     selectedTracks.first?.title ?? "\(selectedTracks.count) selected tracks"
            default:    "\(selectedTracks.count) selected tracks"
            }
        }
        private var selectedTrackMetadata: String? {
            guard let firstTrack = selectedTracks.first else { return nil }
            return [
                "\(firstTrack.rating)",
                firstTrack.genre,
                firstTrack.comment,
                firstTrack.grouping
            ]
                .compactMap { $0 }
                .filter { $0 != "" }
                .joined(separator: " • ")
        }
        private var selectedTrackAlternateMetadata: String? {
            guard let firstTrack = selectedTracks.first else { return nil }
            return [
                firstTrack.artist,
                firstTrack.album == "" ? nil : "— \(firstTrack.album)",
                firstTrack.year == 0 ? nil :"(\(firstTrack.year))"
            ]
                .compactMap { $0 }
                .filter { $0 != "" }
                .joined(separator: " ")
        }

        var selectedTrackSubtitle: ScopeRowView.SubtitleContent {
            switch selectedTracks.count {
            case 0:     .text(String(localized: "TaggingEditView.noSelectedTracksCaption"))
            case 1:     if showSecondaryInfo {
                .text(selectedTrackAlternateMetadata ?? "")
            } else {
                .label(text: selectedTrackMetadata ?? "",
                       icon: selectedTracks.first?.rating == 0 ? Icon.unrated : Icon.rated)
            }
            default:    .none
            }
        }

        var hasSelectedTracks: Bool { !selectedTracks.isEmpty }

        // MARK: Omnibox

        func generateOmniboxPrompt() -> String {
            let prefix = Bool.random(weight: 0.25) ? ["x", "s"].shuffled().first! : nil
            let comment = Tag.examples.shuffled().first(where: { $0.category == .comment })?.normalizedName
            let genre = Tag.examples.shuffled().first(where: { $0.category == .genre })?.normalizedName
            let grouping = Tag.examples.shuffled().first(where: { $0.category == .grouping })?.normalizedName
            let rating = Bool.random() ? "\(Int.random(in: Track.ratingRange))" : nil

            var keywords = [comment, genre, grouping, rating].compactMap({ $0 }).shuffled()
            keywords.removeFirst()
            if let prefix { keywords.insert(prefix, at: 0) }

            return keywords.joined(separator: " ")
        }

        func processInlineCommands() {
            let trimmed = text.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("x ") {
                mode = .remove
                text = String(trimmed.dropFirst(2))
                return
            }

            if trimmed.hasPrefix("s ") {
                scope = .selection
                text = String(trimmed.dropFirst(2))
                return
            }
        }

        // MARK: Functions

        func reset() {
            text = ""
            mode = .add
            scope = nil
            state = .ready
            omniboxPrompt = generateOmniboxPrompt()
        }

        func chooseDefaultScope() {
            if hasCurrentTrack { scope = .current }
            else if hasSelectedTracks { scope = .selection }
            else { scope = nil }
        }

        func toggleScope() {
            switch scope {
            case .current:
                hasSelectedTracks && !selectedTrackIsCurrent ? (scope = .selection) : ()
            case .selection:
                hasCurrentTrack ? (scope = .current) : ()
            case nil:
                break
            }
        }

        func toggleMode() { mode.toggle() }
    }
}
