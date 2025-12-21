import SwiftUI

extension TagManagerView {
    @Observable
    final class ViewModel {
        var genreText: String = ""
        var commentText: String = ""
        var groupingText: String = ""

        var enforceWhitelists: Bool {
            get { AppSettings.shared.enforceWhitelists }
            set { AppSettings.shared.enforceWhitelists = newValue }
        }

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
                TagLibrary.tags(from: genreText, as: .genre),
                TagLibrary.tags(from: commentText, as: .comment),
                TagLibrary.tags(from: groupingText, as: .grouping)
            ].flatMap { $0 })
        }
    }
}

struct TagManagerView: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        VStack(spacing: 20) {
            toggle

            VStack(spacing: 20) {
                WhitelistEditor(
                    title: "Genre",
                    text: $viewModel.genreText,
                    placeholder: "Classical, Jazz, Reggae"
                )

                WhitelistEditor(
                    title: "Comments",
                    text: $viewModel.commentText,
                    placeholder: "lively, sad, traditional"
                )

                WhitelistEditor(
                    title: "Grouping",
                    text: $viewModel.groupingText,
                    placeholder: "brass, strings, vocal"
                )
            }
            .disabled(!viewModel.enforceWhitelists)
        }
        .padding()
        .frame(width: 400)
    }

    var toggle: some View {
        VStack(alignment: .leading) {
            Toggle(
                "Enforce whitelists",
                isOn: $viewModel.enforceWhitelists
            )

            Text(
                """
                Only allow whitelisted keywords to be added to tracks.
                Existing metadata is not affected.
                """
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    init(
        viewModel: ViewModel
    ) {
        self.viewModel = viewModel
    }
}

private struct WhitelistEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            TextField(placeholder ?? "", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(5, reservesSpace: true)
                .font(.body)
                .frame(maxWidth: .infinity)
        }
    }

    init(title: String, text: Binding<String>, placeholder: String? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
    }
}
