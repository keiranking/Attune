import Cocoa
import SwiftUI

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayWindowController {
    private var window: OverlayWindow!
    private var hosting: NSHostingController<OverlayView>!

    var isShown: Bool { window.isVisible }

    init() {
        hosting = NSHostingController(
            rootView: OverlayView(onCommit: { text in
                MusicTagger.shared.process(command: text)
                self.hide()
            })
        )

        // Set an initial size for the window
        window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 90),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
        // Removed window.center() here, as we'll position it under the menu bar icon
    }

    func show() {
        // Default show implementation (can be called if icon position isn't available)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async { [weak self] in
            guard let view = self?.hosting.view else { return }
            if let tf = self?.findTextField(in: view) {
                self?.window.makeFirstResponder(tf)
            }
        }
    }

    // NEW method to position the window below the status bar item
    func showBelow(rect: NSRect) {
        let screenRect = NSScreen.main?.visibleFrame ?? NSScreen.main!.frame

        // Calculate the window's x-position to center it horizontally under the button
        let x = rect.midX - (window.frame.width / 2)

        // Calculate the window's y-position to place it just below the menu bar
        // We use the top of the screen minus a small buffer (5 points)
        let y = screenRect.maxY - window.frame.height - 5

        // Set the new position
        window.setFrameOrigin(NSPoint(x: x, y: y))

        // Show the window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Set focus to the text field
        DispatchQueue.main.async { [weak self] in
            guard let view = self?.hosting.view else { return }
            if let tf = self?.findTextField(in: view) {
                self?.window.makeFirstResponder(tf)
            }
        }
    }

    func hide() {
        window.orderOut(nil)
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let tf = view as? NSTextField { return tf }
        for s in view.subviews {
            if let found = findTextField(in: s) {
                return found
            }
        }
        return nil
    }
}
