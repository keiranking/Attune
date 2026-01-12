import SwiftUI

@main
struct AttuneApp: App {
    @Environment(\.openWindow) private var openWindow

    private let coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            Button(.attuneAppAboutMenuItem) { openWindow(id: "about") }

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

        Window("", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
