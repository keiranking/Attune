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

extension Tag {
    static var examples: [Tag] {
        let comments = [
            "action", "advice", "ballad", "celebration", "clip", "ethnic", "exmas",
            "family", "forgiveness", "friendship", "grand", "heroic", "island", "light",
            "lively", "longing", "lust", "new", "nostalgic", "old", "promise", "rare",
            "regret", "religious", "revenge", "romantic", "running", "sad", "secular",
            "seduction", "self", "sexy", "sinister", "slow", "society", "traditional",
            "theme"
        ]
        let groupings = [
            "boy", "girl", "vocal", "group", "choir", "acapella", "brass", "chant",
            "guitar", "organ", "pan", "piano", "perc", "strings", "synth", "wind",
            "whistle", "solo", "band", "orchestra"
        ]
        let genres = [
            "Alternative", "Broadway", "Blues", "Christmas", "Classical", "Country",
            "Electronica", "Folk", "Jazz", "Karaoke", "Latin", "OST", "Personal", "Pop",
            "R&B", "Rap", "Reggae", "Rock", "Soca", "Soul", "Standards"
        ]

        return [
            comments.map    { .init(name: $0, category: .comment) },
            groupings.map   { .init(name: $0, category: .grouping) },
            genres.map      { .init(name: $0, category: .genre) }
        ]
        .flatMap { $0 }
        .sorted { $0.name < $1.name }
    }
}
