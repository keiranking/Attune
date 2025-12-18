import Foundation

extension Result {
    var isSuccess: Bool {
        if case .success = self { true } else { false }
    }

    var isFailure: Bool { return !isSuccess }
}
