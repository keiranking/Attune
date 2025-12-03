import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("Global Hotkey")) {
                HStack {
                    Text("Toggle Attune:")
                    Spacer()
                    Text(settings.shortcutDescription)
                        .foregroundColor(.secondary)
                    Button("Edit") {
                        // Placeholder
                    }
                }
            }

            Section {
                Text("Attune")
                Text("Curate your music with keywords and moods.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 350, height: 200)
    }
}
