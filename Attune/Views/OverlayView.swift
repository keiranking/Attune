import SwiftUI

struct OverlayView: View {
    @State private var text: String = ""

    @EnvironmentObject var library: TagLibrary // accessible via OverlayWindowController

    var onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("Tag track(s) — type tags or rating")
                .font(.headline)

            HStack {
                TextField("", text: $text, onCommit: { commit() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 600)
                    .focused($isFocused)

                Button("OK") { commit() }
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

    private func commit() {
        onCommit(text)
        text = "" // Clear text after commit

        // We need to hide the window manually here if the closure doesn't handle it,
        // but typically the Controller handles hiding via the closure logic.
        // In the current architecture, the Controller passes a closure that calls hide().
        // However, OverlayView doesn't reference the Controller directly.
        // The simplistic approach is relying on onCommit to trigger the controller's logic.
    }
}
