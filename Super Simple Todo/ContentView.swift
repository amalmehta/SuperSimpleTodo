import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TasksView().tabItem { Text("Tasks") }
            ActivityView().tabItem { Text("Activity") }
        }
        .frame(minWidth: 340, minHeight: 360)
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool

    private var visibleTasks: [TaskItem] {
        hideDoneTasks ? store.sortedTasks.filter { !$0.isDone } : store.sortedTasks
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Add a task", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .help("End with !, !! or !!! for Low, Medium or High priority")
                .onSubmit {
                    store.add(newTitle)
                    newTitle = ""
                }
                .padding([.horizontal, .top], 12)

            PriorityKey()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

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
                                Picker("Priority", selection: Binding(
                                    get: { task.priority },
                                    set: { store.setPriority($0, for: task.id) }
                                )) {
                                    ForEach(Priority.allCases.reversed()) { p in
                                        Text(p.name).tag(p)
                                    }
                                }
                                Divider()
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
                    .foregroundStyle(circleColor)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark not done" : "Mark done")
            .accessibilityValue(task.priority == .none ? "" : "\(task.priority.name) priority")
            .help(task.priority == .none ? "No priority" : "\(task.priority.name) priority")

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }

    private var circleColor: Color {
        task.priority == .none && task.isDone ? .accentColor : task.priority.color
    }
}

extension Priority {
    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        case .none: .secondary
        }
    }
}

/// One-line key explaining the circle colors.
struct PriorityKey: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Priority.allCases.reversed()) { p in
                HStack(spacing: 4) {
                    Circle().fill(p.color).frame(width: 8, height: 8)
                    Text(p.name)
                }
            }
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Circle colors: red High, orange Medium, blue Low, grey None")
    }
}
