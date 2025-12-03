import SwiftUI

struct TagManagerView: View {
    @EnvironmentObject var library: TagLibrary
    @State private var newTagName: String = ""
    @State private var selectedCategory: TagCategory = .comment

    var body: some View {
        VStack {
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(TagCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)

                TextField("Tag", text: $newTagName, onCommit: addTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: addTag) {
                    Image(systemName: "plus")
                }
                .disabled(newTagName.isEmpty)
            }
            .padding()

            List {
                ForEach(library.tags.filter { $0.category == selectedCategory }) { tag in
                    Text(tag.name)
                }
                .onDelete(perform: deleteTag)
            }
        }
        .frame(width: 400, height: 500)
    }

    private func addTag() {
        withAnimation {
            library.addTag(name: newTagName, category: selectedCategory)
            newTagName = ""
        }
    }

    private func deleteTag(at offsets: IndexSet) {
        withAnimation {
            library.deleteTags(at: offsets, in: selectedCategory)
        }
    }
}
