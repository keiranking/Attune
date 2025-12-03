import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("globalHotkeyKeyCode") var keyCode: Int = 49 // Space
    @AppStorage("globalHotkeyModifiers") var modifiers: Int = 131072 // Shift

    var shortcutDescription: String {
        // Todo: parse Carbon modifiers to string symbols
        return "Cmd + Shift + Space"
    }

    func updateHotkey(code: Int, mods: Int) {
        self.keyCode = code
        self.modifiers = mods
        NotificationCenter.default.post(name: .hotKeyConfigurationChanged, object: nil)
    }
}

extension Notification.Name {
    static let hotKeyConfigurationChanged = Notification.Name("hotKeyConfigurationChanged")
}
