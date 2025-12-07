import Cocoa
import SwiftUI

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    var hideAction: (() -> Void)?

    var arrowKeyAction: (() -> Void)?
//    var tabKeyAction: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        hideAction?()
    }

    override func resignKey() {
        super.resignKey()
        hideAction?()
    }

    override func sendEvent(_ event: NSEvent) {
        enum KeyCodes {
            static let arrowUp = 126
            static let arrowDown = 125
//            static let tab = 48
        }

        if event.type == .keyDown {
            if event.keyCode == KeyCodes.arrowUp || event.keyCode == KeyCodes.arrowDown {
                arrowKeyAction?()
                return
            }
//            if event.keyCode == KeyCodes.tab {
//                tabKeyAction?()
//                return
//            }
        }

        super.sendEvent(event)
    }
}

final class OverlayWindowController {
    private var window: OverlayWindow!
    private var hosting: NSHostingController<AnyView>!

    private let overlayState = OverlayState()

    var isShown: Bool { window.isVisible }

    init() {
        let rootView = OverlayView(
            state: overlayState,
            onCommit: { [weak self] text in
                guard let self = self else { return }

                MusicTagger.shared.process(
                    command: text,
                    scope: self.overlayState.scope,
                    mode: self.overlayState.mode
                )

                self.hide()
            }
        )
        .environmentObject(TagLibrary.shared)
        .environmentObject(AppSettings.shared)

        hosting = NSHostingController(rootView: AnyView(rootView))

        // Adjusted height for new UI
        window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 200), // Taller window for list
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.hideAction = { [weak self] in
            self?.hide()
        }

        window.arrowKeyAction = { [weak self] in
            guard let self else { return }

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.overlayState.toggleScope()
                }
            }
        }

//        window.tabKeyAction = { [weak self] in
//            guard let self else { return }
//
//            DispatchQueue.main.async {
//                withAnimation(.easeInOut(duration: 0.1)) {
//                    self.overlayState.toggleMode()
//                }
//            }
//        }

        window.contentViewController = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
    }

    func show() {
        // Reset State
        overlayState.text = ""
        overlayState.mode = .add
        overlayState.scope = .current

        // Fetch Metadata
        DispatchQueue.global(qos: .userInitiated).async {
            let context = MusicTagger.shared.fetchContextState()
            DispatchQueue.main.async {
                self.overlayState.currentTrackTitle = context.currentTrackTitle
                self.overlayState.currentTrackArtist = context.currentTrackArtist
                self.overlayState.isMusicPlaying = context.isPlaying
                self.overlayState.selectionCount = context.selectionCount
            }
        }

        // Position
        if let screenFrame = NSScreen.main?.visibleFrame {
            let windowWidth = window.frame.width
            let windowHeight = window.frame.height
            let centerX = screenFrame.midX
            let x = centerX - (windowWidth / 2)
            let topPosition = screenFrame.maxY
            let twentyFivePercentDown = screenFrame.height * 0.25
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
