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
            TasksView(isActive: tab == "tasks").tabItem { Text("Tasks") }.tag("tasks")
            CalendarView().tabItem { Text("Calendar") }.tag("calendar")
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
    /// False while another tab is showing, so menu shortcuts don't change tasks you can't see.
    var isActive = true
    @EnvironmentObject private var store: TaskStore
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false
    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool
    @FocusState private var listFocused: Bool
    @State private var selection = Set<UUID>()
    @State private var tagFilter = TagFilter()
    /// The task being renamed in place, and its text.
    @State private var editingID: UUID?
    @State private var editText = ""
    @FocusState private var editFocused: Bool
    /// The task the "New Tag…" prompt is adding a tag to.
    @State private var tagTarget: TaskItem?
    @State private var newTagName = ""
    /// The task the "Pick a Date…" sheet is setting a deadline for.
    @State private var deadlineTarget: TaskItem?
    /// The task the "Add Link…" prompt is for, and the typed address.
    @State private var linkTarget: TaskItem?
    @State private var linkText = ""
    @Environment(\.openURL) private var openURL

    private var visibleTasks: [TaskItem] {
        tagFilter.apply(to: store.sortedTasks, hideDone: hideDoneTasks)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Shown briefly after the last open task is ticked.
    @State private var celebrating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GreetingHeader(done: store.doneCount, total: store.tasks.count)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            AddTaskField(text: $newTitle, focused: $inputFocused, tags: store.tags, tasks: store.tasks, onSubmit: {
                store.add(newTitle)
                newTitle = ""
            }, onMoveDown: { move(.down) }, onEscape: { tagFilter.clear() })
            .padding(.horizontal, 16)
            .zIndex(1)   // the tag suggestions float over the list below

            PriorityKey()
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 4)

            if let tag = tagFilter.tag {
                HStack(spacing: 6) {
                    Text("Showing")
                    FilterToken(tag: tag) { tagFilter.clear() }
                    Spacer()
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)
                .padding(.bottom, 4)
            }

            if visibleTasks.isEmpty {
                emptyState
            } else {
                list
            }

            HStack {
                Spacer()
                Button {
                    store.clearDone()
                } label: {
                    Label("Clear Done", systemImage: "sparkles")
                }
                .buttonStyle(.borderless)
                .disabled(store.doneCount == 0)
                .help("Remove finished tasks (⇧⌘⌫)")
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Settings")
                .help("Settings (⌘,)")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Theme.background)
        .overlay(alignment: .bottom) {
            if celebrating {
                Label("All done — nice work!", systemImage: "party.popper")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.card, in: Capsule())
                    .overlay(Capsule().stroke(Theme.cardStroke))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: store.doneCount) { old, new in
            // Celebrate only the moment the last open task gets ticked.
            guard new > old, new == store.tasks.count, new > 0 else { return }
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4)) { celebrating = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4)) { celebrating = false }
            }
        }
        .alert(linkTarget?.link == nil ? "Add Link" : "Edit Link",
               isPresented: Binding(get: { linkTarget != nil }, set: { if !$0 { linkTarget = nil } })) {
            TextField("https://…", text: $linkText)
            Button("Save") {
                if let task = linkTarget, !store.setLink(linkText, for: task.id) { NSSound.beep() }
                linkText = ""
            }
            Button("Cancel", role: .cancel) { linkText = "" }
        } message: {
            Text("A page that helps with \u{201C}\(linkTarget?.title ?? "")\u{201D}. It shows under the task as its next step.")
        }
        .sheet(item: $deadlineTarget) { task in
            DeadlinePicker(task: task) { store.setDeadline($0, for: task.id) }
        }
        .onAppear { inputFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .newTask)) { _ in inputFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .setPriority)) { note in
            guard isActive, let priority = note.object as? Priority else { return }
            guard !selection.isEmpty else { return NSSound.beep() }
            store.setPriority(priority, for: selection)
        }
        .onChange(of: visibleTasks.map(\.id)) { old, new in
            selection = ListNavigation.reconcile(selection, old: old, new: new)
        }
        .onChange(of: store.tags) { tagFilter.keepOnly(knownTags: store.tags) }
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

    @ViewBuilder
    private var emptyState: some View {
        if store.tasks.isEmpty {
            EmptyState(symbol: "leaf", title: "A fresh start",
                       message: "Type a task above and press Return.\nTry \u{201C}Water the plants #daily !\u{201D}")
        } else if tagFilter.isActive {
            EmptyState(symbol: "tag", title: "Nothing here yet",
                       message: "No open tasks with this tag.")
        } else {
            EmptyState(symbol: "sun.max", title: "All clear",
                       message: "Everything's done. Enjoy the rest of your day.")
        }
    }

    /// Ticks with a gentle spring, so the row eases into the done area instead of jumping.
    private func toggle(_ ids: Set<UUID>) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.2)) { store.toggle(ids) }
    }

    /// ↑ / ↓ from the list or the add field.
    private func move(_ direction: ListNavigation.Direction) {
        switch ListNavigation.move(direction, from: selection, in: visibleTasks.map(\.id)) {
        case .select(let id):
            selection = [id]
            listFocused = true
        case .addField:
            selection = []
            inputFocused = true
        case .none:
            break
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(visibleTasks) { task in
                TaskRow(task: task,
                        isSelected: selection.contains(task.id),
                        onToggle: { toggle([task.id]) },
                        onRename: { beginEdit(task.id) },
                        onTagTap: { tag in tagFilter.toggle(tag) },
                        editor: editingID == task.id ? AnyView(editor) : nil)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .fill(selection.contains(task.id) ? Color.accentColor.opacity(0.14) : Theme.card)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
                                .stroke(selection.contains(task.id) ? Color.accentColor.opacity(0.5) : Theme.cardStroke))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 12)
                    )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .focused($listFocused)
        .contextMenu(forSelectionType: UUID.self) { ids in
            if ids.count == 1, let task = store.tasks.first(where: { $0.id == ids.first }) {
                menu(for: task)
            } else if !ids.isEmpty {
                Button("Tick or Untick \(ids.count) Tasks") { toggle(ids) }
                Button("Delete \(ids.count) Tasks", role: .destructive) { store.delete(ids) }
            }
        } primaryAction: { ids in
            if ids.count == 1, let id = ids.first { beginEdit(id) }
        }
        .onDeleteCommand { store.delete(selection) }
        .onKeyPress(.space) {
            guard editingID == nil, !selection.isEmpty else { return .ignored }
            toggle(selection)
            return .handled
        }
        .onKeyPress(.return) {
            guard editingID == nil else { return .ignored }
            if selection.isEmpty {
                inputFocused = true
            } else if selection.count == 1, let id = selection.first {
                beginEdit(id)
            } else {
                return .ignored
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard editingID == nil else { return .ignored }
            move(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard editingID == nil else { return .ignored }
            move(.down)
            return .handled
        }
        .onKeyPress(.escape) {
            guard editingID == nil, tagFilter.isActive else { return .ignored }
            tagFilter.clear()
            return .handled
        }
    }

    private var editor: some View {
        TextField("Title", text: $editText)
            .textFieldStyle(.plain)
            .focused($editFocused)
            .onSubmit { commitEdit(); listFocused = true }
            .onExitCommand { editingID = nil; listFocused = true }
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
        Button(task.link == nil ? "Add Link…" : "Edit Link…") {
            linkText = task.link?.absoluteString ?? ""
            linkTarget = task
        }
        if task.link != nil {
            Button("Remove Link") { store.setLink(nil, for: task.id) }
        }
        Button("Ask Claude How to Start") { openURL(NextStep.claudeURL(for: task)) }
        Divider()
        Picker("Priority", selection: Binding(
            get: { task.priority },
            set: { store.setPriority($0, for: task.id) }
        )) {
            ForEach(Priority.allCases.reversed()) { p in
                Text(p.name).tag(p)
            }
        }
        Menu("Deadline") {
            let today = Calendar.current.startOfDay(for: Date())
            Button("Today") { store.setDeadline(today, for: task.id) }
            Button("Tomorrow") { store.setDeadline(Calendar.current.date(byAdding: .day, value: 1, to: today), for: task.id) }
            Button("In a Week") { store.setDeadline(Calendar.current.date(byAdding: .day, value: 7, to: today), for: task.id) }
            Button("Pick a Date…") { deadlineTarget = task }
            if task.deadline != nil {
                Divider()
                Button("Remove Deadline") { store.setDeadline(nil, for: task.id) }
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

/// The tag the list is filtered to, as a removable token.
struct FilterToken: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill").imageScale(.small)
            Text(tag).lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Show all tasks (Esc)")
            .accessibilityLabel("Remove \(tag) filter")
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(Color.accentColor)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, 2)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Color.accentColor.opacity(0.35)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Showing only \(tag) tasks")
        .accessibilityAction(named: "Show All Tasks", onRemove)
    }
}

struct TaskRow: View {
    let task: TaskItem
    var isSelected = false
    let onToggle: () -> Void
    var onRename: (() -> Void)?
    var onTagTap: ((String) -> Void)?
    /// Shown instead of the title while renaming.
    var editor: AnyView?
    /// True once the pointer has rested on the row briefly (so sweeping past doesn't flicker).
    @State private var hoverSettled = false
    @State private var hoverTask: Task<Void, Never>?

    private var showsClaude: Bool {
        !task.isDone && task.link == nil && editor == nil && (isSelected || hoverSettled)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(circleColor)
                    .imageScale(.large)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: task.isDone)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark not done" : "Mark done")
            .accessibilityValue(task.priority == .none ? "" : "\(task.priority.name) priority")
            .help(task.priority == .none ? "No priority" : "\(task.priority.name) priority")

            VStack(alignment: .leading, spacing: 3) {
                if let editor {
                    editor
                } else {
                    title
                }
                if let link = task.link {
                    Link(destination: link) {
                        Label(NextStep.linkLabel(link), systemImage: "arrow.up.right")
                    }
                    .help(link.absoluteString)
                    .nextStepStyle()
                } else if showsClaude {
                    Link(destination: NextStep.claudeURL(for: task)) {
                        Label("Ask Claude how to start", systemImage: "sparkle")
                    }
                    .help(NextStep.claudeAppInstalled ? "Opens a new chat about this task in the Claude app"
                                                      : "Opens a new Claude chat about this task in your browser")
                    .nextStepStyle()
                    .transition(.opacity)
                }
            }
            if task.deadline != nil || !task.tags.isEmpty {
                Spacer(minLength: 8)
            }
            if let deadline = task.deadline {
                DeadlineLabel(deadline: deadline, isDone: task.isDone)
            }
            if !task.tags.isEmpty {
                TagChips(tags: task.tags, onTap: onTagTap)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        // VoiceOver reads one card as "Title, Not done. High priority. Tags: …", with the
        // circle, rename, link and tag clicks as actions. While renaming, the field stays reachable.
        .accessibilityElement(children: editor == nil ? .ignore : .contain)
        .accessibilityLabel(task.title)
        .accessibilityValue(Self.accessibilityValue(for: task))
        .accessibilityAction { onToggle() }
        .accessibilityAction(named: task.isDone ? "Mark Not Done" : "Mark Done") { onToggle() }
        .accessibilityActions {
            if let onRename { Button("Rename", action: onRename) }
            if let link = task.link {
                Button(NextStep.linkLabel(link)) { NSWorkspace.shared.open(link) }
            } else if !task.isDone {
                Button("Ask Claude How to Start") { NSWorkspace.shared.open(NextStep.claudeURL(for: task)) }
            }
            if let onTagTap {
                ForEach(task.tags, id: \.self) { tag in
                    Button("Show Only \(tag) Tasks") { onTagTap(tag) }
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: showsClaude)
        .onHover { inside in
            hoverTask?.cancel()
            if inside {
                hoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    if !Task.isCancelled { hoverSettled = true }
                }
            } else {
                hoverSettled = false
            }
        }
    }

    /// What VoiceOver says after the title: done state, priority, tags, deadline and next step.
    static func accessibilityValue(for task: TaskItem, now: Date = Date(), calendar: Calendar = .current) -> String {
        var parts = [task.isDone ? "Done" : "Not done",
                     task.priority == .none ? "No priority" : "\(task.priority.name) priority"]
        if !task.tags.isEmpty { parts.append("Tags: \(task.tags.joined(separator: ", "))") }
        if let deadline = task.deadline {
            parts.append(DeadlineLabel.spokenText(for: deadline, isDone: task.isDone, now: now, calendar: calendar))
        }
        if let link = task.link { parts.append("Next step: \(NextStep.linkLabel(link))") }
        return parts.joined(separator: ". ")
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
        .foregroundStyle(.tertiary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Circle colors: red High, orange Medium, blue Low, grey None")
    }
}

/// "Good morning" plus a friendly progress line and a small ring.
struct GreetingHeader: View {
    let done: Int
    let total: Int

    private var greeting: (text: String, symbol: String) {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: ("Good morning", "sun.horizon")
        case 12..<17: ("Good afternoon", "sun.max")
        case 17..<22: ("Good evening", "sun.haze")
        default: ("Hello, night owl", "moon.stars")
        }
    }

    private var progressLine: String {
        switch (done, total) {
        case (_, 0): "Nothing on your list yet."
        case (0, _): "\(total) to go. Let's get started."
        case let (d, t) where d == t: "All \(t) done. Lovely."
        case let (d, t): "\(d) of \(t) done. Nice going."
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Label(greeting.text, systemImage: greeting.symbol)
                    .font(.title2.weight(.semibold))
                    .labelStyle(GreetingLabelStyle())
                Text(progressLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if total > 0 {
                ProgressRing(fraction: Double(done) / Double(total))
                    .frame(width: 34, height: 34)
                    .accessibilityLabel("\(done) of \(total) done")
            }
        }
    }
}

private struct GreetingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(.orange)
            configuration.title
        }
    }
}

