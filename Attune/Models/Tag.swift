import Foundation

struct Tag: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var category: TagCategory

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
