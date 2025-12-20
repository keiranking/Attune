import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayController: OverlayWindowController!
    var hotKeyManager: HotKeyManager!

    var tagManagerController: TagManagerWindowController!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tag",
                                   accessibilityDescription: "Attune")
        }
        statusItem.menu = createMenu()

        overlayController = OverlayWindowController()
        tagManagerController = TagManagerWindowController()

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

        menu.addItem(NSMenuItem(title: "Manage Whitelists...",
                                action: #selector(openTagManager),
                                keyEquivalent: ""))

        menu.addItem(NSMenuItem(title: "Preferences...",
                                action: #selector(openSettings),
                                keyEquivalent: ""))

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

    @objc func openTagManager() {
        tagManagerController.show()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
                .environmentObject(AppSettings.shared)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false
            )
            window.title = "Preferences"
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregisterAll()
    }
}
