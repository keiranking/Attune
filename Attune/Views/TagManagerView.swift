import SwiftUI

extension TagManagerView {
    @Observable
    final class ViewModel {
        var genreText: String = ""
        var commentText: String = ""
        var groupingText: String = ""

        init() {
            load()
        }

        func load() {
            genreText = TagLibrary.shared.genreTags.listed
            commentText = TagLibrary.shared.commentTags.listed
            groupingText = TagLibrary.shared.groupingTags.listed
        }

        func save() {
            TagLibrary.shared.updateTags([
                TagLibrary.tags(from: genreText, in: .genre),
                TagLibrary.tags(from: commentText, in: .comment),
                TagLibrary.tags(from: groupingText, in: .grouping)
            ].flatMap { $0 })
        }
    }
}

struct TagManagerView: View {
    @Bindable var viewModel: ViewModel

    @State private var isEnabled: Bool = true

    var onSubmit: (() -> Void)?

    var body: some View {
        VStack {
            toggle
                .padding(.bottom, 20)

            if isEnabled {
                VStack(spacing: 20) {
                    WhitelistEditor(title: "Genre", text: $viewModel.genreText)

                    WhitelistEditor(title: "Comments", text: $viewModel.commentText)

                    WhitelistEditor(title: "Grouping", text: $viewModel.groupingText)
                }
            }
        }
        .padding()
        .frame(width: 400)
    }

    var toggle: some View {
        VStack(alignment: .leading) {
            Toggle("Limit input to whitelists", isOn: $isEnabled)
            Text(
                """
                Only allow whitelisted keywords when editing track metadata.
                Existing metadata is not affected. Separate keywords with commas.
                """
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    init(
        viewModel: ViewModel,
        onSubmit: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSubmit = onSubmit
    }
}

private struct WhitelistEditor: View {
    let title: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.background)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                }
                .font(.body)
                .frame(minHeight: 100)
        }
    }
}
