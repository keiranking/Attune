import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) var settings

    var body: some View {
        Form {
            Section {
                Text("Attune")
                Text("Curate your music with keywords.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 350, height: 200)
    }
}
