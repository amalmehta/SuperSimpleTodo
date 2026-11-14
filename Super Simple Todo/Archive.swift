import Foundation

/// Finding archived tasks: the archive's search field, and the add field's "bring it back" offer.
/// No SwiftUI, so it is unit-tested directly.
enum ArchiveSearch {
    /// Lowercased words without accents, split at spaces and punctuation ("Re-new  Passport!" → re, new, passport).
    static func words(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    /// True when every query word starts a word of the task's title or one of its tags,
    /// so "ren pass" finds "Renew passport" and "fit" finds anything tagged Fitness.
    static func matches(_ queryWords: [String], _ task: TaskItem) -> Bool {
        let haystack = words(task.title) + task.tags.flatMap(words)
        return queryWords.allSatisfy { q in haystack.contains { $0.hasPrefix(q) } }
    }

    /// The archive list for a search: every archived task when the query is blank.
    /// Open (parked) tasks first, then finished ones; within each, the most recently archived first.
    static func filter(_ tasks: [TaskItem], query: String) -> [TaskItem] {
        let q = words(query)
        return sorted(tasks.filter { $0.isArchived && (q.isEmpty || matches(q, $0)) })
    }

    static func sorted(_ archived: [TaskItem]) -> [TaskItem] {
        archived.sorted {
            if $0.isDone != $1.isDone { return !$0.isDone }
            return ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast)
        }
    }

    /// The fewest letters typed before the add field offers archived tasks, so one or two keys don't flood it.
    static let minimumLetters = 3

    /// Archived tasks the add field offers to bring back while you type a new task. Reads only the
    /// title words: "#tag", "!", "@day" and links are skipped. Needs `minimumLetters` letters in all.
    static func restoreSuggestions(for text: String, in tasks: [TaskItem], limit: Int = 3) -> [TaskItem] {
        let typed = text.split(separator: " ").filter { word in
            let lower = word.lowercased()
            return !(word.first.map { "#@!".contains($0) } ?? true)
                && !lower.hasPrefix("http") && !lower.hasPrefix("www.")
        }
        let q = typed.flatMap { words(String($0)) }
        guard q.joined().count >= minimumLetters else { return [] }
        return Array(sorted(tasks.filter { $0.isArchived && matches(q, $0) }).prefix(limit))
    }
}

/// Open tasks nobody has touched for a while, which the list offers to archive.
enum StaleTasks {
    /// A task counts as untouched after this many days without being added, edited, ticked or restored.
    static let days = 30

    /// Open tasks on the list (not archived) last active `days` or more days ago, oldest first.
    static func find(in tasks: [TaskItem], now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }
        return tasks.filter { !$0.isDone && !$0.isArchived && $0.lastActive <= cutoff }
            .sorted { $0.lastActive < $1.lastActive }
    }

    /// The nudge shows while some untouched task wasn't already there when you chose Not Now.
    static func shouldNudge(stale: [UUID], dismissed: Set<UUID>) -> Bool {
        stale.contains { !dismissed.contains($0) }
    }

    /// "Fix bike, Learn Rust and 3 more" for the nudge.
    static func summary(_ titles: [String], shown: Int = 2) -> String {
        guard titles.count > shown else {
            return titles.count == 2 ? "\(titles[0]) and \(titles[1])" : titles.joined(separator: ", ")
        }
        return titles.prefix(shown).joined(separator: ", ") + " and \(titles.count - shown) more"
    }

    /// The dismissed IDs as stored in UserDefaults (space-separated UUIDs).
    static func decode(_ stored: String) -> Set<UUID> {
        Set(stored.split(separator: " ").compactMap { UUID(uuidString: String($0)) })
    }

    static func encode(_ ids: Set<UUID>) -> String {
        ids.map(\.uuidString).sorted().joined(separator: " ")
    }
}
