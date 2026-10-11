import Foundation

/// Holds the tasks, sections and activity log, and saves them to JSON files after every change.
@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var events: [ActivityEvent] = []
    /// Section names in display order.
    @Published private(set) var sections: [String] = []
    private let fileURL: URL
    private var activityURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Activity.json")
    }
    private var sectionsURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Sections.json")
    }

    static let starterSections = ["Daily", "Fitness", "Work", "Study"]

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

    /// Sections in order, each with its tasks sorted by priority, then "Other" (nil) for unfiled tasks.
    /// Sections with no tasks are left out.
    func grouped(_ visible: [TaskItem]) -> [(section: String?, tasks: [TaskItem])] {
        let groups: [String?] = sections.map { $0 } + [nil]
        return groups.compactMap { name in
            let inGroup = visible.filter { $0.section == name }
            return inGroup.isEmpty ? nil : (name, inGroup)
        }
    }

    /// Adds a task. Words like "!", "!!" or "!!!" set Low, Medium or High priority, and a "#word"
    /// files it under that section, creating the section if it doesn't exist yet.
    func add(_ title: String) {
        let flat = title.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        let parsed = Self.parse(flat)
        guard !parsed.title.isEmpty else { return }
        let section = parsed.tag.map { addSection(Self.sectionName(fromTag: $0)) }
        let task = TaskItem(title: parsed.title, priority: parsed.priority, section: section ?? nil)
        tasks.append(task)
        log(.added, task)
        save()
    }

    /// Splits typed text into a title, a priority ("!"/"!!"/"!!!" words) and a section tag
    /// ("#" followed by a letter). If nothing but markers was typed, the text is kept as the title.
    static func parse(_ text: String) -> (title: String, priority: Priority, tag: String?) {
        var words: [Substring] = []
        var priority = Priority.none
        var tag: String?
        for word in text.split(separator: " ") {
            if (1...3).contains(word.count), word.allSatisfy({ $0 == "!" }) {
                priority = Priority(rawValue: word.count)!
            } else if word.first == "#", word.dropFirst().first?.isLetter == true {
                if tag == nil { tag = String(word.dropFirst()) }
            } else {
                words.append(word)
            }
        }
        if words.isEmpty { return (text, .none, nil) }
        return (words.joined(separator: " "), priority, tag)
    }

    /// "#deep-work" -> "Deep work".
    static func sectionName(fromTag tag: String) -> String {
        let spaced = tag.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }

    /// Adds a section, or finds an existing one with the same name ignoring case.
    /// Returns the section's name as stored, or nil if the name is blank.
    @discardableResult
    func addSection(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let existing = sections.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        sections.append(trimmed)
        save()
        return trimmed
    }

    /// Renames a section and every task in it. Refuses a blank name or one another section uses.
    @discardableResult
    func renameSection(_ old: String, to new: String) -> Bool {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard let i = sections.firstIndex(of: old), !trimmed.isEmpty,
              !sections.contains(where: { $0 != old && $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return false }
        sections[i] = trimmed
        for j in tasks.indices where tasks[j].section == old { tasks[j].section = trimmed }
        save()
        return true
    }

    /// Deletes a section; its tasks move to "Other".
    func deleteSection(_ name: String) {
        sections.removeAll { $0 == name }
        for j in tasks.indices where tasks[j].section == name { tasks[j].section = nil }
        save()
    }

    func moveSection(from source: IndexSet, to destination: Int) {
        sections.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func setSection(_ section: String?, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }), tasks[i].section != section else { return }
        tasks[i].section = section
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
        events.append(ActivityEvent(kind: kind, taskTitle: task.title, detail: detail, section: task.section))
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL) {
            tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: sectionsURL) {
            sections = (try? decoder.decode([String].self, from: data)) ?? Self.starterSections
        } else {
            sections = Self.starterSections
        }
        // A task filed under a section missing from the list (e.g. a hand-edited file) still gets a header.
        for name in tasks.compactMap(\.section) where !sections.contains(name) { sections.append(name) }
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
            try encoder.encode(sections).write(to: sectionsURL, options: .atomic)
        } catch {
            NSLog("Super Simple Todo: could not save tasks: \(error)")
        }
    }
}
