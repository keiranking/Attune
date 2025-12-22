import Foundation

struct Tag: Identifiable, Codable, Comparable, Hashable {
    var name: String
    var category: Category

    var id: String { name }
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.normalizedName < rhs.normalizedName
    }
}

extension Tag {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case comment = "Comments"
        case grouping = "Grouping"
        case genre = "Genre"

        var id: String { self.rawValue }
    }
}
