import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleOverlay = Self("Attune.KeyboardShortcuts.toggleOverlay")
}

@main
struct AttuneApp: App {
    @State private var viewModel = ViewModel()

    var body: some Scene {
        MenuBarExtra {
            Button("Toggle Attune") {
                viewModel.toggleOverlay()
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Attune") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)

        } label: {
            Image("attune")
                .resizable()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                whitelistSettingsViewModel: WhitelistSettingsView.ViewModel()
            )
            .environment(AppSettings.shared)
        }
    }

    func setupDefaultHotkey() {
        if KeyboardShortcuts.getShortcut(for: .toggleOverlay) == nil {
            KeyboardShortcuts.setShortcut(
                .init(.space, modifiers: [.command, .option, .control]),
                for: .toggleOverlay
            )
        }
    }

    init() {
        setupDefaultHotkey()
    }
}

extension AttuneApp {
    @Observable
    final class ViewModel {
        var isOverlayPresented: Bool = false
        let overlayViewModel = OverlayViewModel()

        private var overlayWindow: OverlayWindow?
        private var hotKeyManager: HotKeyManager?
        private let music = Music.shared

        private var priorApplication: NSRunningApplication?

        init() {
            setupOverlayWindow()
            setupHotkey()

            music.onChange = { [weak self] in self?.sync() }
        }

        // MARK: - Setup

        private func setupHotkey() {
            KeyboardShortcuts.onKeyUp(for: .toggleOverlay) { [weak self] in
                Task { @MainActor in
                    self?.toggleOverlay()
                }
            }
        }

        private func setupOverlayWindow() {
            let rootView = OverlayView(
                viewModel: overlayViewModel,
                onSubmit: { [weak self] text, dismiss in
                    self?.submit(text, dismiss)
                }
            )
                .environment(AppSettings.shared)
                .environment(music)

            let hostingController = NSHostingController(rootView: rootView)
            hostingController.view.layer?.backgroundColor = .clear

            let window = OverlayWindow(contentViewController: hostingController)

            window.hideAction = { [weak self] in
                self?.hideOverlay()
            }

            window.arrowKeyAction = { [weak self] in
                withAnimation(.easeInOut(duration: 0.1)) {
                    self?.overlayViewModel.toggleScope()
                }
            }

            window.optionKeyAction = { [weak self] isOptionDown in
                withAnimation(.easeInOut(duration: 0.1)) {
                    self?.overlayViewModel.showSecondaryInfo = isOptionDown
                }
            }

            self.overlayWindow = window
        }

        // MARK: - Actions

        func toggleOverlay() {
            isOverlayPresented ? hideOverlay() : showOverlay()
        }

        private func showOverlay() {
            guard let window = overlayWindow else { return }

            overlayViewModel.reset()
            sync()

            if let screenFrame = NSScreen.main?.visibleFrame {
                let x = screenFrame.midX - window.frame.width / 2
                let y = screenFrame.maxY - screenFrame.height * 0.15 - window.frame.height
                window.setFrameOrigin(NSPoint(x: x, y: y))
            } else {
                window.center()
            }

            priorApplication = NSWorkspace.shared.frontmostApplication
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            isOverlayPresented = true

            window.makeFirstResponder(window.contentViewController?.view.firstTextField)
        }

        private func hideOverlay() {
            guard let window = overlayWindow else { return }
            window.orderOut(nil)
            isOverlayPresented = false

            if let priorApplication {
                priorApplication.activate()
                self.priorApplication = nil
            } else {
                NSApp.deactivate()
            }
        }

        private func sync() {
            music.refresh()

            overlayViewModel.currentTrack = music.currentTrack
            overlayViewModel.selectedTracks = music.selectedTracks

            if overlayViewModel.scope == nil {
                overlayViewModel.chooseDefaultScope()
            }
        }

        private func submit(_ text: String, _ dismiss: Bool) {
            Task {
                await MainActor.run {
                    overlayViewModel.state = .updating
                    overlayViewModel.outcome = nil
                }

                let result = await music.tagger.process(
                    command: text,
                    scope: overlayViewModel.scope,
                    mode: overlayViewModel.mode
                )

                await MainActor.run {
                    overlayViewModel.state = .ready
                    overlayViewModel.outcome = result.isSuccess ? .success : .failure
                }

                try? await Task.sleep(for: .milliseconds(750))

                await MainActor.run {
                    let lastOutcome = overlayViewModel.outcome
                    overlayViewModel.outcome = nil

                    if dismiss {
                        hideOverlay()
                    } else {
                        if lastOutcome == .success { overlayViewModel.text = "" }
                        sync()
                    }
                }
            }
        }
    }
}

private extension NSView {
    var firstTextField: NSTextField? {
        if let textField = self as? NSTextField { return textField }
        for subview in subviews {
            if let found = subview.firstTextField { return found }
        }
        return nil
    }
}
