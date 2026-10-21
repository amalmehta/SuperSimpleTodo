import SwiftUI

extension Notification.Name {
    static let newTask = Notification.Name("SuperSimpleTodo.newTask")
    static let showTab = Notification.Name("SuperSimpleTodo.showTab")
}

struct ContentView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.undoManager) private var undoManager
    // For screenshots: `--args -StartTab activity` opens on the Activity tab.
    @State private var tab = UserDefaults.standard.string(forKey: "StartTab") ?? "tasks"

    var body: some View {
        TabView(selection: $tab) {
            TasksView().tabItem { Text("Tasks") }.tag("tasks")
            ActivityView().tabItem { Text("Activity") }.tag("activity")
        }
        .frame(minWidth: 340, minHeight: 360)
        .onAppear { store.undoManager = undoManager }
        .onChange(of: undoManager) { store.undoManager = undoManager }
        .onReceive(NotificationCenter.default.publisher(for: .showTab)) { note in
            if let name = note.object as? String { tab = name }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTask)) { _ in tab = "tasks" }
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool
    @State private var selection = Set<UUID>()
    @State private var tagFilter: String?
    /// The task being renamed in place, and its text.
    @State private var editingID: UUID?
    @State private var editText = ""
    @FocusState private var editFocused: Bool
    /// The task the "New Tag…" prompt is adding a tag to.
    @State private var tagTarget: TaskItem?
    @State private var newTagName = ""

    private var visibleTasks: [TaskItem] {
        store.visibleTasks(hideDone: hideDoneTasks, tag: tagFilter)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Add a task  (#tag, ! priority)", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .help("Add #tag to tag it (a new #name makes a new tag), and !, !! or !!! for Low, Medium or High priority")
                .onSubmit {
                    store.add(newTitle)
                    newTitle = ""
                }
                .padding([.horizontal, .top], 12)

            PriorityKey()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            if let tagFilter {
                HStack(spacing: 6) {
                    Text("Showing")
                    TagChips(tags: [tagFilter])
                    Button {
                        self.tagFilter = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show all tasks")
                    .help("Show all tasks")
                    Spacer()
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            if visibleTasks.isEmpty {
                Spacer()
                Text(store.tasks.isEmpty ? "No tasks yet" : (tagFilter == nil ? "All done" : "Nothing with this tag"))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                list
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
        .onReceive(NotificationCenter.default.publisher(for: .newTask)) { _ in inputFocused = true }
        .onChange(of: store.tags) { if let tag = tagFilter, !store.tags.contains(tag) { tagFilter = nil } }
        .alert("New Tag", isPresented: Binding(get: { tagTarget != nil }, set: { if !$0 { tagTarget = nil } })) {
            TextField("Name", text: $newTagName)
            Button("Add") {
                if let task = tagTarget { store.toggleTag(newTagName, for: task.id) }
                newTagName = ""
            }
            Button("Cancel", role: .cancel) { newTagName = "" }
        } message: {
            Text("Adds a tag to \u{201C}\(tagTarget?.title ?? "")\u{201D}.")
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(visibleTasks) { task in
                TaskRow(task: task,
                        onToggle: { store.toggle(task.id) },
                        onTagTap: { tag in tagFilter = (tagFilter == tag ? nil : tag) },
                        editor: editingID == task.id ? AnyView(editor) : nil)
            }
        }
        .contextMenu(forSelectionType: UUID.self) { ids in
            if ids.count == 1, let task = store.tasks.first(where: { $0.id == ids.first }) {
                menu(for: task)
            } else if !ids.isEmpty {
                Button("Tick or Untick \(ids.count) Tasks") { store.toggle(ids) }
                Button("Delete \(ids.count) Tasks", role: .destructive) { store.delete(ids) }
            }
        } primaryAction: { ids in
            if ids.count == 1, let id = ids.first { beginEdit(id) }
        }
        .onDeleteCommand { store.delete(selection) }
        .onKeyPress(.space) {
            guard editingID == nil, !selection.isEmpty else { return .ignored }
            store.toggle(selection)
            return .handled
        }
        .onKeyPress(.return) {
            guard editingID == nil, selection.count == 1, let id = selection.first else { return .ignored }
            beginEdit(id)
            return .handled
        }
    }

    private var editor: some View {
        TextField("Title", text: $editText)
            .textFieldStyle(.plain)
            .focused($editFocused)
            .onSubmit(commitEdit)
            .onExitCommand { editingID = nil }
            .onChange(of: editFocused) { if !editFocused { commitEdit() } }
    }

    private func beginEdit(_ id: UUID) {
        guard let task = store.tasks.first(where: { $0.id == id }) else { return }
        editText = task.title
        editingID = id
        DispatchQueue.main.async { editFocused = true }
    }

    private func commitEdit() {
        guard let id = editingID else { return }
        editingID = nil
        store.rename(id, to: editText)
    }

    @ViewBuilder
    private func menu(for task: TaskItem) -> some View {
        Button("Rename") { beginEdit(task.id) }
        Picker("Priority", selection: Binding(
            get: { task.priority },
            set: { store.setPriority($0, for: task.id) }
        )) {
            ForEach(Priority.allCases.reversed()) { p in
                Text(p.name).tag(p)
            }
        }
        Menu("Tags") {
            ForEach(store.tags, id: \.self) { name in
                Toggle(name, isOn: Binding(
                    get: { task.tags.contains(name) },
                    set: { _ in store.toggleTag(name, for: task.id) }
                ))
            }
            Divider()
            Button("New Tag…") { tagTarget = task }
        }
        Divider()
        Button("Delete", role: .destructive) { store.delete(task.id) }
    }
}

/// A task's tags as small grey labels; clickable when `onTap` is given.
struct TagChips: View {
    let tags: [String]
    var onTap: ((String) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags, id: \.self) { tag in
                if let onTap {
                    Button { onTap(tag) } label: { chip(tag) }
                        .buttonStyle(.plain)
                        .help("Show only \(tag) tasks")
                } else {
                    chip(tag)
                }
            }
        }
        .accessibilityElement(children: onTap == nil ? .combine : .contain)
        .accessibilityLabel("Tags: \(tags.joined(separator: ", "))")
    }

    private func chip(_ tag: String) -> some View {
        Text(tag)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    var onTagTap: ((String) -> Void)?
    /// Shown instead of the title while renaming.
    var editor: AnyView?

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

            if let editor {
                editor
            } else {
                title
            }
            if !task.tags.isEmpty {
                Spacer(minLength: 8)
                TagChips(tags: task.tags, onTap: onTagTap)
            }
        }
        .padding(.vertical, 2)
    }

    private var title: some View {
        Text(task.title)
            .strikethrough(task.isDone)
            .foregroundStyle(task.isDone ? .secondary : .primary)
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
