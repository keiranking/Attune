import Foundation

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }

    func split(by condition: (Element) -> Bool) -> (meetingCondition: [Element], notMeetingCondition: [Element]) {
        let meetingCondition = self.filter(condition)
        let notMeetingCondition = self.filter { !condition($0) }

        return (meetingCondition, notMeetingCondition)
    }

    mutating func subtract(where condition: (Element) -> Bool) -> [Element] {
        var foundElements: [Element] = []
        var remainingElements: [Element] = []

        for element in self {
            if condition(element) {
                foundElements.append(element)
            } else {
                remainingElements.append(element)
            }
        }

        self = remainingElements
        return foundElements
    }
}
