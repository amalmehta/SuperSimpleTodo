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
    /// Name of the section the task is filed under; nil means "Other".
    var section: String?
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isDone: Bool = false,
         priority: Priority = .none, section: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.section = section
        self.createdAt = createdAt
    }

    // Tasks saved before priorities or sections existed have no "priority" or "section" key.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        isDone = try c.decode(Bool.self, forKey: .isDone)
        priority = try c.decodeIfPresent(Priority.self, forKey: .priority) ?? .none
        section = try c.decodeIfPresent(String.self, forKey: .section)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}
