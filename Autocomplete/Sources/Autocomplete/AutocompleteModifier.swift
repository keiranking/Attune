import SwiftUI
import AppKit

struct AutocompleteModifier: ViewModifier {
    @Binding var text: String
    let autocompleter: Autocompleter

    let characterLimit: Int = 45
    var remainingCharacters: Int { characterLimit - text.count }
    @State private var rejectInputAnimationTrigger: Int = 0

    @State private var suggestion: String? = nil
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
                Text(suggestion ?? "").foregroundStyle(Color.tertiary)
            }
            .allowsHitTesting(false)
            .lineLimit(1)
        }
    }

    func handleAcceptIntent() -> KeyPress.Result {
        guard let suggestion else { return .ignored }
        text += suggestion
        self.suggestion = nil
        return .handled
    }

    func handleTextChange(old: String, new: String) {
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
            suggestion = nil
        }

        DispatchQueue.main.async {
            isForwardTyping = false
        }
    }

    func suggestion(for input: String) -> String? {
        guard
            let lastWord = input.lastWord,
            lastWord.count > 1,
            let suggestion = autocompleter.complete(lastWord),
            suggestion.count <= remainingCharacters
        else { return nil }

        return suggestion
    }

    func signalRejectInput() {
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
        else { self.modifier(
            AutocompleteModifier(
                text: text,
                autocompleter: Autocompleter(candidates: candidates)
            )
        ) }
    }
}
