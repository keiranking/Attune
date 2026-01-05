//
//  Extensions for testing purposes
//

import Testing
@testable import Attune

@MainActor
extension Track {
    static func mock(
        id: PersistentID = "mock-id",
        title: String = "",
        artist: String = "",
        album: String = "",
        year: Int = 0,
        rating: Int = 0,
        tags: [Attune.Tag] = []
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            year: year,
            rating: rating,
            tags: Set(tags)
        )
    }
}
