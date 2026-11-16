import Foundation

/// Everything the app keeps, in one versioned JSON file for File ▸ Export… and File ▸ Import….
/// Tasks and logged actions use the same JSON as Tasks.json and Activity.json.
struct Backup: Codable, Equatable {
    /// Marks the file as ours, so another app's JSON (or a bare Tasks.json) is refused clearly.
    static let formatName = "super-simple-todo"
    /// Raise this when the file format changes; files with a higher version are refused as too new.
    static let currentVersion = 1

    var format = Backup.formatName
    var version = Backup.currentVersion
    var exportedAt: Date
    var tags: [String]
    var tasks: [TaskItem]
    /// The Activity tab's history, including each completion's time.
    var activity: [ActivityEvent]

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(Self.fractionalFormatter.string(from: date))
        }
        return try encoder.encode(self)
    }

    /// Reads an exported file, checking that it is ours and not from a newer version before reading the rest.
    static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        // Milliseconds are optional, so hand-written dates like "2026-10-21T09:00:00Z" work too.
        decoder.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let text = try c.decode(String.self)
            guard let date = fractionalFormatter.date(from: text) ?? wholeSecondFormatter.date(from: text) else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "\"\(text)\" isn't an ISO 8601 date.")
            }
            return date
        }
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            throw BackupError.malformed("It isn't valid JSON.")
        }
        guard let header = object as? [String: Any], header["format"] as? String == formatName else {
            throw BackupError.notABackup
        }
        guard let version = header["version"] as? Int, version >= 1 else {
            throw BackupError.malformed("Its \"version\" is missing or isn't a positive whole number.")
        }
        guard version <= currentVersion else { throw BackupError.tooNew(version: version) }

        let backup: Backup
        do {
            backup = try decoder.decode(Backup.self, from: data)
        } catch let error as DecodingError {
            throw BackupError.malformed(describe(error))
        }
        if let id = backup.tasks.map(\.id).duplicate() {
            throw BackupError.malformed("Two tasks share the ID \(id.uuidString).")
        }
        if let id = backup.activity.map(\.id).duplicate() {
            throw BackupError.malformed("Two history entries share the ID \(id.uuidString).")
        }
        return backup
    }

    /// "tasks[2].title is missing." and the like, for the error alert.
    private static func describe(_ error: DecodingError) -> String {
        func path(_ keys: [CodingKey]) -> String {
            keys.reduce("") { text, key in
                if let index = key.intValue { return text + "[\(index)]" }
                return text.isEmpty ? key.stringValue : text + "." + key.stringValue
            }
        }
        switch error {
        case .keyNotFound(let key, let context):
            return "\(path(context.codingPath + [key])) is missing."
        case .valueNotFound(_, let context):
            return "\(path(context.codingPath)) is empty."
        case .typeMismatch(_, let context), .dataCorrupted(let context):
            let place = path(context.codingPath)
            return place.isEmpty ? context.debugDescription : "\(place) has an unexpected value."
        @unknown default:
            return error.localizedDescription
        }
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let wholeSecondFormatter = ISO8601DateFormatter()
}

enum BackupError: LocalizedError, Equatable {
    case malformed(String)
    case notABackup
    case tooNew(version: Int)

    var errorDescription: String? {
        switch self {
        case .malformed: "This file can't be imported because it's damaged."
        case .notABackup: "This file isn't a Super Simple Todo export."
        case .tooNew: "This file was exported by a newer version of Super Simple Todo."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .malformed(let detail): "\(detail) Nothing was imported."
        case .notABackup: "Choose a file made with File ▸ Export…. Nothing was imported."
        case .tooNew(let version):
            "It uses format version \(version); this copy reads up to version \(Backup.currentVersion). "
                + "Update the app, then import it again. Nothing was imported."
        }
    }
}

/// What File ▸ Import… does with the current tasks.
enum ImportMode {
    /// Keep the current data and add what's new; a task or history entry whose ID is already here is skipped.
    case merge
    /// Swap all tasks, tags and history for the file's.
    case replace
}

struct ImportSummary: Equatable {
    var tasksAdded = 0
    var tasksSkipped = 0
    var eventsAdded = 0
}

private extension Array where Element: Hashable {
    /// The first element that appears twice, if any.
    func duplicate() -> Element? {
        var seen = Set<Element>()
        return first { !seen.insert($0).inserted }
    }
}
