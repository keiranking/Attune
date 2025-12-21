import Cocoa
import SwiftUI

final class OverlayWindow: NSWindow {
    var hideAction: (() -> Void)?
    var arrowKeyAction: (() -> Void)?
    var optionKeyAction: ((Bool) -> Void)?

    convenience init(contentViewController: NSViewController) {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 200),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.contentViewController = contentViewController

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        hideAction?()
    }

    override func resignKey() {
        super.resignKey()
        hideAction?()
        optionKeyAction?(false)
    }

    private func isOnlyOptionKey(event: NSEvent) -> Bool {
        event.type == .flagsChanged
        && event.modifierFlags.intersection([.option, .command, .control, .shift]) == .option
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            optionKeyAction?(isOnlyOptionKey(event: event))
        }

        if event.type == .keyDown {
            switch event.keyCode {
            case 126, 125: // up/down
                arrowKeyAction?()
                return
            default:
                break
            }
        }
        super.sendEvent(event)
    }

    override func keyUp(with event: NSEvent) {
        optionKeyAction?(isOnlyOptionKey(event: event))
        super.keyUp(with: event)
    }
}
