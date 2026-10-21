import Foundation

/// Holds the tasks, tags and activity log, and saves them to JSON files after every change.
/// Every change goes through `change(_:_:)`, which also makes it undoable.
@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var events: [ActivityEvent] = []
    /// Known tag names in display order (offered in menus and Settings).
    @Published private(set) var tags: [String] = []
    /// Set by the window so ⌘Z / ⇧⌘Z work; nil in tests unless a test sets one.
    var undoManager: UndoManager?

    private let fileURL: URL
    private var activityURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Activity.json")
    }
    private var tagsURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Tags.json")
    }
    /// Written by the sections version of the app; read once to carry its names over as tags.
    private var legacySectionsURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Sections.json")
    }

    static let starterTags = ["Daily", "Fitness", "Work", "Study"]

    nonisolated static var defaultFileURL: URL {
        // For trying the app on sample data: `open "Super Simple Todo.app" --args -TasksFile /path/Tasks.json`
        if let path = UserDefaults.standard.string(forKey: "TasksFile") {
            return URL(fileURLWithPath: path)
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Super Simple Todo", isDirectory: true)
            .appendingPathComponent("Tasks.json")
    }

    init(fileURL: URL = TaskStore.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    var doneCount: Int { tasks.filter(\.isDone).count }

    /// Open tasks first, then done ones; within each, highest priority first, then the order added.
    var sortedTasks: [TaskItem] {
        tasks.enumerated()
            .sorted {
                ($1.element.isDone ? 1 : 0, $0.element.priority, $1.offset)
                    > ($0.element.isDone ? 1 : 0, $1.element.priority, $0.offset)
            }
            .map(\.element)
    }

    /// The tasks the list shows: sorted, optionally without done ones, optionally only one tag's.
    func visibleTasks(hideDone: Bool, tag: String?) -> [TaskItem] {
        sortedTasks.filter { (!hideDone || !$0.isDone) && (tag == nil || $0.tags.contains(tag!)) }
    }

    // MARK: Tasks

    /// Adds a task. Words like "!", "!!" or "!!!" set Low, Medium or High priority, and each "#word"
    /// adds that tag, creating it if it doesn't exist yet.
    func add(_ title: String) {
        let parsed = Self.parse(Self.flatten(title))
        guard !parsed.title.isEmpty else { return }
        change("Add Task") {
            let task = TaskItem(title: parsed.title, priority: parsed.priority,
                                tags: parsed.tags.compactMap { ensureTag(Self.tagName(fromTag: $0)) }.uniqued())
            tasks.append(task)
            log(.added, task)
        }
    }

    /// Changes a task's title. "#tags" in the new text are added, and "!" markers set the priority.
    func rename(_ id: UUID, to text: String) {
        let parsed = Self.parse(Self.flatten(text))
        guard let i = tasks.firstIndex(where: { $0.id == id }), !parsed.title.isEmpty else { return }
        let newTags = parsed.tags.map { Self.tagName(fromTag: $0) }
        let samePriority = parsed.priority == .none || parsed.priority == tasks[i].priority
        guard parsed.title != tasks[i].title || !newTags.isEmpty || !samePriority else { return }
        change("Edit Task") {
            tasks[i].title = parsed.title
            for name in newTags.compactMap(ensureTag) where !tasks[i].tags.contains(name) {
                tasks[i].tags.append(name)
            }
            if !samePriority {
                tasks[i].priority = parsed.priority
                log(.priorityChanged, tasks[i], detail: parsed.priority.name)
            }
        }
    }

    func setPriority(_ priority: Priority, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }), tasks[i].priority != priority else { return }
        change("Change Priority") {
            tasks[i].priority = priority
            log(.priorityChanged, tasks[i], detail: priority.name)
        }
    }

    func toggle(_ id: UUID) {
        toggle(Set([id]))
    }

    /// Ticks or unticks tasks. If any of them is open, all become done; otherwise all reopen.
    func toggle(_ ids: Set<UUID>) {
        let indices = tasks.indices.filter { ids.contains(tasks[$0].id) }
        guard !indices.isEmpty else { return }
        let markDone = indices.contains { !tasks[$0].isDone }
        change(markDone ? "Complete" : "Untick") {
            for i in indices where tasks[i].isDone != markDone {
                tasks[i].isDone = markDone
                log(markDone ? .completed : .uncompleted, tasks[i])
            }
        }
    }

    func delete(_ id: UUID) {
        delete(Set([id]))
    }

    func delete(_ ids: Set<UUID>) {
        guard tasks.contains(where: { ids.contains($0.id) }) else { return }
        change(ids.count == 1 ? "Delete Task" : "Delete Tasks") {
            tasks.filter { ids.contains($0.id) }.forEach { log(.deleted, $0) }
            tasks.removeAll { ids.contains($0.id) }
        }
    }

    func clearDone() {
        guard doneCount > 0 else { return }
        change("Clear Done") {
            tasks.filter(\.isDone).forEach { log(.deleted, $0) }
            tasks.removeAll(where: \.isDone)
        }
    }

    // MARK: Tags

    /// Adds a tag to the known list, or finds an existing one with the same name ignoring case.
    /// Returns the tag's name as stored, or nil if the name is blank.
    @discardableResult
    func addTag(_ name: String) -> String? {
        var result: String?
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) || trimmed.isEmpty {
            return ensureTag(trimmed)
        }
        change("Add Tag") { result = ensureTag(trimmed) }
        return result
    }

    /// Renames a tag everywhere. Refuses a blank name or one another tag uses.
    @discardableResult
    func renameTag(_ old: String, to new: String) -> Bool {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard let i = tags.firstIndex(of: old), !trimmed.isEmpty, trimmed != old,
              !tags.contains(where: { $0 != old && $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return false }
        change("Rename Tag") {
            tags[i] = trimmed
            for j in tasks.indices {
                tasks[j].tags = tasks[j].tags.map { $0 == old ? trimmed : $0 }
            }
        }
        return true
    }

    /// Deletes a tag and removes it from every task.
    func deleteTag(_ name: String) {
        change("Delete Tag") {
            tags.removeAll { $0 == name }
            for j in tasks.indices { tasks[j].tags.removeAll { $0 == name } }
        }
    }

    func moveTag(from source: IndexSet, to destination: Int) {
        change("Move Tag") { tags.move(fromOffsets: source, toOffset: destination) }
    }

    /// Adds the tag to the task if it doesn't have it, otherwise removes it. Creates unknown tags.
    func toggleTag(_ name: String, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        change("Change Tags") {
            guard let tag = ensureTag(name) else { return }
            if tasks[i].tags.contains(tag) {
                tasks[i].tags.removeAll { $0 == tag }
            } else {
                tasks[i].tags.append(tag)
            }
        }
    }

    // MARK: History

    /// Replaces a logged action with an edited copy (same id). Doesn't touch any task.
    func updateEvent(_ event: ActivityEvent) {
        guard let i = events.firstIndex(where: { $0.id == event.id }), events[i] != event else { return }
        change("Edit History") {
            var edited = event
            edited.taskTitle = Self.flatten(event.taskTitle)
            edited.tags = event.tags.compactMap(ensureTag).uniqued()
            events[i] = edited
            events.sort { $0.date < $1.date }
        }
    }

    /// Deletes logged actions. Doesn't touch any task.
    func deleteEvents(_ ids: Set<UUID>) {
        guard events.contains(where: { ids.contains($0.id) }) else { return }
        change("Delete History") { events.removeAll { ids.contains($0.id) } }
    }

    /// Deletes the whole activity log. Doesn't touch any task.
    func clearHistory() {
        guard !events.isEmpty else { return }
        change("Clear History") { events.removeAll() }
    }

    // MARK: Parsing

    static func flatten(_ text: String) -> String {
        text.components(separatedBy: .newlines).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    /// Splits typed text into a title, a priority ("!"/"!!"/"!!!" words) and tags ("#" followed by
    /// a letter). If nothing but markers was typed, the text is kept as the title.
    static func parse(_ text: String) -> (title: String, priority: Priority, tags: [String]) {
        var words: [Substring] = []
        var priority = Priority.none
        var tags: [String] = []
        for word in text.split(separator: " ") {
            if (1...3).contains(word.count), word.allSatisfy({ $0 == "!" }) {
                priority = Priority(rawValue: word.count)!
            } else if word.first == "#", word.dropFirst().first?.isLetter == true {
                tags.append(String(word.dropFirst()))
            } else {
                words.append(word)
            }
        }
        if words.isEmpty { return (text, .none, []) }
        return (words.joined(separator: " "), priority, tags)
    }

    /// "#deep-work" -> "Deep work".
    static func tagName(fromTag tag: String) -> String {
        let spaced = tag.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }

    // MARK: Changes, undo and saving

    private struct Snapshot {
        var tasks: [TaskItem], events: [ActivityEvent], tags: [String]
    }

    /// Runs a change, saves, and registers an undo step that restores the state from before it.
    private func change(_ actionName: String, _ body: () -> Void) {
        let before = Snapshot(tasks: tasks, events: events, tags: tags)
        body()
        registerUndo(restoring: before, actionName: actionName)
        save()
    }

    /// Restores a snapshot, registering the opposite step so undo and redo alternate.
    private func registerUndo(restoring snapshot: Snapshot, actionName: String) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                let current = Snapshot(tasks: store.tasks, events: store.events, tags: store.tags)
                store.tasks = snapshot.tasks
                store.events = snapshot.events
                store.tags = snapshot.tags
                store.registerUndo(restoring: current, actionName: actionName)
                store.save()
            }
        }
        undoManager.setActionName(actionName)
    }

    /// The stored name for a tag, adding it to the known list if it's new. Call inside `change`.
    private func ensureTag(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let existing = tags.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        tags.append(trimmed)
        return trimmed
    }

    private func log(_ kind: ActivityEvent.Kind, _ task: TaskItem, detail: String? = nil) {
        events.append(ActivityEvent(kind: kind, taskTitle: task.title, detail: detail, tags: task.tags))
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        tasks = read([TaskItem].self, from: fileURL, decoder) ?? []
        if let saved = read([String].self, from: tagsURL, decoder) ?? read([String].self, from: legacySectionsURL, decoder) {
            tags = saved
        } else {
            tags = Self.starterTags
        }
        // A tag used on a task but missing from the list (e.g. a hand-edited file) is added to it.
        for name in tasks.flatMap(\.tags) where !tags.contains(name) { tags.append(name) }
        if let saved = read([ActivityEvent].self, from: activityURL, decoder) {
            events = saved
        } else {
            // First launch with activity tracking: the only history we have is when tasks were added.
            events = tasks.sorted { $0.createdAt < $1.createdAt }
                .map { ActivityEvent(date: $0.createdAt, kind: .added, taskTitle: $0.title) }
        }
    }

    /// Reads a JSON file. A file that exists but can't be read is renamed to
    /// "<name>.unreadable-<date>.json" so the next save can't overwrite it.
    private func read<T: Decodable>(_ type: T.Type, from url: URL, _ decoder: JSONDecoder) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let value = try? decoder.decode(type, from: data) { return value }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backup = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: backup)
        NSLog("Super Simple Todo: \(url.lastPathComponent) couldn't be read; kept it as \(backup.lastPathComponent)")
        return nil
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(tasks).write(to: fileURL, options: .atomic)
            try encoder.encode(events).write(to: activityURL, options: .atomic)
            try encoder.encode(tags).write(to: tagsURL, options: .atomic)
        } catch {
            NSLog("Super Simple Todo: could not save tasks: \(error)")
        }
    }
}

extension Array where Element: Hashable {
    /// The elements in order, without repeats.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
