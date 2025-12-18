import Foundation

enum TaggingState: Equatable {
    case ready
    case updating
    case failed(String)
}
