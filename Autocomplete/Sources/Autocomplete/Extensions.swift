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
