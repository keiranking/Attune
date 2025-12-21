import Cocoa
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    let whitelistSettingsViewModel = WhitelistSettingsView.ViewModel()
    let window: NSWindow

    var isShown: Bool { window.isVisible }

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        super.init()

        let view = WhitelistSettingsView(
            viewModel: whitelistSettingsViewModel
        )

        window.title = "Manage Whitelist"
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.isReleasedWhenClosed = false

        window.delegate = self
    }

    func show() {
        whitelistSettingsViewModel.load()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window.performClose(nil)
    }

    func windowWillClose(_ notification: Notification) {
        whitelistSettingsViewModel.save()
    }
}
