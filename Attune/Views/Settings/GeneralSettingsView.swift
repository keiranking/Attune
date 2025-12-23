import SwiftUI
import KeyboardShortcuts

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    KeyboardShortcuts.Recorder(
                        "Attune Hotkey:",
                        name: .toggleOverlay
                    )

                    Text("Select this field and type the hotkey you would like to use to control Attune.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
