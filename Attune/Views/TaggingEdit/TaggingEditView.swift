import SwiftUI
import Autocomplete

struct TaggingEditView: View {
    @Bindable var viewModel: ViewModel
    @Environment(Music.self) var music

    var onSubmit: (_ text: String, _ dismiss: Bool) -> Void

    @Environment(\.openSettings) private var openSettings
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            omnibox

            ZStack {
                playerControls

                HStack {
                    modeControls

                    Spacer()

                    otherControls
                }
            }

            VStack(spacing: 4) {
                currentRow
                if !viewModel.selectedTrackIsCurrent { selectedRow }
            }
        }
        .tint(.primary)
        .padding(12)
        .frame(width: 600)
        .background { background }
        .task { isFocused = true }
        .overlay { keyboardShortcuts }
        .disabled(music.isClosed)
    }

    var omnibox: some View {
        HStack {
            TextField(
                "",
                text: $viewModel.text,
                prompt: viewModel.showOmniboxPrompt ? Text(viewModel.omniboxPrompt) : nil
            )
            .autocomplete(
                text: $viewModel.text,
                using: Whitelist.shared.suggestions,
                characterLimit: 45,
                disabled: !viewModel.showAutocompletion
            )
            .onSubmit {
                onSubmit(viewModel.text, true)
            }
            .onChange(of: viewModel.text) {
                viewModel.processInlineCommands()
            }
            .font(.system(size: 24))
            .padding(12)
            .background(Color.antiprimary.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .focused($isFocused)
            .help(.taggingEditViewOmniboxTooltip)
        }
    }

    var modeControls: some View {
        Toggle("", isOn: Binding(
            get: { viewModel.mode == .add },
            set: { _ in viewModel.toggleMode() }
        ))
        .toggleStyle(SymbolSwitchToggleStyle(
            onSymbol: Icon.add.name,
            offSymbol: Icon.remove.name
        ))
        .help(.taggingEditViewModeControlTooltip)
    }

    var playerControls: some View { PlayerControlsView() }

    var otherControls: some View {
        Button(action: { openSettings() }) {
            Label(.taggingEditViewSettingsButtonLabel, systemImage: Icon.settings.name)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.playerButton)
        .help(.taggingEditViewSettingsButtonTooltip)
    }

    var currentRow: some View {
        ScopeRowView(
            status:     viewModel.currentTrackStatus,
            icon:       viewModel.currentTrackIcon,
            title:      viewModel.currentTrackTitle,
            subtitle:   viewModel.currentTrackSubtitle,
            color:      viewModel.mode == .add ? .green : .red,
            isAnimated:
                music.player.isPlaying
                || (viewModel.scope == .current && viewModel.state == .updating)
        )
        .onHover { _ in viewModel.scope = .current }
        .onTapGesture { onSubmit(viewModel.text, true) }
        .disabled(!viewModel.hasCurrentTrack)
        .help(viewModel.hasCurrentTrack ? .taggingEditViewActiveScopeRowTooltip : "")
    }

    var selectedRow: some View {
        ScopeRowView(
            status:     viewModel.selectedTrackStatus,
            icon:       viewModel.selectedTrackIcon,
            title:      viewModel.selectedTrackTitle,
            subtitle:   viewModel.selectedTrackSubtitle,
            color:      viewModel.mode == .add ? .green : .red,
            isAnimated:
                viewModel.scope == .selection && viewModel.state == .updating
        )
        .onHover { _ in viewModel.scope = .selection }
        .onTapGesture { onSubmit(viewModel.text, true) }
        .disabled(!viewModel.hasSelectedTracks)
        .help(viewModel.hasSelectedTracks ? .taggingEditViewActiveScopeRowTooltip : "")
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.regularMaterial)
    }

    var keyboardShortcuts: some View {
        HStack {
            Button(.taggingEditViewAddModeButtonLabel) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    viewModel.mode = .add
                }
            }
            .keyboardShortcut("+", modifiers: [.command])

            Button(.taggingEditViewRemoveModeButtonLabel) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    viewModel.mode = .remove
                }
            }
            .keyboardShortcut("-", modifiers: [.command])

            Button(.taggingEditViewSubmitAndContinueButtonLabel) {
                let text = viewModel.text
                onSubmit(text, false)
            }
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .hidden()
    }
}
