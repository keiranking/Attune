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

extension Array where Element: Identifiable, Element.ID: StringProtocol {
    var listed: String {
        compactMap(\.id).joined(separator: ", ")
    }
}

extension Array where Element: StringProtocol {
    var listed: String {
        self.joined(separator: ", ")
    }
}

extension Collection where Element: Hashable {
    func randomElements(_ count: Int) -> [Element] {
        guard count >= 0 else { return [] }

        if self.count <= count {
            return self.shuffled()
        }

        var result = Set<Element>()
        let elements = Array(self)

        while result.count < count {
            if let randomElement = elements.randomElement() {
                result.insert(randomElement)
            }
        }

        return Array(result)
    }
}
