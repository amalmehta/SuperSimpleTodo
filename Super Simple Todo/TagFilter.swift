import Foundation

/// The tag the task list is narrowed to, if any. Kept apart from the view so it can be tested.
struct TagFilter: Equatable {
    private(set) var tag: String?

    init(tag: String? = nil) { self.tag = tag }

    var isActive: Bool { tag != nil }

    /// Clicking a tag shows only its tasks; clicking the same tag again shows everything.
    mutating func toggle(_ name: String) {
        tag = tag == name ? nil : name
    }

    mutating func clear() { tag = nil }

    /// Drops the filter when its tag no longer exists (deleted or renamed in Settings).
    mutating func keepOnly(knownTags: [String]) {
        if let tag, !knownTags.contains(tag) { self.tag = nil }
    }

    /// The tasks to show, in the order given: optionally without done ones, and only the filter tag's.
    func apply(to tasks: [TaskItem], hideDone: Bool) -> [TaskItem] {
        tasks.filter { (!hideDone || !$0.isDone) && (tag == nil || $0.tags.contains(tag!)) }
    }
}

/// Suggestions for the "#word" being typed in the add field.
enum TagAutocomplete {
    /// The "#word" at the end of the text being typed: where it starts and what follows the "#"
    /// ("" right after typing "#"). Nil when the last word isn't a tag in progress, e.g. "C#",
    /// "#1" or text ending in a space.
    static func activeQuery(in text: String) -> (start: String.Index, query: String)? {
        guard let hash = text.lastIndex(of: "#") else { return nil }
        let query = text[text.index(after: hash)...]
        let startsWord = hash == text.startIndex || text[text.index(before: hash)].isWhitespace
        guard startsWord, query.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }),
              query.first.map(\.isLetter) ?? true else { return nil }
        return (hash, String(query))
    }

    /// How many tasks (open or done) carry each tag.
    static func useCounts(in tasks: [TaskItem]) -> [String: Int] {
        tasks.flatMap(\.tags).reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// Known tags, most used first; ties keep the known order.
    static func ranked(_ tags: [String], by counts: [String: Int]) -> [String] {
        tags.enumerated()
            .sorted { (counts[$0.element] ?? 0, $1.offset) > (counts[$1.element] ?? 0, $0.offset) }
            .map(\.element)
    }

    /// Tags matching what's typed after "#", ignoring case and treating "-"/"_" as spaces: names that
    /// start with it come first, then names with a later word that starts with it; each group is ranked
    /// by use. An empty query lists every tag.
    static func suggestions(for query: String, tags: [String], tasks: [TaskItem], limit: Int = 8) -> [String] {
        let typed = TaskStore.tagName(fromTag: query).lowercased()
        let ranked = ranked(tags, by: useCounts(in: tasks))
        guard !typed.isEmpty else { return Array(ranked.prefix(limit)) }
        let starts = ranked.filter { $0.lowercased().hasPrefix(typed) }
        let laterWord = ranked.filter { name in
            !starts.contains(name) && name.lowercased().split(separator: " ").dropFirst().contains { $0.hasPrefix(typed) }
        }
        return Array((starts + laterWord).prefix(limit))
    }

    /// How a tag is typed so `TaskStore.parse` reads it back as the same tag: "Deep work" -> "#deep-work".
    static func token(for tag: String) -> String {
        "#" + tag.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    /// True when the query already spells out the tag, so accepting it would change nothing.
    static func isTyped(_ tag: String, as query: String) -> Bool {
        token(for: tag) == "#" + query.lowercased()
    }

    /// The text with its trailing "#word" replaced by the chosen tag and a space, ready for more typing.
    static func accept(_ tag: String, in text: String) -> String {
        guard let active = activeQuery(in: text) else { return text }
        return String(text[..<active.start]) + token(for: tag) + " "
    }
}
