import Foundation

@MainActor
final class Autocompleter {
    let candidates: [String]

    init(candidates: [String]) {
        self.candidates = candidates
    }

    func complete(_ text: String) -> String? {
        guard let match = candidates
            .first(where: {
                $0.lowercased().hasPrefix(text.lowercased())
                && $0.lowercased() != text.lowercased()
            })
        else { return nil }

        return String(match.dropFirst(text.count))
    }
}
