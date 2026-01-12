import SwiftUI

private struct AppearOnTopModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}

extension View {
    func appearOnTop() -> some View {
        modifier(AppearOnTopModifier())
    }
}
