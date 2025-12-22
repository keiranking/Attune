import Foundation

struct Tagging {
    enum Mode: CaseIterable {
        case remove
        case add

        var systemImage: String {
            switch self {
            case .add:      Icon.add
            case .remove:   Icon.remove
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
