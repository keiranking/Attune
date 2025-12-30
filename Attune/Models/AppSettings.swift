import SwiftUI
import Combine

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var enforceWhitelist: Bool {
        didSet {
            defaults.set(enforceWhitelist, forKey: StorageKey.enforceWhitelist)
        }
    }

    var showAutocompletion: Bool {
        didSet {
            defaults.set(showAutocompletion, forKey: StorageKey.showAutocompletion)
        }
    }

    var showOmniboxPrompt: Bool {
        didSet {
            defaults.set(showOmniboxPrompt, forKey: StorageKey.showOmniboxPrompt)
        }
    }

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            StorageKey.enforceWhitelist: false,
            StorageKey.showAutocompletion: true,
            StorageKey.showOmniboxPrompt: true
        ])

        self.enforceWhitelist = defaults.bool(forKey: StorageKey.enforceWhitelist)
        self.showAutocompletion = defaults.bool(forKey: StorageKey.showAutocompletion)
        self.showOmniboxPrompt = defaults.bool(forKey: StorageKey.showOmniboxPrompt)
    }
}

private extension AppSettings {
    enum StorageKey {
        static let enforceWhitelist = "Attune.AppSettings.enforceWhitelist"
        static let showAutocompletion = "Attune.AppSettings.showAutocompletion"
        static let showOmniboxPrompt = "Attune.AppSettings.showOmniboxPrompt"
    }
}
