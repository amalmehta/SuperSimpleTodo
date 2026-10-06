import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool

    private var visibleTasks: [TaskItem] {
        hideDoneTasks ? store.tasks.filter { !$0.isDone } : store.tasks
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Add a task", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit {
                    store.add(newTitle)
                    newTitle = ""
                }
                .padding(12)

            if visibleTasks.isEmpty {
                Spacer()
                Text(store.tasks.isEmpty ? "No tasks yet" : "All done")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(visibleTasks) { task in
                        TaskRow(task: task) { store.toggle(task.id) }
                            .contextMenu {
                                Button("Delete", role: .destructive) { store.delete(task.id) }
                            }
                    }
                    .onDelete { offsets in
                        offsets.map { visibleTasks[$0].id }.forEach(store.delete)
                    }
                }
            }

            Divider()
            HStack {
                Text("\(store.doneCount) of \(store.tasks.count) done")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear Done") { store.clearDone() }
                    .disabled(store.doneCount == 0)
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .help("Settings (⌘,)")
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 300, minHeight: 300)
        .onAppear { inputFocused = true }
    }
}

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? Color.accentColor : Color.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark not done" : "Mark done")

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }
}
