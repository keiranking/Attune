import SwiftUI

struct TagManagerView: View {
    @Environment(TagLibrary.self) var library

    @State private var genreText: String
    @State private var commentText: String
    @State private var groupingText: String

    @State private var isEnabled: Bool = true

    var body: some View {
        VStack {
            toggle
                .padding(.bottom, 20)

            if isEnabled {
                VStack(spacing: 20) {
                    WhitelistEditor(title: "Genre", text: $genreText)

                    WhitelistEditor(title: "Comments", text: $commentText)

                    WhitelistEditor(title: "Grouping", text: $groupingText)
                }
            }
        }
        .padding()
        .frame(width: 400)
        .onDisappear(perform: updateTags)
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

    private func updateTags() {
        print("Updating tags...")
        var newTags: [Tag] = []
        newTags.append(contentsOf: TagLibrary.makeTags(from: genreText, in: .genre))
        newTags.append(contentsOf: TagLibrary.makeTags(from: commentText, in: .comment))
        newTags.append(contentsOf: TagLibrary.makeTags(from: groupingText, in: .grouping))

        library.tags = newTags
    }

    init() {
        genreText = TagLibrary.shared.genreTags.listed
        commentText = TagLibrary.shared.commentTags.listed
        groupingText = TagLibrary.shared.groupingTags.listed
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
