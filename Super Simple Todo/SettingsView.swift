import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newSection = ""
    @State private var renaming: String?
    @State private var renameText = ""

    var body: some View {
        Form {
            Section {
                Toggle("Hide done tasks", isOn: $hideDoneTasks)
            }
            Section {
                List {
                    ForEach(store.sections, id: \.self) { name in
                        HStack {
                            if renaming == name {
                                TextField("Name", text: $renameText)
                                    .onSubmit(commitRename)
                                    .onExitCommand { renaming = nil }
                            } else {
                                Text(name)
                                Text("\(store.tasks.filter { $0.section == name }.count)")
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button("Rename") { renaming = name; renameText = name }
                                .buttonStyle(.borderless)
                            Button {
                                store.deleteSection(name)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete \(name)")
                            .help("Delete section; its tasks move to Other")
                        }
                    }
                    .onMove { store.moveSection(from: $0, to: $1) }
                }
                .frame(height: 150)
                HStack {
                    TextField("New section", text: $newSection)
                        .onSubmit(addSection)
                    Button("Add", action: addSection)
                        .disabled(newSection.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Sections")
            } footer: {
                Text("Drag to reorder. Deleting a section moves its tasks to Other. You can also type #name in a new task to create one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }

    private func addSection() {
        store.addSection(newSection)
        newSection = ""
    }

    private func commitRename() {
        if let old = renaming { store.renameSection(old, to: renameText) }
        renaming = nil
    }
}
