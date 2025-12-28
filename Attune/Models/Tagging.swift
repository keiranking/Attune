import Foundation

struct Tagging {
    enum Mode: CaseIterable {
        case remove
        case add

        mutating func toggle() {
            self = (self == .add) ? .remove : .add
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
