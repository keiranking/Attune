import SwiftUI
import AppKit

struct AutocompleteModifier: ViewModifier {
    @Binding var text: String
    let candidates: [String]

    let characterLimit: Int = 45
    var remainingCharacters: Int { characterLimit - text.count }
    @State private var shakeTrigger: Int = 0

    @State private var suggestion: String = ""
    @State private var isForwardTyping: Bool = false

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
                .onKeyPress(.rightArrow) { handleAcceptIntent() }
                .onKeyPress(.tab) { handleAcceptIntent() }
                .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { _ in
                    if !isForwardTyping {
                        suggestion = ""
                    }
                }
                .onChange(of: text) { old, new in
                    handleTextChange(old: old, new: new)
                }
                .phaseAnimator([0, 10, -10, 10, -10, 0], trigger: shakeTrigger) { content, offset in
                    content.offset(x: offset)
                } animation: { _ in .linear(duration: 0.05) }
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
            signalCharacterLimitReached()
            return
        }

        if new.count > old.count && new.hasPrefix(old) {
            isForwardTyping = true
            updateSuggestion(for: new)
        } else {
            isForwardTyping = false
            suggestion = ""
        }

        DispatchQueue.main.async {
            isForwardTyping = false
        }
    }

    private func updateSuggestion(for input: String) {
        let lastWord = input.components(separatedBy: " ").last?.lowercased() ?? ""

        guard lastWord.count > 1 else {
            suggestion = ""
            return
        }

        if let match = candidates.first(where: {
            $0.lowercased().hasPrefix(lastWord)
            && $0.lowercased() != lastWord
        }) {
            suggestion = String(match.dropFirst(lastWord.count))

            if suggestion.count > remainingCharacters { suggestion = "" }
        } else {
            suggestion = ""
        }
    }

    private func signalCharacterLimitReached() {
        shakeTrigger += 1
        NSSound(named: "Basso")?.play()
    }
}

extension View {
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
