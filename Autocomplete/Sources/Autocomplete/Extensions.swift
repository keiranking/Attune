import SwiftUI
import AppKit

extension Color {
    static var tertiary: Color {
        Color(nsColor: .tertiaryLabelColor)
    }
}

extension ShapeStyle where Self == Color {
    static var tertiary: Color { .tertiary }
}

extension String {
    var lastWord: String? {
        split(separator: " ").last.map(String.init)
    }
}
