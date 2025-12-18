import SwiftUI
import AppKit

extension Color {
    static var antiprimary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? .black
                : .white
        })
    }

    static var tertiary: Color {
        Color(nsColor: .tertiaryLabelColor)
    }

    static var quaternary: Color {
        Color(nsColor: .quaternaryLabelColor)
    }
}

extension ShapeStyle where Self == Color {
    static var antiprimary: Color { .antiprimary }
    static var tertiary: Color { .tertiary }
    static var quaternary: Color { .quaternary }
}
