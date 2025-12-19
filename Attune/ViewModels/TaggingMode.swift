import Foundation

enum TaggingMode: CaseIterable {
    case remove
    case add

    var systemImage: String {
        switch self {
        case .add:      Icon.add
        case .remove:   Icon.remove
        }
    }
}
