import Foundation

struct Tag: Identifiable, Codable, Comparable, CustomStringConvertible, Hashable {
    var name: String
    var category: Category

    var id: String { name }
    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var description: String { name }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.normalizedName < rhs.normalizedName
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
            "action", "advice", "ballad", "celebration", "clip", "ethnic", "exmas",
            "family", "forgiveness", "friendship", "grand", "heroic", "island", "light",
            "lively", "longing", "lust", "new", "nostalgic", "old", "promise", "rare",
            "regret", "religious", "revenge", "romantic", "running", "sad", "secular",
            "seduction", "self", "sexy", "sinister", "slow", "society", "traditional",
            "theme"
        ].compactMap { Tag($0, category: .comment) }

        let groupings = [
            "boy", "girl", "vocal", "group", "choir", "acapella", "brass", "chant",
            "guitar", "organ", "pan", "piano", "perc", "strings", "synth", "wind",
            "whistle", "solo", "band", "orchestra"
        ].compactMap { Tag($0, category: .grouping) }

        let genres = [
            "Alternative", "Broadway", "Blues", "Christmas", "Classical", "Country",
            "Electronica", "Folk", "Jazz", "Karaoke", "Latin", "OST", "Personal", "Pop",
            "R&B", "Rap", "Reggae", "Rock", "Soca", "Soul", "Standards"
        ].compactMap { Tag($0, category: .genre) }

        return (comments + groupings + genres).sorted { $0.name < $1.name }
    }
}
