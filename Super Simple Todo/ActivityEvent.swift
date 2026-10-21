import Foundation

struct ActivityEvent: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        // Order fixes the chart colors (series slot 1–5).
        case added, completed, deleted, uncompleted, priorityChanged

        var id: String { rawValue }

        var name: String {
            switch self {
            case .added: "Added"
            case .completed: "Completed"
            case .deleted: "Deleted"
            case .uncompleted: "Unticked"
            case .priorityChanged: "Priority"
            }
        }

        var symbol: String {
            switch self {
            case .added: "plus.circle"
            case .completed: "checkmark.circle"
            case .deleted: "xmark.circle"
            case .uncompleted: "arrow.uturn.backward.circle"
            case .priorityChanged: "flag.circle"
            }
        }
    }

    let id: UUID
    let date: Date
    let kind: Kind
    let taskTitle: String
    /// For priority changes, the new priority's name.
    let detail: String?
    /// The task's tags at the time of the action.
    let tags: [String]

    init(id: UUID = UUID(), date: Date = Date(), kind: Kind, taskTitle: String,
         detail: String? = nil, tags: [String] = []) {
        self.id = id
        self.date = date
        self.kind = kind
        self.taskTitle = taskTitle
        self.detail = detail
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, kind, taskTitle, detail, tags
        case section   // events logged while tasks had sections
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        kind = try c.decode(Kind.self, forKey: .kind)
        taskTitle = try c.decode(String.self, forKey: .taskTitle)
        detail = try c.decodeIfPresent(String.self, forKey: .detail)
        let section = try c.decodeIfPresent(String.self, forKey: .section)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? (section.map { [$0] } ?? [])
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(kind, forKey: .kind)
        try c.encode(taskTitle, forKey: .taskTitle)
        try c.encodeIfPresent(detail, forKey: .detail)
        try c.encode(tags, forKey: .tags)
    }
}

struct DailyCount: Identifiable, Equatable {
    let day: Date
    let kind: ActivityEvent.Kind
    let count: Int
    var id: String { "\(day.timeIntervalSince1970)-\(kind.rawValue)" }
}

/// Counts per day and kind for the `days` days ending on `end`'s day. Days with no
/// activity produce no entries; the chart's x-axis still covers the whole range.
func dailyCounts(_ events: [ActivityEvent], days: Int, endingAt end: Date = Date(),
                 calendar: Calendar = .current) -> [DailyCount] {
    let lastDay = calendar.startOfDay(for: end)
    guard let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: lastDay) else { return [] }
    var counts: [Date: [ActivityEvent.Kind: Int]] = [:]
    for event in events {
        let day = calendar.startOfDay(for: event.date)
        guard day >= firstDay, day <= lastDay else { continue }
        counts[day, default: [:]][event.kind, default: 0] += 1
    }
    return counts.keys.sorted().flatMap { day in
        ActivityEvent.Kind.allCases.compactMap { kind in
            counts[day]?[kind].map { DailyCount(day: day, kind: kind, count: $0) }
        }
    }
}