struct ProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(Theme.cardStroke, lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: fraction)
            if fraction >= 1 {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

/// The rounded "Add a task" field with a plus icon. Typing "#" offers known tags below it.
struct AddTaskField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    /// Known tags and the tasks that use them, for the "#" suggestions.
    var tags: [String] = []
    var tasks: [TaskItem] = []
    let onSubmit: () -> Void
    /// ↓ in the field moves into the list.
    var onMoveDown: () -> Void = {}
    /// Esc with no suggestions showing.
    var onEscape: () -> Void = {}
    @State private var highlighted = 0
    /// The text when Esc closed the suggestions; they stay closed until it changes.
    @State private var dismissedText: String?

    private var query: String? {
        guard focused.wrappedValue, dismissedText != text else { return nil }
        return TagAutocomplete.activeQuery(in: text)?.query
    }

    private var suggestions: [String] {
        query.map { TagAutocomplete.suggestions(for: $0, tags: tags, tasks: tasks) } ?? []
    }

    private var current: String? {
        let list = suggestions
        return list.isEmpty ? nil : list[min(highlighted, list.count - 1)]
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.accentColor)
                .imageScale(.large)
            TextField("Add a task  (#tag  !priority  @day  link)", text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .onSubmit(onSubmit)
                .onKeyPress(.downArrow) {
                    if suggestions.isEmpty { onMoveDown() } else { highlighted = min(highlighted + 1, suggestions.count - 1) }
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    guard !suggestions.isEmpty else { return .ignored }
                    highlighted = max(highlighted - 1, 0)
                    return .handled
                }
                .onKeyPress(.tab) {
                    guard let current else { return .ignored }
                    accept(current)
                    return .handled
                }
                .onKeyPress(.return) {
                    // A tag already typed in full leaves Return to add the task.
                    guard let current, let query, !TagAutocomplete.isTyped(current, as: query) else { return .ignored }
                    accept(current)
                    return .handled
                }
                .onKeyPress(.escape) {
                    if suggestions.isEmpty { onEscape() } else { dismissedText = text }
                    return .handled
                }
                .onChange(of: text) { highlighted = 0 }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
            .stroke(focused.wrappedValue ? Color.accentColor.opacity(0.6) : Theme.cardStroke))
        .help("Add #tag to tag it (a new #name makes a new tag), !, !! or !!! for Low, Medium or High priority, @today, @fri or @oct30 for a deadline, and paste a link to make it the next step")
        .overlay(alignment: .bottomLeading) {
            if !suggestions.isEmpty {
                TagSuggestions(tags: suggestions, counts: TagAutocomplete.useCounts(in: tasks),
                               highlighted: min(highlighted, suggestions.count - 1), onPick: accept)
                    .padding(.leading, 30)
                    .alignmentGuide(.bottom) { $0[.top] - 4 }
            }
        }
    }

    private func accept(_ tag: String) {
        text = TagAutocomplete.accept(tag, in: text)
        dismissedText = nil
    }
}

