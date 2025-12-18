import Foundation

struct Tag: Identifiable, Codable, Hashable {
    var name: String
    var category: TagCategory

    var id: String { name }
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
