import SwiftUI

@main
struct AttuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                whitelistSettingsViewModel: appDelegate.whitelistSettingsViewModel
            )
            .environment(AppSettings.shared)
        }
    }
}