/// The "#" autocomplete: matching tags, most used first, with how many tasks use each.
struct TagSuggestions: View {
    let tags: [String]
    let counts: [String: Int]
    let highlighted: Int
    let onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(tags.enumerated()), id: \.element) { index, tag in
                Button { onPick(tag) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "number").imageScale(.small).foregroundStyle(.secondary)
                        Text(tag).lineLimit(1)
                        Spacer(minLength: 16)
                        Text("\(counts[tag] ?? 0)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(index == highlighted ? Color.accentColor.opacity(0.18) : .clear,
                                in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tag)
                .accessibilityValue("\(counts[tag] ?? 0) tasks")
                .accessibilityAddTraits(index == highlighted ? .isSelected : [])
            }
            Text("Tab or Return to add · Esc to close")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
        .font(.callout)
        .padding(5)
        .frame(minWidth: 180, maxWidth: 240, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardStroke))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tag suggestions")
    }
}

/// A calm, friendly message for an empty list.
struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.orange.opacity(0.8))
                .symbolEffect(.pulse, options: .nonRepeating)
            Text(title).font(.title3.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

/// "Overdue", "Today", "Tomorrow", a weekday within the next week, or a short date.
struct DeadlineLabel: View {
    let deadline: Date
    let isDone: Bool

    static func text(for deadline: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: deadline)).day ?? 0
        switch days {
        case ..<0: return "Overdue"
        case 0: return "Today"
        case 1: return "Tomorrow"
        case 2...6: return deadline.formatted(.dateTime.weekday(.abbreviated))
        default: return deadline.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// "Due October 30, 2026", or "Overdue, was due …" for an open task past its day.
    static func spokenText(for deadline: Date, isDone: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let date = deadline.formatted(date: .long, time: .omitted)
        return !isDone && deadline < calendar.startOfDay(for: now) ? "Overdue, was due \(date)" : "Due \(date)"
    }

    private var isOverdue: Bool { !isDone && deadline < Calendar.current.startOfDay(for: Date()) }
    private var isToday: Bool { Calendar.current.isDateInToday(deadline) }

    var body: some View {
        Label(Self.text(for: deadline), systemImage: isOverdue ? "exclamationmark.circle" : "calendar")
            .labelStyle(DeadlineLabelStyle())
            .font(.caption.weight(isOverdue || isToday ? .semibold : .regular))
            .foregroundStyle(isDone ? AnyShapeStyle(.tertiary) : isOverdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            .help("Due \(deadline.formatted(date: .complete, time: .omitted))")
            .accessibilityLabel(Self.spokenText(for: deadline, isDone: isDone))
    }
}

private struct DeadlineLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) { configuration.icon; configuration.title }
    }
}

