import Foundation

/// Holds the tasks, tags and activity log, and saves them to JSON files after every change.
@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var events: [ActivityEvent] = []
    /// Known tag names in display order (offered in menus and Settings).
    @Published private(set) var tags: [String] = []
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

    /// Highest priority first; within a priority, the order tasks were added.
    var sortedTasks: [TaskItem] {
        tasks.enumerated()
            .sorted { ($0.element.priority, $1.offset) > ($1.element.priority, $0.offset) }
            .map(\.element)
    }

    /// Adds a task. Words like "!", "!!" or "!!!" set Low, Medium or High priority, and each "#word"
    /// adds that tag, creating it if it doesn't exist yet.
    func add(_ title: String) {
        let flat = title.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        let parsed = Self.parse(flat)
        guard !parsed.title.isEmpty else { return }
        var taskTags: [String] = []
        for tag in parsed.tags {
            if let name = addTag(Self.tagName(fromTag: tag)), !taskTags.contains(name) { taskTags.append(name) }
        }
        let task = TaskItem(title: parsed.title, priority: parsed.priority, tags: taskTags)
        tasks.append(task)
        log(.added, task)
        save()
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

    /// Adds a tag to the known list, or finds an existing one with the same name ignoring case.
    /// Returns the tag's name as stored, or nil if the name is blank.
    @discardableResult
    func addTag(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let existing = tags.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        tags.append(trimmed)
        save()
        return trimmed
    }

    /// Renames a tag everywhere. Refuses a blank name or one another tag uses.
    @discardableResult
    func renameTag(_ old: String, to new: String) -> Bool {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard let i = tags.firstIndex(of: old), !trimmed.isEmpty,
              !tags.contains(where: { $0 != old && $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return false }
        tags[i] = trimmed
        for j in tasks.indices {
            tasks[j].tags = tasks[j].tags.map { $0 == old ? trimmed : $0 }
        }
        save()
        return true
    }

    /// Deletes a tag and removes it from every task.
    func deleteTag(_ name: String) {
        tags.removeAll { $0 == name }
        for j in tasks.indices { tasks[j].tags.removeAll { $0 == name } }
        save()
    }

    func moveTag(from source: IndexSet, to destination: Int) {
        tags.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// Adds the tag to the task if it doesn't have it, otherwise removes it. Creates unknown tags.
    func toggleTag(_ name: String, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }), let tag = addTag(name) else { return }
        if tasks[i].tags.contains(tag) {
            tasks[i].tags.removeAll { $0 == tag }
        } else {
            tasks[i].tags.append(tag)
        }
        save()
    }

    func setPriority(_ priority: Priority, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[i].priority != priority else { return }
        tasks[i].priority = priority
        log(.priorityChanged, tasks[i], detail: priority.name)
        save()
    }

    func toggle(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].isDone.toggle()
        log(tasks[i].isDone ? .completed : .uncompleted, tasks[i])
        save()
    }

    func delete(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        log(.deleted, tasks.remove(at: i))
        save()
    }

    func clearDone() {
        tasks.filter(\.isDone).forEach { log(.deleted, $0) }
        tasks.removeAll(where: \.isDone)
        save()
    }

    private func log(_ kind: ActivityEvent.Kind, _ task: TaskItem, detail: String? = nil) {
        events.append(ActivityEvent(kind: kind, taskTitle: task.title, detail: detail, tags: task.tags))
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL) {
            tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        }
        if let data = (try? Data(contentsOf: tagsURL)) ?? (try? Data(contentsOf: legacySectionsURL)) {
            tags = (try? decoder.decode([String].self, from: data)) ?? Self.starterTags
        } else {
            tags = Self.starterTags
        }
        // A tag used on a task but missing from the list (e.g. a hand-edited file) is added to it.
        for name in tasks.flatMap(\.tags) where !tags.contains(name) { tags.append(name) }
        if let data = try? Data(contentsOf: activityURL) {
            events = (try? decoder.decode([ActivityEvent].self, from: data)) ?? []
        } else {
            // First launch with activity tracking: the only history we have is when tasks were added.
            events = tasks.sorted { $0.createdAt < $1.createdAt }
                .map { ActivityEvent(date: $0.createdAt, kind: .added, taskTitle: $0.title) }
        }
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
