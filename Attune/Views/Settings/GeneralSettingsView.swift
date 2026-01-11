import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

extension GeneralSettingsView {
    @Observable
    final class ViewModel {
        var showOmniboxPrompt: Bool {
            get { AppSettings.shared.showOmniboxPrompt }
            set { AppSettings.shared.showOmniboxPrompt = newValue }
        }

        init() {}
    }
}


struct GeneralSettingsView: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle()

                VStack(alignment: .leading) {
                    KeyboardShortcuts.Recorder(
                        String(localized: .generalSettingsViewGlobalHotkeyLabel),
                        name: .toggleOverlay
                    )

                    Text(.generalSettingsViewGlobalHotkeyCaption)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
            }

            Section {
                Toggle(
                    .generalSettingsViewShowOmniboxPromptLabel,
                    isOn: $viewModel.showOmniboxPrompt
                )
            }
        }
        .formStyle(.grouped)
    }

    init(
        viewModel: ViewModel
    ) {
        self.viewModel = viewModel
    }
}
