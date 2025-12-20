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

            if viewModel.enforceWhitelists {
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
            Toggle(
                "Limit input to whitelists",
                isOn: $viewModel.enforceWhitelists
            )

            Text(
                """
                Only allow whitelisted keywords to be added to tracks.
                Separate keywords with commas.
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
