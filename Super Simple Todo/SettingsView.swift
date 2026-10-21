import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newTag = ""
    @State private var renaming: String?
    @State private var renameText = ""

    var body: some View {
        Form {
            Section {
                Toggle("Hide done tasks", isOn: $hideDoneTasks)
            }
            Section {
                List {
                    ForEach(store.tags, id: \.self) { name in
                        HStack {
                            if renaming == name {
                                TextField("Name", text: $renameText)
                                    .onSubmit(commitRename)
                                    .onExitCommand { renaming = nil }
                            } else {
                                Text(name)
                                Text("\(store.tasks.filter { $0.tags.contains(name) }.count)")
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button("Rename") { renaming = name; renameText = name }
                                .buttonStyle(.borderless)
                            Button {
                                store.deleteTag(name)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete \(name)")
                            .help("Delete tag; it's removed from every task")
                        }
                    }
                    .onMove { store.moveTag(from: $0, to: $1) }
                }
                .frame(height: 150)
                HStack {
                    TextField("New tag", text: $newTag)
                        .onSubmit(addTag)
                    Button("Add", action: addTag)
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Tags")
            } footer: {
                Text("Drag to reorder. Renaming a tag updates every task; deleting removes it from them. You can also type #name in a new task, or right-click a task ▸ Tags.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }

    private func addTag() {
        store.addTag(newTag)
        newTag = ""
    }

    private func commitRename() {
        if let old = renaming { store.renameTag(old, to: renameText) }
        renaming = nil
    }
}
