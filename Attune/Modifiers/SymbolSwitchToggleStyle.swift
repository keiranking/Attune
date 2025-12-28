import SwiftUI

struct SymbolSwitchToggleStyle: ToggleStyle {
    let onSymbol: String
    let offSymbol: String
    let showLabel: Bool

    let height = 24.0
    let dialPadding = 2.0
    var dialSize: CGFloat { height - dialPadding * 2 }
    var width: CGFloat { height * 2.5 }

    @Environment(\.isEnabled) private var isEnabled
    @State var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if showLabel {
                configuration.label
                    .padding(.trailing, 8)
            }

            ZStack {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.antiprimary.opacity(0.2))
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    .frame(width: width, height: height)

                HStack {
                    if configuration.isOn { Spacer() }

                    ZStack {
                        RoundedRectangle(cornerRadius: dialSize / 2)
                            .fill(isEnabled ? (isHovered ? .primary : .secondary) : .tertiary)
                            .frame(width: dialSize * 1.75, height: dialSize)

                        Image(systemName: configuration.isOn ? onSymbol : offSymbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.antiprimary.opacity(0.7))
                    }

                    if !configuration.isOn { Spacer() }
                }
                .padding(dialPadding)
                .frame(width: width, height: height)
            }
            .onTapGesture {
                guard isEnabled else { return }

                withAnimation(.easeInOut(duration: 0.1)) {
                    configuration.isOn.toggle()
                }
            }
        }
        .onHover { isHovered = $0 }
    }

    init(
        onSymbol: String,
        offSymbol: String,
        showLabel: Bool = false
    ) {
        self.onSymbol = onSymbol
        self.offSymbol = offSymbol
        self.showLabel = showLabel
    }
}
