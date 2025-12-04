import Cocoa
import SwiftUI

final class OverlayWindow: NSWindow {
    // Allows the borderless window to receive keyboard input
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    var hideAction: (() -> Void)?
    override func cancelOperation(_ sender: Any?) {
        hideAction?()
    }
    override func resignKey() {
        super.resignKey()
        hideAction?()
    }
}

final class OverlayWindowController {
    private var window: OverlayWindow!
    private var hosting: NSHostingController<AnyView>! // Wrapped in AnyView to erase type complexity with EnvObjs

    private let overlayState = OverlayState()

    var isShown: Bool { window.isVisible }

    init() {
        let rootView = OverlayView(
            state: overlayState,
            onCommit: { text in
                MusicTagger.shared.process(command: text)
                self.hide()
            }
        )
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

        window.hideAction = { [weak self] in
            self?.hide()
        }

        window.contentViewController = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
    }

    func show() {
        overlayState.text = ""

        if let screenFrame = NSScreen.main?.visibleFrame {
            let windowWidth = window.frame.width
            let windowHeight = window.frame.height

            let centerX = screenFrame.midX
            let x = centerX - (windowWidth / 2)

            let topPosition = screenFrame.maxY
            let twentyFivePercentDown = screenFrame.height * 0.75

            let y = topPosition - twentyFivePercentDown - windowHeight

            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }

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
