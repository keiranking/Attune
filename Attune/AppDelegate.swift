import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayController: OverlayWindowController!
    var hotKeyManager: HotKeyManager!

    let whitelistSettingsViewModel = WhitelistSettingsView.ViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tag",
                                   accessibilityDescription: "Attune")
        }
        statusItem.menu = createMenu()

        overlayController = OverlayWindowController()

        hotKeyManager = HotKeyManager()
        let hotKey = ( // Default: Cmd+Opt+Ctrl+Space (49)
            cmd: true,
            shift: false,
            option: true,
            control: true,
            keyCode: UInt32(49)
        )
        hotKeyManager.register(hotKey: hotKey) { [weak self] in
            self?.toggleOverlay(nil)
        }
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()
        let overlayMenuItem = NSMenuItem(title: "Toggle Attune",
                                         action: #selector(toggleOverlay),
                                         keyEquivalent: " ")
        overlayMenuItem.keyEquivalentModifierMask = [.command, .option, .control]
        menu.addItem(overlayMenuItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Settings...",
                                action: nil,
                                keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Attune",
                                action: #selector(NSApp.terminate(_:)),
                                keyEquivalent: "q"))
        return menu
    }

    // MARK: - Actions

    @objc func toggleOverlay(_ sender: Any?) {
        overlayController.isShown ? overlayController.hide() : overlayController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregisterAll()
    }
}
