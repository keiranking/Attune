import SwiftUI

@main
struct AttuneApp: App {
    @Environment(\.openWindow) private var openWindow

    private let coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            Button("AttuneApp.aboutMenuItem") { openWindow(id: "about") }

            Button("AttuneApp.toggleAttuneMenuItem") { coordinator.toggleOverlay() }

            Divider()

            SettingsLink { Text("AttuneApp.settingsMenuItem") }
                .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("AttuneApp.quitMenuItem") { NSApp.terminate(nil) }
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
