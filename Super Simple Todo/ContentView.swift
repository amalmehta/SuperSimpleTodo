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
    /// The task the "Pick a Date…" sheet is setting a deadline for.
    @State private var deadlineTarget: TaskItem?
    /// The task the "Add Link…" prompt is for, and the typed address.
    @State private var linkTarget: TaskItem?
    @State private var linkText = ""
    @Environment(\.openURL) private var openURL

    private var visibleTasks: [TaskItem] {
        store.visibleTasks(hideDone: hideDoneTasks, tag: tagFilter)
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

            AddTaskField(text: $newTitle, focused: $inputFocused) {
                store.add(newTitle)
                newTitle = ""
            }
            .padding(.horizontal, 16)

            PriorityKey()
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 4)

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

    @ViewBuilder
    private var emptyState: some View {
        if store.tasks.isEmpty {
            EmptyState(symbol: "leaf", title: "A fresh start",
                       message: "Type a task above and press Return.\nTry \u{201C}Water the plants #daily !\u{201D}")
        } else if tagFilter != nil {
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

    private var list: some View {
        List(selection: $selection) {
            ForEach(visibleTasks) { task in
                TaskRow(task: task,
                        isSelected: selection.contains(task.id),
                        onToggle: { toggle([task.id]) },
                        onTagTap: { tag in tagFilter = (tagFilter == tag ? nil : tag) },
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

struct TaskRow: View {
    let task: TaskItem
    var isSelected = false
    let onToggle: () -> Void
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

/// The rounded "Add a task" field with a plus icon.
struct AddTaskField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.accentColor)
                .imageScale(.large)
            TextField("Add a task  (#tag  !priority  @day  link)", text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
            .stroke(focused.wrappedValue ? Color.accentColor.opacity(0.6) : Theme.cardStroke))
        .help("Add #tag to tag it (a new #name makes a new tag), !, !! or !!! for Low, Medium or High priority, @today, @fri or @oct30 for a deadline, and paste a link to make it the next step")
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

    private var isOverdue: Bool { !isDone && deadline < Calendar.current.startOfDay(for: Date()) }
    private var isToday: Bool { Calendar.current.isDateInToday(deadline) }

    var body: some View {
        Label(Self.text(for: deadline), systemImage: isOverdue ? "exclamationmark.circle" : "calendar")
            .labelStyle(DeadlineLabelStyle())
            .font(.caption.weight(isOverdue || isToday ? .semibold : .regular))
            .foregroundStyle(isDone ? AnyShapeStyle(.tertiary) : isOverdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            .help("Due \(deadline.formatted(date: .complete, time: .omitted))")
            .accessibilityLabel(isOverdue ? "Overdue, was due \(deadline.formatted(date: .long, time: .omitted))"
                                          : "Due \(deadline.formatted(date: .long, time: .omitted))")
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
