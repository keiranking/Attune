import Foundation

struct Tagging {
    enum Mode: CaseIterable {
        case remove
        case add

        mutating func toggle() {
            self = (self == .add) ? .remove : .add
        }
    }

    enum Outcome {
        case success
        case failure
    }

    enum Scope {
        case current
        case selection
    }

    enum State {
        case ready
        case updating
    }
}
