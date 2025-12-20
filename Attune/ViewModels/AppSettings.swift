import SwiftUI
import Combine

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var enforceWhitelists: Bool {
        didSet {
            defaults.set(enforceWhitelists, forKey: StorageKey.enforceWhitelists)
        }
    }

    private let defaults = UserDefaults.standard

    private init() {
        self.enforceWhitelists = defaults.bool(forKey: StorageKey.enforceWhitelists)
    }
}

private extension AppSettings {
    enum StorageKey {
        static let enforceWhitelists = "Attune.AppSettings.enforceWhitelists"
    }
}