/// A small sheet with a calendar for choosing a deadline.
struct DeadlinePicker: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    let onSave: (Date?) -> Void
    @State private var date: Date

    init(task: TaskItem, onSave: @escaping (Date?) -> Void) {
        self.task = task
        self.onSave = onSave
        _date = State(initialValue: task.deadline ?? Calendar.current.startOfDay(for: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deadline for \u{201C}\(task.title)\u{201D}").font(.headline)
            DatePicker("Deadline", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
            HStack {
                if task.deadline != nil {
                    Button("Remove Deadline") { onSave(nil); dismiss() }
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Set Deadline") { onSave(date); dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

/// A task's next step: its own link, or a new Claude chat about it.
enum NextStep {
    /// "Open toyotafinancial.com"
    static func linkLabel(_ url: URL) -> String {
        var host = url.host() ?? url.absoluteString
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return "Open \(host)"
    }

    /// True when the Claude desktop app is installed to handle claude:// links.
    static var claudeAppInstalled: Bool {
        NSWorkspace.shared.urlForApplication(toOpen: URL(string: "claude://claude.ai/new")!) != nil
    }

    /// A link that starts a new Claude chat with a message about the task already typed in. It opens
    /// in the Claude app when installed (claude://claude.ai/new?q=…), otherwise claude.ai in the
    /// browser. Nothing is sent until you press send.
    static func claudeURL(for task: TaskItem, inApp: Bool = claudeAppInstalled) -> URL {
        var prompt = "I want to get this done: \u{201C}\(task.title)\u{201D}."
        if let deadline = task.deadline {
            prompt += " It's due \(deadline.formatted(date: .long, time: .omitted))."
        }
        prompt += " What's the first concrete step, and can you guide me through it?"
        var parts = URLComponents(string: inApp ? "claude://claude.ai/new" : "https://claude.ai/new")!
        parts.queryItems = [URLQueryItem(name: "q", value: prompt)]
        return parts.url!
    }
}

private extension View {
    func nextStepStyle() -> some View {
        font(.caption)
            .labelStyle(NextStepLabelStyle())
            .foregroundStyle(Color.accentColor)
            .buttonStyle(.plain)
    }
}

private struct NextStepLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) { configuration.icon.imageScale(.small); configuration.title }
    }
}
