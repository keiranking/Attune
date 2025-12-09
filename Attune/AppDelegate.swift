import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayController: OverlayWindowController!
    var hotKeyManager: HotKeyManager!

    var tagManagerWindow: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tag",
                                   accessibilityDescription: "Attune")
        }
        statusItem.menu = createMenu()

        overlayController = OverlayWindowController()

        hotKeyManager = HotKeyManager()
        let hotKey = ( // Default: Cmd+Shift+Space (49)
            cmd: true,
            shift: true,
            option: false,
            control: false,
            keyCode: UInt32(49)
        )
        hotKeyManager.register(hotKey: hotKey) { [weak self] in
            self?.toggleOverlay(nil)
        }
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Attune",
                                action: #selector(toggleOverlay),
                                keyEquivalent: "t"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Manage Tags...",
                                action: #selector(openTagManager),
                                keyEquivalent: ","))

        menu.addItem(NSMenuItem(title: "Preferences...",
                                action: #selector(openSettings),
                                keyEquivalent: ";"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Attune",
                                action: #selector(NSApp.terminate(_:)),
                                keyEquivalent: "q"))
        return menu
    }

    // MARK: - Actions

    @objc func toggleOverlay(_ sender: Any?) {
        if overlayController.isShown {
            overlayController.hide()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            overlayController.show()
        }
    }

    @objc func openTagManager() {
        if tagManagerWindow == nil {
            let contentView = TagManagerView()
                .environmentObject(TagLibrary.shared)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = "Manage Tags"
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            window.isReleasedWhenClosed = false
            tagManagerWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        tagManagerWindow?.makeKeyAndOrderFront(nil)
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

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregisterAll()
    }
}
