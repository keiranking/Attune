// Boundary, empty, invalid values
// Uniqueness and duplication
// Persistence round-trips

import Testing
@testable import Attune

@Suite("AppSettings unit tests")
struct AppSettingsTests {

    fileprivate let storage = TestStorage()

    @Test("Defaults are applied when storage is empty")
    func defaultsApplied() {
        let settings = AppSettings(storage: storage)

        #expect(settings.enforceWhitelist == false)
        #expect(settings.showAutocompletion == true)
        #expect(settings.showOmniboxPrompt == true)
    }

    @Test("Changing a value persists it")
    func mutationPersists() {
        let settings = AppSettings(storage: storage)

        settings.enforceWhitelist = true

        #expect(storage.bool(forKey: AppSettings.StorageKey.enforceWhitelist) == true)
    }

    @Test("Values survive reinitialization")
    func roundTrip() {
        storage.set(true, forKey: AppSettings.StorageKey.showAutocompletion)

        let settings = AppSettings(storage: storage)

        #expect(settings.showAutocompletion == true)
    }
}
