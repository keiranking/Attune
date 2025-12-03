import Cocoa
import SwiftUI

final class OverlayWindow: NSWindow {
    // Allows the borderless window to receive keyboard input
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayWindowController {
    private var window: OverlayWindow!
    private var hosting: NSHostingController<AnyView>! // Wrapped in AnyView to erase type complexity with EnvObjs

    var isShown: Bool { window.isVisible }

    init() {
        // INJECTION HAPPENS HERE:
        // We wrap the view and inject the shared objects
        let rootView = OverlayView(onCommit: { text in
            MusicTagger.shared.process(command: text)
            // We need to capture 'self' carefully; relying on the closure to callback
            // For simplicity, we can just hide via notification or closure,
            // but here we just need to know the processing happened.
        })
        .environmentObject(TagLibrary.shared)
        .environmentObject(AppSettings.shared)

        // We use AnyView simply to make the type definition cleaner in this context
        hosting = NSHostingController(rootView: AnyView(rootView))

        // Create the borderless window
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
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        focusInput()
    }

    func showBelow(rect: NSRect) {
        let screenRect = NSScreen.main?.visibleFrame ?? NSScreen.main!.frame
        let x = rect.midX - (window.frame.width / 2)
        let y = screenRect.maxY - window.frame.height - 5
        window.setFrameOrigin(NSPoint(x: x, y: y))

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        focusInput()
    }

    private func focusInput() {
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
