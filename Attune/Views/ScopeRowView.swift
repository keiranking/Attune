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
        case label(text: String, icon: String)
    }
}

struct ScopeRowView: View {
    let status: Status
    let icon: String
    let title: String
    let subtitle: SubtitleContent
    let color: Color

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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .contentTransition(.symbolEffect(.replace, options: .speed(2)))
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(titleColor)

                Group {
                    if case let .text(text) = subtitle, !text.isEmpty {
                        Text(text)
                    } else if case let .label(text, icon) = subtitle, !text.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: icon)
                            Text(text)
                        }
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(subtitleColor)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(height: 38)

            Spacer()

            if isActive {
                Image(systemName: "return")
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? color.opacity(0.8) : Color.clear)
        )
        .contentShape(Rectangle()) // Makes empty space tappable
    }
}
