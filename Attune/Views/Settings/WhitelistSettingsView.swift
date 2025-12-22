import SwiftUI

extension WhitelistSettingsView {
    @Observable
    final class ViewModel {
        var genreText: String = ""
        var commentText: String = ""
        var groupingText: String = ""

        var enforceWhitelist: Bool {
            get { AppSettings.shared.enforceWhitelist }
            set { AppSettings.shared.enforceWhitelist = newValue }
        }

        init() {
            load()
        }

        func load() {
            genreText = Whitelist.shared.genreTags.listed
            commentText = Whitelist.shared.commentTags.listed
            groupingText = Whitelist.shared.groupingTags.listed
        }

        func save() {
            Whitelist.shared.updateTags([
                Whitelist.tags(from: genreText, as: .genre),
                Whitelist.tags(from: commentText, as: .comment),
                Whitelist.tags(from: groupingText, as: .grouping)
            ].flatMap { $0 })
        }
    }
}

struct WhitelistSettingsView: View {
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
            .disabled(!viewModel.enforceWhitelist)
        }
        .padding()
        .frame(width: 400)
    }

    var toggle: some View {
        VStack(alignment: .leading) {
            Toggle(
                "Enforce whitelist",
                isOn: $viewModel.enforceWhitelist
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
