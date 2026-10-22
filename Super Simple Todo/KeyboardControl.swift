import Foundation

extension Notification.Name {
    /// Sent by Tasks ▸ Priority (⌘0–⌘3) with the `Priority` as its object.
    static let setPriority = Notification.Name("SuperSimpleTodo.setPriority")
}

/// How the arrow keys and list changes move the selection. Kept apart from the view so it can be tested.
enum ListNavigation {
    enum Direction { case up, down }

    /// What ↑ or ↓ leads to.
    enum Move: Equatable {
        /// Select just this task.
        case select(UUID)
        /// ↑ on the first task: go back to the add field.
        case addField
        /// Nothing to move to (the list is empty).
        case none
    }

    /// With nothing selected, ↓ picks the first task and ↑ the last. Otherwise ↓ goes below the lowest
    /// selected task and ↑ above the highest; ↓ on the last task stays there.
    static func move(_ direction: Direction, from selection: Set<UUID>, in order: [UUID]) -> Move {
        guard let first = order.first, let last = order.last else { return .none }
        let selected = order.indices.filter { selection.contains(order[$0]) }
        guard let top = selected.first, let bottom = selected.last else {
            return .select(direction == .down ? first : last)
        }
        switch direction {
        case .down: return .select(order[min(bottom + 1, order.count - 1)])
        case .up: return top == 0 ? .addField : .select(order[top - 1])
        }
    }

    /// The selection after the list changes from `old` to `new` (a delete, a tick with done tasks hidden,
    /// Clear Done, a filter). Selected tasks still shown stay selected. If none are left, the task that
    /// followed them is selected, or else the one before, so the keyboard keeps a place in the list.
    static func reconcile(_ selection: Set<UUID>, old: [UUID], new: [UUID]) -> Set<UUID> {
        let shown = Set(new)
        let kept = selection.intersection(shown)
        guard kept.isEmpty, !selection.isEmpty,
              let lastSelected = old.lastIndex(where: selection.contains) else { return kept }
        let firstSelected = old.firstIndex(where: selection.contains)!
        if let after = old[(lastSelected + 1)...].first(where: shown.contains) { return [after] }
        if let before = old[..<firstSelected].last(where: shown.contains) { return [before] }
        return []
    }
}

/// The keys listed in Settings ▸ Keyboard Shortcuts.
enum ShortcutGuide {
    static let all: [(keys: String, action: String)] = [
        ("⌘N", "New task (jumps to the add field)"),
        ("Return", "Rename the selected task, or go to the add field when none is selected"),
        ("↑ ↓", "Move the selection (↓ from the add field goes to the list)"),
        ("Space", "Tick or untick the selected tasks"),
        ("⌫", "Delete the selected tasks"),
        ("⌘Z / ⇧⌘Z", "Undo / redo"),
        ("⌘1 / ⌘2 / ⌘3", "Priority Low / Medium / High"),
        ("⌘0", "No priority"),
        ("#", "Suggest tags in the add field (↑ ↓ to pick, Tab or Return to add)"),
        ("Esc", "Stop renaming, close tag suggestions, or clear the tag filter"),
        ("⇧⌘⌫", "Clear done tasks"),
        ("⌥⌘1 / ⌥⌘2 / ⌥⌘3", "Tasks / Calendar / Activity tab"),
        ("⌘,", "Settings"),
    ]
}
