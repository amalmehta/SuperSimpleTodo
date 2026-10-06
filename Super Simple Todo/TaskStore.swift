import Foundation

/// Holds the task list and saves it to a JSON file after every change.
@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    private let fileURL: URL

    nonisolated static var defaultFileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Super Simple Todo", isDirectory: true)
            .appendingPathComponent("Tasks.json")
    }

    init(fileURL: URL = TaskStore.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    var doneCount: Int { tasks.filter(\.isDone).count }

    func add(_ title: String) {
        let trimmed = title.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed))
        save()
    }

    func toggle(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].isDone.toggle()
        save()
    }

    func delete(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func clearDone() {
        tasks.removeAll(where: \.isDone)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(tasks).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Super Simple Todo: could not save tasks: \(error)")
        }
    }
}
