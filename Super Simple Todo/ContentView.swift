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
    /// Collapsed section names, joined with newlines ("" stands for Other).
    @AppStorage("collapsedSections") private var collapsedStorage = ""
    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool

    private var collapsed: Set<String> {
        Set(collapsedStorage.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
    }

    private func toggleCollapsed(_ key: String) {
        var set = collapsed
        if set.contains(key) { set.remove(key) } else { set.insert(key) }
        collapsedStorage = set.sorted().joined(separator: "\n")
    }

    private var visibleTasks: [TaskItem] {
        hideDoneTasks ? store.sortedTasks.filter { !$0.isDone } : store.sortedTasks
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Add a task", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .help("Add #section to file it (a new #name makes a new section), and !, !! or !!! for Low, Medium or High priority")
                .onSubmit {
                    store.add(newTitle)
                    newTitle = ""
                }
                .padding([.horizontal, .top], 12)

            PriorityKey()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            if visibleTasks.isEmpty && store.sections.isEmpty {
                Spacer()
                Text(store.tasks.isEmpty ? "No tasks yet" : "All done")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(store.grouped(visibleTasks), id: \.section) { group in
                        let key = group.section ?? ""
                        let isCollapsed = collapsed.contains(key)
                        Section {
                            if !isCollapsed {
                                ForEach(group.tasks) { task in
                                    TaskRow(task: task) { store.toggle(task.id) }
                                        .contextMenu { menu(for: task) }
                                }
                                .onDelete { offsets in
                                    offsets.map { group.tasks[$0].id }.forEach(store.delete)
                                }
                                if group.tasks.isEmpty, let name = group.section {
                                    Text("Add one with #\(name.lowercased().replacingOccurrences(of: " ", with: "-"))")
                                        .font(.callout)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        } header: {
                            SectionHeader(name: group.section ?? "Other",
                                          openCount: group.tasks.filter { !$0.isDone }.count,
                                          isCollapsed: isCollapsed) { toggleCollapsed(key) }
                        }
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

    @ViewBuilder
    private func menu(for task: TaskItem) -> some View {
        Picker("Priority", selection: Binding(
            get: { task.priority },
            set: { store.setPriority($0, for: task.id) }
        )) {
            ForEach(Priority.allCases.reversed()) { p in
                Text(p.name).tag(p)
            }
        }
        Picker("Section", selection: Binding(
            get: { task.section },
            set: { store.setSection($0, for: task.id) }
        )) {
            ForEach(store.sections, id: \.self) { name in
                Text(name).tag(Optional(name))
            }
            Divider()
            Text("Other").tag(String?.none)
        }
        Divider()
        Button("Delete", role: .destructive) { store.delete(task.id) }
    }
}

struct SectionHeader: View {
    let name: String
    let openCount: Int
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                    .font(.caption2.bold())
                    .frame(width: 10)
                Text(name)
                Text("\(openCount)").foregroundStyle(.tertiary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name), \(openCount) open")
        .accessibilityHint(isCollapsed ? "Expands the section" : "Collapses the section")
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
