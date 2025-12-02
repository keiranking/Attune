import SwiftUI

struct OverlayView: View {
    @State private var text: String = ""
    var onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("Tag track(s) — type tags or rating")
                .font(.headline)

            HStack {
                TextField("", text: $text, onCommit: { onCommit(text) })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 600)
                    .focused($isFocused)    // ← SwiftUI-native focus binding

                Button("OK") { onCommit(text) }
            }
        }
        .padding()
        .background(
            VisualEffectView(material: .toolTip, blendingMode: .withinWindow)
        )
        .cornerRadius(10)
        .padding()
        .onAppear {
            // Delay ensures hosting controller + window are keyed before focus assignment
            DispatchQueue.main.async {
                self.isFocused = true
            }
        }
    }

    // no longer needed
    func focusTextField() {}
}
