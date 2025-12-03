import SwiftUI

@main
struct AttuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // prevents default window, but persists app lifecycle
        }
    }
}
