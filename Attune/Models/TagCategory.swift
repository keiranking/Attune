import Foundation

enum TagCategory: String, Codable, CaseIterable, Identifiable {
    case comment = "Comments"
    case grouping = "Grouping"
    case genre = "Genre"
    case rating = "Rating"

    var id: String { self.rawValue }
}
