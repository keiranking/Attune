import SwiftUI
import AppKit

struct AutocompleteModifier: ViewModifier {
    @Binding var text: String
    let candidates: [String]

    let characterLimit: Int = 45
    var remainingCharacters: Int { characterLimit - text.count }
    @State private var rejectInputAnimationTrigger: Int = 0

    @State private var suggestion: String = ""
    @State private var isForwardTyping: Bool = false

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
                .onKeyPress(.rightArrow, action: handleAcceptIntent)
                .onKeyPress(.tab, action: handleAcceptIntent)
                .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { _ in
                    if !isForwardTyping {
                        suggestion = ""
                    }
                }
                .onChange(of: text, handleTextChange)
                .phaseAnimator(
                    [0, 10, -10, 10, -10, 0],
                    trigger: rejectInputAnimationTrigger,
                    content: { content, phase in content.offset(x: phase) },
                    animation: { _ in .linear(duration: 0.05) }
                )

            HStack(spacing: 0) {
                Text(text).foregroundStyle(.clear)
                Text(suggestion).foregroundStyle(Color.tertiary)
            }
            .allowsHitTesting(false)
            .lineLimit(1)
        }
    }

    private func handleAcceptIntent() -> KeyPress.Result {
        guard !suggestion.isEmpty else { return .ignored }
        text += suggestion
        suggestion = ""
        return .handled
    }

    private func handleTextChange(old: String, new: String) {
        if new.count > characterLimit {
            text = old
            signalRejectInput()
            return
        }

        if new.count > old.count && new.hasPrefix(old) {
            isForwardTyping = true
            suggestion = suggestion(for: new)
        } else {
            isForwardTyping = false
            suggestion = ""
        }

        DispatchQueue.main.async {
            isForwardTyping = false
        }
    }

    private func suggestion(for input: String) -> String {
        let lastWord = input.components(separatedBy: " ").last?.lowercased() ?? ""

        guard lastWord.count > 1 else { return "" }

        if let match = candidates.first(where: {
            $0.lowercased().hasPrefix(lastWord)
            && $0.lowercased() != lastWord
        }) {
            let suggestion = String(match.dropFirst(lastWord.count))

            if suggestion.count <= remainingCharacters { return suggestion }
        }

        return ""
    }

    private func signalRejectInput() {
        rejectInputAnimationTrigger += 1
        NSSound(named: "Basso")?.play()
    }
}

public extension View {
    @ViewBuilder
    func autocomplete(
        text: Binding<String>,
        using candidates: [String],
        disabled: Bool = false
    ) -> some View {
        if disabled { self }
        else { self.modifier(AutocompleteModifier(text: text, candidates: candidates)) }
    }
}
