import Foundation

struct Tagging {
    enum Mode: String, CaseIterable {
        case remove = "Remove metadata"
        case add = "Add metadata"

        var systemImage: String {
            switch self {
            case .add:      Icon.add.name
            case .remove:   Icon.remove.name
            }
        }

        var tooltip: String {
            switch self {
            case .add:      "Add metadata (⌘+)"
            case .remove:   "Remove metadata (⌘-)"
            }
        }
    }

    enum Outcome: Equatable {
        case success
        case failure
    }

    enum Scope: String, CaseIterable {
        case current = "Current Track"
        case selection = "Selection"
    }

    enum State: Equatable {
        case ready
        case updating
    }
}
