import Foundation

enum TaggingMode: String, CaseIterable {
    case remove = "Remove from"
    case add = "Add to"

    var systemImage: String {
        switch self {
        case .add:      "plus"
        case .remove:   "minus"
        }
    }
}
