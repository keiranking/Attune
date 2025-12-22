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

    private let defaults = UserDefaults.standard

    private init() {
        self.enforceWhitelist = defaults.bool(forKey: StorageKey.enforceWhitelist)
    }
}

private extension AppSettings {
    enum StorageKey {
        static let enforceWhitelist = "Attune.AppSettings.enforceWhitelist"
    }
}
