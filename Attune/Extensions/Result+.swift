import Foundation

extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        } else {
            return false
        }
    }

    var isFailure: Bool { return !isSuccess }
}
