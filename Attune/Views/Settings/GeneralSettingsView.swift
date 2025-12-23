import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder(
                    "Attune Hotkey:",
                    name: .toggleOverlay
                )

                Text("Select this field and type the hotkey you would like to use to control Attune.")
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 10)

            Section {
                LaunchAtLogin.Toggle()
            }
        }
    }
}
