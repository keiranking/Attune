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

        var showAutocompletion: Bool {
            get { AppSettings.shared.showAutocompletion }
            set { AppSettings.shared.showAutocompletion = newValue }
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
            Whitelist.shared.replace(with: [
                Tag.array(from: genreText, as: .genre),
                Tag.array(from: commentText, as: .comment),
                Tag.array(from: groupingText, as: .grouping)
            ].flatMap { $0 })
        }
    }
}

struct WhitelistSettingsView: View {
    @Bindable var viewModel: ViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            Section {
                enforceWhitelistToggle
            }

            Group {
                Divider()

                showAutocompletionToggle

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
        .onDisappear() { viewModel.save() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { viewModel.save() }
        }
    }

    var enforceWhitelistToggle: some View {
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

    var showAutocompletionToggle: some View {
        Toggle(
            "Autocomplete keywords from whitelist",
            isOn: $viewModel.showAutocompletion
        )
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
        Section(
            header: Text(title).padding(.top, 20)
        ) {
            TextField("", text: $text, prompt: Text(placeholder ?? ""), axis: .vertical)
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
