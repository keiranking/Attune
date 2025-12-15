import SwiftUI

struct PlayerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentTransition(.symbolEffect(.replace, options: .speed(2)))
            .frame(width: 40, height: 36)
            .background(isHovered ? AnyShapeStyle(.primary.opacity(0.05)) : AnyShapeStyle(.clear))
            .foregroundStyle(
                isHovered ? Color.primary : (isEnabled ? Color.secondary : .tertiary)
            )
            .cornerRadius(8)
            .labelStyle(.iconOnly)
            .font(.system(size: 16))
            .onHover { isHovered = $0 }
    }
}

extension ButtonStyle where Self == PlayerButtonStyle {
    static var playerButton: PlayerButtonStyle {
        PlayerButtonStyle()
    }
}
