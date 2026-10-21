import Foundation

enum Priority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case none = 0, low, medium, high

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    static func < (a: Priority, b: Priority) -> Bool { a.rawValue < b.rawValue }
}

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var priority: Priority
    var tags: [String]
    /// The day the task is due (local start of day), or nil. Saved as a plain "yyyy-MM-dd" date.
    var deadline: Date?
    /// A web page that helps with the task, shown as its next step.
    var link: URL?
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isDone: Bool = false,
         priority: Priority = .none, tags: [String] = [], deadline: Date? = nil, link: URL? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.tags = tags
        self.deadline = deadline
        self.link = link
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, isDone, priority, tags, deadline, link, createdAt
        case section   // older files: one section per task, now read as a single tag
    }

    // Older files may lack "priority" and "tags", or have a "section" instead of tags.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        isDone = try c.decode(Bool.self, forKey: .isDone)
        priority = try c.decodeIfPresent(Priority.self, forKey: .priority) ?? .none
        let section = try c.decodeIfPresent(String.self, forKey: .section)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? (section.map { [$0] } ?? [])
        deadline = try c.decodeIfPresent(String.self, forKey: .deadline).flatMap(Self.dayFormatter.date(from:))
        link = try c.decodeIfPresent(String.self, forKey: .link).flatMap(URL.init(string:))
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(isDone, forKey: .isDone)
        try c.encode(priority, forKey: .priority)
        try c.encode(tags, forKey: .tags)
        try c.encodeIfPresent(deadline.map(Self.dayFormatter.string(from:)), forKey: .deadline)
        try c.encodeIfPresent(link?.absoluteString, forKey: .link)
        try c.encode(createdAt, forKey: .createdAt)
    }

    /// A calendar date in the user's time zone, so a deadline stays on the same day.
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
