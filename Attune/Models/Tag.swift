import Foundation

struct Tag: Identifiable, Codable, Comparable, Hashable {
    var name: String
    var category: TagCategory

    var id: String { name }
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.normalizedName < rhs.normalizedName
    }
}
