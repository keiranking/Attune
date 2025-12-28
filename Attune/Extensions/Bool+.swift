import Foundation

extension Bool {
    static func random(weight truePercentage: Double) -> Bool {
        Double.random(in: 0.0..<1.0) < truePercentage
    }
}
