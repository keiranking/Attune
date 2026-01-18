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
                VStack(spacing: 20) {
                    ListEditor(
                        title: "WhitelistSettingsView.genreLabel",
                        text: $viewModel.genreText,
                        placeholder: "WhitelistSettingsView.genrePlaceholder"
                    )

                    ListEditor(
                        title: "WhitelistSettingsView.commentsLabel",
                        text: $viewModel.commentText,
                        placeholder: "WhitelistSettingsView.commentsPlaceholder"
                    )

                    ListEditor(
                        title: "WhitelistSettingsView.groupingLabel",
                        text: $viewModel.groupingText,
                        placeholder: "WhitelistSettingsView.groupingPlaceholder"
                    )
                }
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
                "WhitelistSettingsView.enforceWhitelistToggleLabel",
                isOn: $viewModel.enforceWhitelist
            )

            Text("WhitelistSettingsView.enforceWhitelistToggleCaption")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var showAutocompletionToggle: some View {
        Toggle(
            "WhitelistSettingsView.showAutocompletionToggleLabel",
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
    let title: LocalizedStringKey
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

    init(title: LocalizedStringKey, text: Binding<String>, placeholder: String? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
    }
}
