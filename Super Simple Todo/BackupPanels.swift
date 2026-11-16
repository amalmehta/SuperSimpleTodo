import AppKit
import UniformTypeIdentifiers

/// File ▸ Export… and File ▸ Import…: the save and open panels, the merge-or-replace question and the alerts.
/// The file format itself is in `Backup`.
@MainActor
enum BackupPanels {
    static func export(_ store: TaskStore) {
        let panel = NSSavePanel()
        panel.title = "Export Tasks"
        panel.prompt = "Export"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        let day = TaskItem.dayFormatter.string(from: Date())
        panel.nameFieldStringValue = "Super Simple Todo \(day).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.backup().encoded().write(to: url, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    static func importFile(into store: TaskStore) {
        let panel = NSOpenPanel()
        panel.title = "Import Tasks"
        panel.prompt = "Import"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let backup: Backup
        do {
            backup = try Backup.decode(Data(contentsOf: url))
        } catch {
            NSAlert(error: error).runModal()
            return
        }

        let ask = NSAlert()
        ask.messageText = "Merge or replace your tasks?"
        ask.informativeText = """
            “\(url.lastPathComponent)” has \(count(backup.tasks.count, "task")) and \
            \(count(backup.activity.count, "history entry", "history entries")).

            Merge keeps your \(count(store.tasks.count, "task")) and adds the ones you don't have yet \
            (matched by ID). Replace swaps all your tasks, tags and history for the file's.

            You can undo either with ⌘Z.
            """
        ask.addButton(withTitle: "Merge")
        ask.addButton(withTitle: "Replace").hasDestructiveAction = true
        ask.addButton(withTitle: "Cancel")
        let mode: ImportMode
        switch ask.runModal() {
        case .alertFirstButtonReturn: mode = .merge
        case .alertSecondButtonReturn: mode = .replace
        default: return
        }

        let summary = store.importBackup(backup, mode: mode)
        let done = NSAlert()
        done.messageText = "Import finished"
        var lines = ["Added \(count(summary.tasksAdded, "task")) and \(count(summary.eventsAdded, "history entry", "history entries"))."]
        if summary.tasksSkipped > 0 {
            lines.append("Skipped \(count(summary.tasksSkipped, "task")) you already had.")
        }
        done.informativeText = lines.joined(separator: " ")
        done.runModal()
    }

    /// "1 task", "3 tasks".
    private static func count(_ n: Int, _ one: String, _ many: String? = nil) -> String {
        "\(n) \(n == 1 ? one : many ?? one + "s")"
    }
}
