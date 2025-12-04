import SwiftUI
import Combine

final class OverlayState: ObservableObject {
    @Published var text: String = ""
}

struct OverlayView: View {
    @ObservedObject var state: OverlayState

    @EnvironmentObject var library: TagLibrary // accessible via OverlayWindowController

    var onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("Tag track(s) — type tags or rating")
                .font(.headline)

            HStack {
                TextField("", text: $state.text, onCommit: { onCommit(state.text) })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 600)
                    .focused($isFocused)

                Button("OK") { onCommit(state.text) }
            }
        }
        .padding()
        .background(
            VisualEffectView(material: .toolTip, blendingMode: .withinWindow)
        )
        .cornerRadius(10)
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                self.isFocused = true
            }
        }
    }
}
