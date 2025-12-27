import Foundation

struct Icon {
    let name: String
    let isCustom: Bool

    init(_ name: String, isCustom: Bool = false) {
        self.name = name
        self.isCustom = isCustom
    }
}

extension Icon {
    static let success = Icon("checkmark")
    static let failure = Icon("xmark")

    static let currentPlaying = Icon("speaker.wave.2.fill")
    static let currentPaused = Icon("speaker.fill")
    static let currentDisabled = Icon("speaker.slash.fill")
    static let selected = Icon("selected", isCustom: true)

    static let updating = Icon("rays")

    static let pause = Icon("pause.fill")
    static let play = Icon("play.fill")
    static let previous = Icon("backward.fill")
    static let next = Icon("forward.fill")

    static let rated = Icon("star.fill")
    static let unrated = Icon("star")

    static let add = Icon("plus")
    static let remove = Icon("minus")
}
