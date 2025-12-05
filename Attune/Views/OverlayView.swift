import SwiftUI
import Combine

// Expanded State Object for UI Data
final class OverlayState: ObservableObject {
    @Published var text: String = ""
    @Published var scope: TaggingScope = .current
    @Published var mode: TaggingMode = .add

    // Metadata for display
    @Published var currentTrackTitle: String = "Loading..."
    @Published var currentTrackArtist: String = ""
    @Published var isMusicPlaying: Bool = false
    @Published var selectionCount: Int = 0

    func toggleScope() {
        scope = (scope == .current) ? .selection : .current
    }

    func toggleMode() {
        mode = (mode == .add) ? .remove : .add
    }
}

struct OverlayView: View {
    @ObservedObject var state: OverlayState
    @EnvironmentObject var library: TagLibrary
    var onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // 1. Input Field Area
            HStack {
                TextField("", text: $state.text, onCommit: { onCommit(state.text) })
                    .font(.system(size: 24, weight: .regular, design: .default))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // 2. Mode Picker (Add / Remove)
            Picker("", selection: $state.mode) {
                ForEach(TaggingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 60)
            .padding(.bottom, 12)

            // 3. Scope List
            VStack(spacing: 4) {
                // Item 1: Current Track
                ScopeRow(
                    isActive: state.scope == .current,
                    icon: state.isMusicPlaying ? "waveform" : "waveform.slash",
                    title: "\(state.currentTrackTitle)",
                    subtitle: state.currentTrackArtist,
                    color: state.mode == .add ? .green : .red
                )
                .onTapGesture { state.scope = .current }

                // Item 2: Selected Tracks
                ScopeRow(
                    isActive: state.scope == .selection,
                    icon: "cursorarrow.rays",
                    title: "^[\(state.selectionCount) track](inflect: true) selected",
                    subtitle: state.selectionCount > 0 ? "" : "Select a track in the Music app",
                    color: state.mode == .add ? .green : .red
                )
                .onTapGesture { state.scope = .selection }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 600)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            DispatchQueue.main.async {
                self.isFocused = true
            }
        }
    }
}

// Subview for the List Items
struct ScopeRow: View {
    let isActive: Bool
    let icon: String
    let title: LocalizedStringKey
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isActive ? .white : .secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isActive ? .white : .primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? .white.opacity(0.8) : .secondary)
                }
            }
            Spacer()

            if isActive {
                Image(systemName: "return")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? color.opacity(0.8) : Color.clear)
        )
        .contentShape(Rectangle()) // Makes empty space tappable
    }
}
