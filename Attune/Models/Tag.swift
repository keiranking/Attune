import Foundation

struct Tag: Identifiable, Codable, Comparable, CustomStringConvertible, Equatable, Hashable {
    var name: String
    var category: Category

    var id: String { name }
    var normalizedName: String { name.lowercased() }

    var description: String { name }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.normalizedName < rhs.normalizedName
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.normalizedName == rhs.normalizedName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(normalizedName)
    }

    init?(_ name: String, category: Category = .comment) {
        guard let validName = name.validated else { return nil }

        self.name = validName
        self.category = category
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

extension Tag {
    static func array(from string: String, as category: Category) -> [Tag] {
        string.tokenized.sorted().compactMap { Tag(String($0), category: category) }
    }
}

extension Tag {
    static var examples: [Tag] {
        let comments = [
            "defiant", "dramatic", "driving", "experimental", "grand", "happy",
            "haunting", "heavy", "heroic", "intense", "light", "lively",
            "nostalgic", "rare", "sad", "sexy", "sinister", "slow",
            "traditional", "uplifting"
        ].compactMap { Tag($0, category: .comment) }

        let groupings = [
            "acapella", "acoustic", "band", "brass", "chant", "choir", "female",
            "group", "guitar", "male", "orchestra", "organ", "percussion",
            "piano", "solo", "strings", "synth", "whistle", "wind", "vocal"
        ].compactMap { Tag($0, category: .grouping) }

        let genres = [
            "Afrobeat", "Alternative", "Broadway", "Blues", "Classical",
            "Country", "Electronica", "Folk", "Jazz", "Latin", "Metal", "Pop",
            "R&B", "Rap", "Reggae", "Rock", "Soca", "Soul", "Soundtracks",
            "Standards"
        ].compactMap { Tag($0, category: .genre) }

        return (comments + groupings + genres).sorted { $0.name < $1.name }
    }
}
