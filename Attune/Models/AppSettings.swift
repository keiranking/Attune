import SwiftUI
import Combine

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var enforceWhitelist: Bool {
        didSet {
            storage.set(enforceWhitelist, forKey: StorageKey.enforceWhitelist)
        }
    }

    var showAutocompletion: Bool {
        didSet {
            storage.set(showAutocompletion, forKey: StorageKey.showAutocompletion)
        }
    }

    var showOmniboxPrompt: Bool {
        didSet {
            storage.set(showOmniboxPrompt, forKey: StorageKey.showOmniboxPrompt)
        }
    }

    private let storage: Storable

    init(storage: Storable = UserDefaults.standard) {
        self.storage = storage

        let enforceWhitelist = storage.bool(forKey: StorageKey.enforceWhitelist) ?? false
        let showAutocompletion = storage.bool(forKey: StorageKey.showAutocompletion) ?? true
        let showOmniboxPrompt = storage.bool(forKey: StorageKey.showOmniboxPrompt) ?? true


        self.enforceWhitelist = enforceWhitelist
        self.showAutocompletion = showAutocompletion
        self.showOmniboxPrompt = showOmniboxPrompt
    }
}

extension AppSettings {
    enum StorageKey {
        static let enforceWhitelist = "Attune.AppSettings.enforceWhitelist"
        static let showAutocompletion = "Attune.AppSettings.showAutocompletion"
        static let showOmniboxPrompt = "Attune.AppSettings.showOmniboxPrompt"
    }
}

private extension Storable {
    func bool(forKey key: String) -> Bool? {
        (self as? UserDefaults)?.object(forKey: key) as? Bool
    }
}
