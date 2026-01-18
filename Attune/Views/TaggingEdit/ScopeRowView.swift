import Foundation
import SwiftUI

extension ScopeRowView {
    enum Status {
        case active
        case inactive
        case disabled
    }

    enum SubtitleContent {
        case none
        case text(String)
        case label(text: String, icon: Icon)
    }
}

struct ScopeRowView: View {
    let status: Status
    let icon: Icon
    let title: String
    let subtitle: SubtitleContent
    let color: Color
    let isAnimated: Bool

    var isActive: Bool { status == .active }
    var isDisabled: Bool { status == .disabled }

    var iconColor: Color {
        isDisabled ? .tertiary : (isActive ? .primary : .secondary)
    }
    var titleColor: Color {
        isDisabled ? .tertiary : (isActive ? .primary : .secondary)
    }
    var subtitleColor: Color {
        isDisabled ? .tertiary : (isActive ? .primary.opacity(0.8) : .secondary)
    }

    var image: Image {
        icon.isCustom ? Image(icon.name) : Image(systemName: icon.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            image
                .contentTransition(.symbolEffect(.replace, options: .speed(2)))
                .if(isAnimated) {
                    $0.symbolEffect(.variableColor.iterative.hideInactiveLayers)
                }
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(titleColor)

                HStack(spacing: 2) {
                    if case let .text(text) = subtitle, !text.isEmpty {
                        Text(text)
                    } else if case let .label(text, icon) = subtitle, !text.isEmpty {
                        Image(systemName: icon.name)
                        Text(text)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(subtitleColor)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(height: 38)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.leading, 12)
        .padding(.trailing, 20)
        .background(
            Attunoid(cornerRadius: 8)
                .fill(isActive ? color.opacity(0.8) : Color.clear)
        )
        .contentShape(Rectangle()) // Makes empty space tappable
    }

    init(
        status: Status,
        icon: Icon,
        title: String,
        subtitle: SubtitleContent,
        color: Color,
        isAnimated: Bool = false
    ) {
        self.status = status
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isAnimated = isAnimated
    }
}
