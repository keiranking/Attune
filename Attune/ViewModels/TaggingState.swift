import Foundation

enum TaggingState: Equatable {
    case ready
    case writing
    case failed(String)
}
