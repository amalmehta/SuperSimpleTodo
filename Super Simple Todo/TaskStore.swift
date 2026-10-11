import Foundation

/// Holds the task list and the activity log, and saves both to JSON files after every change.
@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var events: [ActivityEvent] = []
    private let fileURL: URL
    private var activityURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Activity.json")
    }

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

    /// Adds a task. A trailing "!", "!!" or "!!!" (after a space) sets Low, Medium or High.
    func add(_ title: String) {
        let flat = title.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        let (text, priority) = Self.parsePriority(flat)
        guard !text.isEmpty else { return }
        let task = TaskItem(title: text, priority: priority)
        tasks.append(task)
        log(.added, task)
        save()
    }

    func setPriority(_ priority: Priority, for id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[i].priority != priority else { return }
        tasks[i].priority = priority
        log(.priorityChanged, tasks[i], detail: priority.name)
        save()
    }

    static func parsePriority(_ text: String) -> (String, Priority) {
        guard let space = text.lastIndex(of: " ") else { return (text, .none) }
        let suffix = text[text.index(after: space)...]
        guard (1...3).contains(suffix.count), suffix.allSatisfy({ $0 == "!" }),
              let priority = Priority(rawValue: suffix.count)
        else { return (text, .none) }
        return (text[..<space].trimmingCharacters(in: .whitespaces), priority)
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
        events.append(ActivityEvent(kind: kind, taskTitle: task.title, detail: detail))
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL) {
            tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        }
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
        } catch {
            NSLog("Super Simple Todo: could not save tasks: \(error)")
        }
    }
}
