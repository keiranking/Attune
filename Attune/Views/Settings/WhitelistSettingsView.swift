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
                showAutocompletionToggle
            }

            Section {
                ListEditor(
                    title: "Genre",
                    text: $viewModel.genreText,
                    placeholder: "Classical, Jazz, Reggae"
                )

                ListEditor(
                    title: "Comments",
                    text: $viewModel.commentText,
                    placeholder: "lively, sad, traditional"
                )

                ListEditor(
                    title: "Grouping",
                    text: $viewModel.groupingText,
                    placeholder: "brass, strings, vocal"
                )
            }
        }
        .formStyle(.grouped)
        .frame(minHeight: 550)
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
                Only whitelisted keywords can be added to tracks.
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
            "Show suggestions as you type",
            isOn: $viewModel.showAutocompletion
        )
    }

    init(
        viewModel: ViewModel
    ) {
        self.viewModel = viewModel
    }
}

private struct ListEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        LabeledContent(title) {
            TextField("", text: $text, prompt: Text(placeholder ?? ""), axis: .vertical)
                .focused($isFocused)
                .lineLimit(5, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .font(.body)
                .frame(maxWidth: .infinity)
                .textFieldStyle(.plain)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.textBackgroundColor))
                )
        }
    }

    init(title: String, text: Binding<String>, placeholder: String? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
    }
}
