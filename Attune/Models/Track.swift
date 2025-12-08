import Foundation

struct Track: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    var rating: Int
    var tags: Set<Tag>

    var tagDelimiter = ", "
    var comment: String {
        tags.filter { $0.category == .comment}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }
    var grouping: String {
        tags.filter { $0.category == .grouping}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }
    var genre: String {
        tags.filter { $0.category == .genre}
            .map { $0.name }
            .sorted()
            .joined(separator: tagDelimiter)
    }

    mutating func add(tags: [Tag]) {
        self.tags.formUnion(tags)
    }

    mutating func remove(tags: [Tag]) {
        self.tags.subtract(tags)
    }

    mutating func rate(_ rating: Int) {
        self.rating = rating
    }
}
