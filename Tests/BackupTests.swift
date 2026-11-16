import XCTest
@testable import Super_Simple_Todo

@MainActor
final class BackupTests: XCTestCase {
    private var folder: URL!

    override func setUp() {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: folder)
    }

    /// A fresh store in its own subfolder, like a new install.
    private func makeStore(_ name: String) -> TaskStore {
        TaskStore(fileURL: folder.appendingPathComponent(name).appendingPathComponent("Tasks.json"))
    }

    /// A store with every kind of data: tags (one unused, one renamed), priorities, a deadline, a link,
    /// completions on two days, a priority change, a deletion and an edited history entry.
    private func makeFilledStore() -> TaskStore {
        let store = makeStore("source")
        store.add("Run 5k !!! #fitness @tomorrow")
        store.add("Read chapter 3 https://example.com/book #study !")
        store.add("Call mum #family")
        store.add("Old idea")
        store.addTag("Errands")
        store.renameTag("Family", to: "Home")
        store.setPriority(.medium, for: store.tasks[2].id)
        store.toggle(store.tasks[0].id)
        store.toggle(store.tasks[1].id)
        store.delete(store.tasks[3].id)
        var earlier = store.events.last { $0.kind == .completed }!
        earlier.date = Calendar.current.date(byAdding: .day, value: -1, to: earlier.date)!
        store.updateEvent(earlier)
        // Reopen it as after a relaunch: the store's own files keep dates to the second, which is what an export holds.
        return makeStore("source")
    }

    private func assertSameData(_ a: TaskStore, _ b: TaskStore, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.tasks, b.tasks, "tasks", file: file, line: line)
        XCTAssertEqual(a.tags, b.tags, "tags", file: file, line: line)
        XCTAssertEqual(a.events, b.events, "activity", file: file, line: line)
        // What the Activity tab and calendar show, worked out from each store.
        XCTAssertEqual(dailyCounts(a.events, days: 30), dailyCounts(b.events, days: 30), file: file, line: line)
        let aDone = completedCounts(a.events), bDone = completedCounts(b.events)
        XCTAssertEqual(aDone.today, bDone.today, file: file, line: line)
        XCTAssertEqual(aDone.week, bDone.week, file: file, line: line)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        for day in [Date(), yesterday] {
            XCTAssertEqual(a.completions(on: day), b.completions(on: day), file: file, line: line)
        }
    }

    // MARK: Round trip

    func testExportThenReplaceIntoEmptyStoreMakesEqualStores() throws {
        let source = makeFilledStore()
        XCTAssertEqual(source.events.filter { $0.kind == .completed }.count, 2)
        XCTAssertNotNil(source.tasks.first?.deadline)
        XCTAssertNotNil(source.tasks.first { $0.link != nil })
        XCTAssertTrue(source.tags.contains("Errands") && source.tags.contains("Home"))

        let data = try source.backup().encoded()
        let target = makeStore("target")
        let summary = target.importBackup(try Backup.decode(data), mode: .replace)

        assertSameData(source, target)
        XCTAssertEqual(summary, ImportSummary(tasksAdded: 3, tasksSkipped: 0, eventsAdded: source.events.count))
        // The import is saved: the target reopens with the same data.
        assertSameData(source, makeStore("target"))
    }

    func testExportThenMergeIntoEmptyStoreKeepsTasksAndHistory() throws {
        let source = makeFilledStore()
        let target = makeStore("target")
        target.importBackup(try Backup.decode(source.backup().encoded()), mode: .merge)
        XCTAssertEqual(target.tasks, source.tasks)
        XCTAssertEqual(target.events, source.events)
        // Merging keeps the new store's starter tags first.
        XCTAssertEqual(target.tags, (TaskStore.starterTags + source.tags).uniqued())
    }

    func testExportingTwiceGivesTheSameFile() throws {
        let source = makeFilledStore()
        let stamp = Date(timeIntervalSince1970: 1_800_000_000)
        let target = makeStore("target")
        target.importBackup(try Backup.decode(source.backup().encoded()), mode: .replace)
        XCTAssertEqual(try source.backup(exportedAt: stamp).encoded(), try target.backup(exportedAt: stamp).encoded())
    }

    // MARK: Merge

    func testMergeSkipsTasksAndHistoryAlreadyHereByID() throws {
        let source = makeStore("source")
        source.add("A #work")
        source.add("B")
        let target = makeStore("target")
        target.importBackup(try Backup.decode(source.backup().encoded()), mode: .replace)
        target.rename(target.tasks[0].id, to: "A edited here")
        target.add("Only here")

        source.add("C !!")
        let summary = target.importBackup(try Backup.decode(source.backup().encoded()), mode: .merge)

        XCTAssertEqual(summary, ImportSummary(tasksAdded: 1, tasksSkipped: 2, eventsAdded: 1))
        XCTAssertEqual(target.tasks.map(\.title), ["A edited here", "B", "Only here", "C"])
        XCTAssertEqual(Set(target.tasks.map(\.id)).count, 4)
        XCTAssertEqual(Set(target.events.map(\.id)).count, target.events.count)
        XCTAssertEqual(target.events.map(\.taskTitle), ["A", "B", "Only here", "C"])
        XCTAssertEqual(target.events.map(\.date), target.events.map(\.date).sorted())
    }

    func testMergeMatchesTagsIgnoringCase() throws {
        let target = makeStore("target")
        let task = TaskItem(title: "Stretch", tags: ["fitness", "Garden"])
        let backup = Backup(exportedAt: Date(), tags: ["fitness", "Garden"], tasks: [task], activity: [])
        target.importBackup(backup, mode: .merge)
        XCTAssertEqual(target.tasks[0].tags, ["Fitness", "Garden"])
        XCTAssertEqual(target.tags, TaskStore.starterTags + ["Garden"])
    }

    func testImportIsOneUndoStep() throws {
        let source = makeStore("source")
        source.add("From file")
        let target = makeStore("target")
        target.add("Mine")
        let undo = UndoManager()
        undo.groupsByEvent = false
        target.undoManager = undo
        let before = (target.tasks, target.events, target.tags)
        undo.beginUndoGrouping()
        target.importBackup(try Backup.decode(source.backup().encoded()), mode: .replace)
        undo.endUndoGrouping()
        XCTAssertEqual(target.tasks.map(\.title), ["From file"])
        XCTAssertEqual(undo.undoActionName, "Import")
        undo.undo()
        XCTAssertEqual(target.tasks, before.0)
        XCTAssertEqual(target.events, before.1)
        XCTAssertEqual(target.tags, before.2)
    }

    // MARK: File format and errors

    func testFileFormat() throws {
        let store = makeStore("source")
        store.add("Run @2030-01-02 #fitness")
        let data = try store.backup(exportedAt: Date(timeIntervalSince1970: 0)).encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["format", "version", "exportedAt", "tags", "tasks", "activity"])
        XCTAssertEqual(json["format"] as? String, "super-simple-todo")
        XCTAssertEqual(json["version"] as? Int, 1)
        XCTAssertEqual(json["exportedAt"] as? String, "1970-01-01T00:00:00.000Z")
        let task = try XCTUnwrap((json["tasks"] as? [[String: Any]])?.first)
        XCTAssertEqual(task["deadline"] as? String, "2030-01-02")
        XCTAssertEqual(task["tags"] as? [String], ["Fitness"])
    }

    func testHandWrittenFileWithWholeSecondDatesImports() throws {
        let json = """
            {"format": "super-simple-todo", "version": 1, "exportedAt": "2026-10-21T09:00:00Z",
             "tags": ["Work"],
             "tasks": [{"id": "6F9619FF-8B86-D011-B42D-00C04FC964FF", "title": "Write report", "isDone": true,
                        "priority": 2, "tags": ["Work"], "createdAt": "2026-10-20T08:00:00Z"}],
             "activity": [{"id": "7F9619FF-8B86-D011-B42D-00C04FC964FF", "date": "2026-10-21T08:30:00.250Z",
                           "kind": "completed", "taskTitle": "Write report", "tags": ["Work"]}]}
            """
        let backup = try Backup.decode(Data(json.utf8))
        XCTAssertEqual(backup.tasks.first?.priority, .medium)
        XCTAssertEqual(try XCTUnwrap(backup.activity.first?.date.timeIntervalSince1970), 1_792_571_400.25, accuracy: 0.0005)
        XCTAssertEqual(backup.tasks.first?.createdAt, Date(timeIntervalSince1970: 1_792_483_200))
    }

    private func assertImportFails(_ json: String, with expected: BackupError,
                                   file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try Backup.decode(Data(json.utf8)), file: file, line: line) { error in
            XCTAssertEqual(error as? BackupError, expected, file: file, line: line)
            XCTAssertNotNil((error as? LocalizedError)?.recoverySuggestion, file: file, line: line)
        }
    }

    func testMalformedFilesAreRefusedWithAReason() {
        assertImportFails("{\"format\": \"super-simple-todo\", ", with: .malformed("It isn't valid JSON."))
        assertImportFails("", with: .malformed("It isn't valid JSON."))
        assertImportFails(#"{"format": "super-simple-todo"}"#,
                          with: .malformed("Its \"version\" is missing or isn't a positive whole number."))
        assertImportFails(#"{"format": "super-simple-todo", "version": "1"}"#,
                          with: .malformed("Its \"version\" is missing or isn't a positive whole number."))
        assertImportFails(#"{"format": "super-simple-todo", "version": 1, "exportedAt": "2026-10-21T09:00:00Z", "tags": [], "activity": []}"#,
                          with: .malformed("tasks is missing."))
        assertImportFails("""
            {"format": "super-simple-todo", "version": 1, "exportedAt": "2026-10-21T09:00:00Z", "tags": [], "activity": [],
             "tasks": [{"id": "6F9619FF-8B86-D011-B42D-00C04FC964FF", "isDone": false, "createdAt": "2026-10-20T08:00:00Z"}]}
            """, with: .malformed("tasks[0].title is missing."))
        assertImportFails("""
            {"format": "super-simple-todo", "version": 1, "exportedAt": "yesterday", "tags": [], "tasks": [], "activity": []}
            """, with: .malformed("exportedAt has an unexpected value."))
        let task = #"{"id": "6F9619FF-8B86-D011-B42D-00C04FC964FF", "title": "A", "isDone": false, "createdAt": "2026-10-20T08:00:00Z"}"#
        assertImportFails("""
            {"format": "super-simple-todo", "version": 1, "exportedAt": "2026-10-21T09:00:00Z", "tags": [], "activity": [],
             "tasks": [\(task), \(task)]}
            """, with: .malformed("Two tasks share the ID 6F9619FF-8B86-D011-B42D-00C04FC964FF."))
    }

    func testOtherJSONIsNotABackup() {
        assertImportFails("[]", with: .notABackup)   // e.g. Tasks.json itself
        assertImportFails(#"{"tasks": []}"#, with: .notABackup)
        assertImportFails(#"{"format": "other-app", "version": 1}"#, with: .notABackup)
    }

    func testNewerVersionIsRefusedBeforeReadingTheRest() {
        assertImportFails(#"{"format": "super-simple-todo", "version": 2, "tasks": "a new shape"}"#,
                          with: .tooNew(version: 2))
        XCTAssertTrue(BackupError.tooNew(version: 2).recoverySuggestion!.contains("version 2"))
    }
}
