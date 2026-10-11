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
    /// The task's section at the time of the action (events before sections existed have none).
    let section: String?

    init(id: UUID = UUID(), date: Date = Date(), kind: Kind, taskTitle: String,
         detail: String? = nil, section: String? = nil) {
        self.id = id
        self.date = date
        self.kind = kind
        self.taskTitle = taskTitle
        self.detail = detail
        self.section = section
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
