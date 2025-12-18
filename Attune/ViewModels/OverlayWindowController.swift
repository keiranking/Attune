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

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating

        self.contentViewController = contentViewController
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
        optionKeyAction?(isOnlyOptionKey(event: event))

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

// MARK: - OverlayWindowController (single source of truth)
final class OverlayWindowController {
    private let viewModel: OverlayViewModel
    private var hosting: NSHostingController<AnyView>
    private var window: OverlayWindow

    private let music = Music.shared

    var isShown: Bool { window.isVisible }

    private var pendingApplyRefresh = false

    init() {
        self.viewModel = OverlayViewModel()
        self.hosting = NSHostingController(rootView: AnyView(EmptyView()))
        self.window = OverlayWindow(contentViewController: hosting)

        let overlayView = OverlayView(
            viewModel: viewModel,
            onCommit: { [weak self] text in
                guard let self else { return }

                Task {
                    let result = await self.music.tagger.process(
                        command: text,
                        scope: self.viewModel.scope,
                        mode: self.viewModel.mode
                    )

                    await MainActor.run {
                        switch result {
                        case .success:
                            print("Rating/tags processed successfully.")
                        case .failure(let error):
                            self.viewModel.state = .failed(String(describing: error))
                        }
                        self.hide()
                    }
                }
            },
            onApply: { [weak self] text in
                guard let self else { return }

                Task {
                    await MainActor.run {
                        self.viewModel.state = .writing
                    }

                    let result = await self.music.tagger.process(
                        command: text,
                        scope: self.viewModel.scope,
                        mode: self.viewModel.mode
                    )

                    await MainActor.run {
                        switch result {
                        case .success:
                            self.viewModel.text = ""
                            self.viewModel.state = .ready
                            self.sync()
                        case .failure(let error):
                            self.viewModel.state = .failed(String(describing: error))
                        }
                    }
                }
            }
        )
        .environmentObject(TagLibrary.shared)
        .environmentObject(AppSettings.shared)
        .environment(music)

        hosting.rootView = AnyView(overlayView)

        window.hideAction = { [weak self] in self?.hide() }

        window.arrowKeyAction = { [weak self] in
            guard let self else { return }

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.viewModel.toggleScope()
                }
            }
        }

        window.optionKeyAction = { [weak self] isOptionDown in
            guard let self else { return }

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.viewModel.showSecondaryInfo = isOptionDown
                }
            }
        }

        music.onChange = { [weak self] in
            guard let self else { return }

            DispatchQueue.main.async {
                self.sync()

                if self.pendingApplyRefresh {
                    self.pendingApplyRefresh = false
                }
            }
        }
    }

    private func sync() {
        music.refresh()

        viewModel.currentTrack = music.currentTrack
        viewModel.selectedTracks = music.selectedTracks

        if viewModel.scope == nil {
            viewModel.chooseDefaultScope()
        }
    }

    func show() {
        viewModel.text = ""
        viewModel.mode = .add
        viewModel.scope = nil

        sync()

        if let screenFrame = NSScreen.main?.visibleFrame {
            let x = screenFrame.midX - window.frame.width / 2 // horizontally centered
            let y = screenFrame.maxY - screenFrame.height * 0.15 - window.frame.height // near top
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async { [weak self] in
            guard let textField = self?.hosting.view.firstTextField else { return }
            self?.window.makeFirstResponder(textField)
        }
    }

    func hide() {
        window.orderOut(nil)
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
