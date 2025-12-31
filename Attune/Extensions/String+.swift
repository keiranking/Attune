import Foundation
import Algorithms

extension String {
    var tokenized: [String] {
        self
            .replacingOccurrences(of: ",", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { $0.validated }
            .uniqued(on: { $0.lowercased() })
    }

    var validated: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
