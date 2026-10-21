import XCTest
@testable import Super_Simple_Todo

@MainActor
final class TaskStoreTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Tasks.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    func testAddTrimsAndIgnoresBlank() {
        let store = TaskStore(fileURL: fileURL)
        store.add("  Buy milk  ")
        store.add("   ")
        XCTAssertEqual(store.tasks.map(\.title), ["Buy milk"])
    }

    func testAddFlattensLineBreaks() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Buy\nmilk\n")
        XCTAssertEqual(store.tasks.map(\.title), ["Buy milk"])
    }

    func testToggleAndCount() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B")
        store.toggle(store.tasks[0].id)
        XCTAssertTrue(store.tasks[0].isDone)
        XCTAssertEqual(store.doneCount, 1)
        store.toggle(store.tasks[0].id)
        XCTAssertEqual(store.doneCount, 0)
    }

    func testDeleteAndClearDone() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B"); store.add("C")
        store.delete(store.tasks[0].id)
        store.toggle(store.tasks[0].id)
        store.clearDone()
        XCTAssertEqual(store.tasks.map(\.title), ["C"])
    }

    func testPersistsAcrossLaunches() {
        let first = TaskStore(fileURL: fileURL)
        first.add("Keep me")
        first.toggle(first.tasks[0].id)
        let second = TaskStore(fileURL: fileURL)
        XCTAssertEqual(second.tasks.map(\.id), first.tasks.map(\.id))
        XCTAssertEqual(second.tasks.map(\.title), ["Keep me"])
        XCTAssertEqual(second.tasks.map(\.isDone), [true])
    }

    func testBangSuffixSetsPriority() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Pay rent !!!")
        store.add("Call dentist !!")
        store.add("Water plants !")
        store.add("Wow!")
        store.add("!!!")
        XCTAssertEqual(store.tasks.map(\.title), ["Pay rent", "Call dentist", "Water plants", "Wow!", "!!!"])
        XCTAssertEqual(store.tasks.map(\.priority), [.high, .medium, .low, .none, .none])
    }

    func testSortedByPriorityThenAddedOrder() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a"); store.add("b !"); store.add("c !!!"); store.add("d !")
        XCTAssertEqual(store.sortedTasks.map(\.title), ["c", "b", "d", "a"])
        store.setPriority(.none, for: store.tasks[2].id)
        XCTAssertEqual(store.sortedTasks.map(\.title), ["b", "d", "a", "c"])
    }

    func testOldFileWithoutPriorityLoads() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let old = #"[{"createdAt":"2026-10-06T07:29:31Z","id":"DD816FCA-94AB-47D5-920C-3734FE1FC1FE","isDone":false,"title":"Old"}]"#
        try Data(old.utf8).write(to: fileURL)
        let store = TaskStore(fileURL: fileURL)
        XCTAssertEqual(store.tasks.map(\.title), ["Old"])
        XCTAssertEqual(store.tasks.first?.priority, Priority.none)
    }

    func testActionsAreLoggedAndSaved() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B")
        store.toggle(store.tasks[0].id)
        store.toggle(store.tasks[0].id)
        store.setPriority(.high, for: store.tasks[1].id)
        store.setPriority(.high, for: store.tasks[1].id) // no change, no event
        store.delete(store.tasks[1].id)
        store.toggle(store.tasks[0].id)
        store.clearDone()
        XCTAssertEqual(store.events.map(\.kind),
                       [.added, .added, .completed, .uncompleted, .priorityChanged, .deleted, .completed, .deleted])
        XCTAssertEqual(store.events[4].detail, "High")
        XCTAssertEqual(TaskStore(fileURL: fileURL).events.map(\.id), store.events.map(\.id))
    }

    func testMissingActivityFileIsBackfilledFromTasks() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let old = #"[{"createdAt":"2026-10-06T07:29:31Z","id":"DD816FCA-94AB-47D5-920C-3734FE1FC1FE","isDone":false,"title":"Old"}]"#
        try Data(old.utf8).write(to: fileURL)
        let store = TaskStore(fileURL: fileURL)
        XCTAssertEqual(store.events.map(\.kind), [.added])
        XCTAssertEqual(store.events.first?.date, ISO8601DateFormatter().date(from: "2026-10-06T07:29:31Z"))
    }

    func testDailyCountsGroupsByDayAndDropsOldEvents() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let end = ISO8601DateFormatter().date(from: "2026-10-10T12:00:00Z")!
        let at = { (s: String) in ISO8601DateFormatter().date(from: s)! }
        let events = [
            ActivityEvent(date: at("2026-10-10T01:00:00Z"), kind: .added, taskTitle: "a"),
            ActivityEvent(date: at("2026-10-10T09:00:00Z"), kind: .added, taskTitle: "b"),
            ActivityEvent(date: at("2026-10-10T10:00:00Z"), kind: .completed, taskTitle: "a"),
            ActivityEvent(date: at("2026-10-04T10:00:00Z"), kind: .deleted, taskTitle: "c"),
            ActivityEvent(date: at("2026-10-03T23:59:00Z"), kind: .added, taskTitle: "too old"),
        ]
        let counts = dailyCounts(events, days: 7, endingAt: end, calendar: cal)
        XCTAssertEqual(counts.map { "\($0.kind.rawValue)=\($0.count)" }, ["deleted=1", "added=2", "completed=1"])
    }

    func testFreshStoreHasStarterTags() {
        XCTAssertEqual(TaskStore(fileURL: fileURL).tags, ["Daily", "Fitness", "Work", "Study"])
    }

    func testHashTagsAddTagsAndCreateNewOnes() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Run 5k #fitness #daily !!")
        store.add("!!! Ship report #Work #work")
        store.add("Read paper #deep-work")
        store.add("Fix C# bug #1")
        store.add("#study")
        XCTAssertEqual(store.tasks.map(\.title), ["Run 5k", "Ship report", "Read paper", "Fix C# bug #1", "#study"])
        XCTAssertEqual(store.tasks.map(\.tags), [["Fitness", "Daily"], ["Work"], ["Deep work"], [], []])
        XCTAssertEqual(store.tasks.map(\.priority), [.medium, .high, .none, .none, .none])
        XCTAssertEqual(store.tags, ["Daily", "Fitness", "Work", "Study", "Deep work"])
        let reloaded = TaskStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.tags, store.tags)
        XCTAssertEqual(reloaded.tasks.map(\.tags), store.tasks.map(\.tags))
    }

    func testListStaysOneListSortedByPriority() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a #work"); store.add("b !!!"); store.add("c #daily !")
        XCTAssertEqual(store.sortedTasks.map(\.title), ["b", "c", "a"])
    }

    func testToggleRenameAndDeleteTag() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Squats #fitness")
        let id = store.tasks[0].id
        store.toggleTag("Daily", for: id)
        store.toggleTag("gym", for: id)          // unknown: created
        XCTAssertEqual(store.tasks[0].tags, ["Fitness", "Daily", "gym"])
        store.toggleTag("daily", for: id)        // matches ignoring case: removed
        XCTAssertEqual(store.tasks[0].tags, ["Fitness", "gym"])
        XCTAssertFalse(store.renameTag("gym", to: "work"))   // taken
        XCTAssertTrue(store.renameTag("gym", to: "Gym"))
        XCTAssertEqual(store.tasks[0].tags, ["Fitness", "Gym"])
        store.deleteTag("Fitness")
        XCTAssertEqual(store.tasks[0].tags, ["Gym"])
        XCTAssertFalse(store.tags.contains("Fitness"))
    }

    func testEventsCarryTags() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Plan week #work")
        store.toggleTag("Daily", for: store.tasks[0].id)
        store.toggle(store.tasks[0].id)
        XCTAssertEqual(store.events.map(\.tags), [["Work"], ["Work", "Daily"]])
    }

    func testSectionsVersionFilesBecomeTags() throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(#"[{"createdAt":"2026-10-11T07:00:00Z","id":"DD816FCA-94AB-47D5-920C-3734FE1FC1FE","isDone":false,"priority":0,"section":"Gym","title":"Squats"}]"#.utf8).write(to: fileURL)
        try Data(#"["Daily","Gym"]"#.utf8).write(to: dir.appendingPathComponent("Sections.json"))
        try Data(#"[{"date":"2026-10-11T07:00:00Z","id":"11111111-0000-0000-0000-000000000001","kind":"added","section":"Gym","taskTitle":"Squats"}]"#.utf8).write(to: dir.appendingPathComponent("Activity.json"))
        let store = TaskStore(fileURL: fileURL)
        XCTAssertEqual(store.tasks[0].tags, ["Gym"])
        XCTAssertEqual(store.tags, ["Daily", "Gym"])
        XCTAssertEqual(store.events[0].tags, ["Gym"])
        store.add("x")   // saves: tasks are written with tags and no section key
        let saved = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertFalse(saved.contains("section"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("Tags.json").path))
    }

    func testCorruptFileStartsEmpty() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        let store = TaskStore(fileURL: fileURL)
        XCTAssertTrue(store.tasks.isEmpty)
        store.add("New")   // saving must not destroy the unreadable file
        let dir = fileURL.deletingLastPathComponent()
        let backups = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.hasPrefix("Tasks.unreadable-") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try String(contentsOf: dir.appendingPathComponent(backups[0]), encoding: .utf8), "not json")
    }

    func testDoneTasksSinkBelowOpenOnes() {
        let store = TaskStore(fileURL: fileURL)
        store.add("high done !!!"); store.add("low open !"); store.add("none open")
        store.toggle(store.tasks[0].id)
        XCTAssertEqual(store.sortedTasks.map(\.title), ["low open", "none open", "high done"])
    }

    func testVisibleTasksFiltersByTagAndDone() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a #work"); store.add("b #work #daily"); store.add("c")
        store.toggle(store.tasks[0].id)
        XCTAssertEqual(store.visibleTasks(hideDone: false, tag: "Work").map(\.title), ["b", "a"])
        XCTAssertEqual(store.visibleTasks(hideDone: true, tag: "Work").map(\.title), ["b"])
        XCTAssertEqual(store.visibleTasks(hideDone: true, tag: nil).map(\.title), ["b", "c"])
    }

    func testRenameKeepsTagsAndReadsMarkers() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Run #fitness")
        let id = store.tasks[0].id
        store.rename(id, to: "Run 5k #daily !!")
        XCTAssertEqual(store.tasks[0].title, "Run 5k")
        XCTAssertEqual(store.tasks[0].tags, ["Fitness", "Daily"])
        XCTAssertEqual(store.tasks[0].priority, .medium)
        XCTAssertEqual(store.events.last?.kind, .priorityChanged)
        let eventCount = store.events.count
        store.rename(id, to: "   ")             // blank: ignored
        store.rename(id, to: "Run 5k")           // no change: nothing logged
        XCTAssertEqual(store.tasks[0].title, "Run 5k")
        XCTAssertEqual(store.events.count, eventCount)
    }

    func testToggleAndDeleteSeveralAtOnce() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a"); store.add("b"); store.add("c")
        store.toggle(store.tasks[0].id)
        let ab = Set(store.tasks.prefix(2).map(\.id))
        store.toggle(ab)                          // one open among them: all become done
        XCTAssertEqual(store.tasks.map(\.isDone), [true, true, false])
        store.toggle(ab)                          // all done: all reopen
        XCTAssertEqual(store.tasks.map(\.isDone), [false, false, false])
        store.delete(ab)
        XCTAssertEqual(store.tasks.map(\.title), ["c"])
    }

    func testUndoAndRedoRestoreTasksHistoryAndFile() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.undoManager = undo
        func step(_ action: () -> Void) { undo.beginUndoGrouping(); action(); undo.endUndoGrouping() }

        step { store.add("Keep #work") }
        step { store.toggle(store.tasks[0].id) }
        step { store.clearDone() }
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertEqual(undo.undoActionName, "Clear Done")

        undo.undo()
        XCTAssertEqual(store.tasks.map(\.title), ["Keep"])
        XCTAssertTrue(store.tasks[0].isDone)
        XCTAssertEqual(store.events.map(\.kind), [.added, .completed])
        XCTAssertEqual(TaskStore(fileURL: fileURL).tasks.map(\.title), ["Keep"])   // saved

        undo.redo()
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertEqual(store.events.last?.kind, .deleted)
    }

    func testEditDeleteAndClearHistoryLeaveTasksAlone() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a"); store.add("b")
        store.toggle(store.tasks[0].id)
        var edited = store.events[0]
        edited.taskTitle = "a renamed"
        edited.kind = .completed
        edited.date = Date(timeIntervalSinceNow: -86_400)
        edited.tags = ["Work", "work", "Gym"]
        store.updateEvent(edited)
        let saved = store.events.first { $0.id == edited.id }!
        XCTAssertEqual(saved.taskTitle, "a renamed")
        XCTAssertEqual(saved.kind, .completed)
        XCTAssertEqual(saved.tags, ["Work", "Gym"])                 // known tag reused, new one created
        XCTAssertTrue(store.tags.contains("Gym"))
        XCTAssertEqual(store.tasks.map(\.title), ["a", "b"])       // tasks untouched

        store.deleteEvents([edited.id])
        XCTAssertFalse(store.events.contains { $0.id == edited.id })
        store.clearHistory()
        XCTAssertTrue(store.events.isEmpty)
        XCTAssertEqual(store.tasks.count, 2)
        XCTAssertTrue(TaskStore(fileURL: fileURL).events.isEmpty)    // an empty log isn't backfilled again
    }

    func testCompletedCountsTodayAndThisWeek() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1   // weeks start Sunday
        let at = { (s: String) in ISO8601DateFormatter().date(from: s)! }
        let now = at("2026-10-21T15:00:00Z")   // a Wednesday
        let events = [
            ActivityEvent(date: at("2026-10-21T09:00:00Z"), kind: .completed, taskTitle: "today"),
            ActivityEvent(date: at("2026-10-21T10:00:00Z"), kind: .added, taskTitle: "not a completion"),
            ActivityEvent(date: at("2026-10-19T09:00:00Z"), kind: .completed, taskTitle: "monday"),
            ActivityEvent(date: at("2026-10-17T09:00:00Z"), kind: .completed, taskTitle: "last saturday"),
        ]
        let counts = completedCounts(events, now: now, calendar: cal)
        XCTAssertEqual(counts.today, 1)
        XCTAssertEqual(counts.week, 2)
    }
}
