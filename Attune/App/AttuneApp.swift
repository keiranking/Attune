import SwiftUI

@main
struct AttuneApp: App {
    private let coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            Button(.attuneAppToggleAttuneMenuItem) { coordinator.toggleOverlay() }

            Divider()

            SettingsLink { Text(.attuneAppSettingsMenuItem) }
                .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button(.attuneAppQuitMenuItem) { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(Icon.app.name).resizable()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                generalSettingsViewModel: GeneralSettingsView.ViewModel(),
                whitelistSettingsViewModel: WhitelistSettingsView.ViewModel()
            )
            .environment(AppSettings.shared)
        }
    }
}
