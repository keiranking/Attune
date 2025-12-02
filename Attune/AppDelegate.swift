import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popoverController: OverlayWindowController!
    var hotKeyManager: HotKeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Status item: Set to variableLength to allow icon resizing
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // 2. CRITICAL CHECK: Ensure the status item button was created successfully
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tag", accessibilityDescription: "MusicTagger")
            button.action = #selector(togglePopover(_:))
        } else {
            // This logs an error if the status item failed to be created (which should not happen
            // but helps diagnose)
            NSLog("ERROR: Failed to create NSStatusItem button.")
            return
        }

        // Overlay controller
        popoverController = OverlayWindowController()

        // Hotkey: register Cmd+Shift+Space in example (customize)
        hotKeyManager = HotKeyManager()
        // Spacebar key code is 49
        hotKeyManager.register(hotKey: (cmd:true, shift:true, option:false, control:false, keyCode:49)) { [weak self] in
            self?.togglePopover(nil)
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if popoverController.isShown {
            popoverController.hide()
        } else {
            // Activate the application, ignoring other apps, to ensure it's on top and can receive focus
            NSApp.activate(ignoringOtherApps: true)
            popoverController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregisterAll()
    }
}
