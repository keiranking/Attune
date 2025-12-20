import Cocoa
import SwiftUI

final class TagManagerWindowController: NSObject, NSWindowDelegate {
    let viewModel = TagManagerView.ViewModel()
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

        let view = TagManagerView(
            viewModel: viewModel
        )

        window.title = "Manage Whitelists"
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.isReleasedWhenClosed = false

        window.delegate = self
    }

    func show() {
        viewModel.load()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window.performClose(nil)
    }

    func windowWillClose(_ notification: Notification) {
        viewModel.save()
    }
}
