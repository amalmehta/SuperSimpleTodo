import XCTest
@testable import Super_Simple_Todo

@MainActor
final class ArchiveTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Tasks.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    private func undoable(_ store: TaskStore) -> (UndoManager, (() -> Void) -> Void) {
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.undoManager = undo
        return (undo, { action in undo.beginUndoGrouping(); action(); undo.endUndoGrouping() })
    }

    // MARK: Archive and restore

    func testArchivedTasksLeaveTheListCalendarAndCounts() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Renew passport @tomorrow #errands")
        store.add("Water plants")
        store.toggle(store.tasks[1].id)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(store.tasks(dueOn: tomorrow).count, 1)

        store.archive(Set(store.tasks.map(\.id)))
        XCTAssertTrue(store.sortedTasks.isEmpty)
        XCTAssertTrue(store.activeTasks.isEmpty)
        XCTAssertTrue(store.tasks(dueOn: tomorrow).isEmpty)   // no calendar dot
        XCTAssertEqual(store.doneCount, 0)
        XCTAssertEqual(store.tasks.count, 2)                    // kept, with everything on them
        XCTAssertEqual(store.tasks[0].tags, ["Errands"])
        XCTAssertNotNil(store.tasks[0].deadline)
        // Parked open tasks first, then finished ones.
        XCTAssertEqual(store.archivedTasks.map(\.title), ["Renew passport", "Water plants"])
        // Saved: a relaunch still has them archived.
        XCTAssertEqual(TaskStore(fileURL: fileURL).archivedTasks.map(\.id), store.archivedTasks.map(\.id))
    }

    func testRestoreBringsTasksBackOpenAndTouched() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Renew passport")
        store.add("Fix bike")
        store.toggle(store.tasks[0].id)
        store.archive(Set(store.tasks.map(\.id)))
        let eventsBefore = store.events.count
        let now = Date(timeIntervalSinceNow: 5)

        store.restore(Set(store.tasks.map(\.id)), now: now)
        XCTAssertEqual(store.sortedTasks.map(\.title), ["Renew passport", "Fix bike"])
        XCTAssertTrue(store.archivedTasks.isEmpty)
        XCTAssertEqual(store.tasks.map(\.isDone), [false, false])   // a finished task comes back open
        XCTAssertEqual(store.tasks.map(\.touchedAt), [now, now])
        // Only the reopening is logged (as Unticked); archiving and restoring aren't.
        XCTAssertEqual(store.events.dropFirst(eventsBefore).map(\.kind), [.uncompleted])
    }

    func testArchiveAndRestoreAreUndoable() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B")
        let (undo, step) = undoable(store)
        step { store.archive([store.tasks[0].id]) }
        XCTAssertEqual(undo.undoActionName, "Archive Task")
        XCTAssertEqual(store.sortedTasks.map(\.title), ["B"])
        undo.undo()
        XCTAssertEqual(store.sortedTasks.map(\.title), ["A", "B"])
        undo.redo()
        step { store.restore([store.tasks[0].id]) }
        XCTAssertEqual(undo.undoActionName, "Restore Task")
        undo.undo()
        XCTAssertEqual(store.archivedTasks.map(\.title), ["A"])
        step { store.archive(Set(store.tasks.map(\.id)), actionName: "Archive Untouched Tasks") }
        XCTAssertEqual(undo.undoActionName, "Archive Untouched Tasks")
    }

    func testArchivingTwiceOrRestoringAListedTaskDoesNothing() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A")
        let before = store.tasks
        store.restore([store.tasks[0].id])   // not archived
        XCTAssertEqual(store.tasks, before)
        let first = Date(timeIntervalSince1970: 1_000)
        store.archive([store.tasks[0].id], now: first)
        store.archive([store.tasks[0].id], now: Date())
        XCTAssertEqual(store.tasks[0].archivedAt, first)   // keeps when it was first archived
    }

    func testDeletingFromTheArchiveIsForGood() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Old idea")
        store.archive([store.tasks[0].id])
        store.delete(store.tasks[0].id)
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertEqual(store.events.last?.kind, .deleted)
    }

    func testArchiveDoneOnlyMovesFinishedTasks() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Open"); store.add("Done")
        store.toggle(store.tasks[1].id)
        let (undo, step) = undoable(store)
        step { store.archiveDone() }
        XCTAssertEqual(store.sortedTasks.map(\.title), ["Open"])
        XCTAssertEqual(store.archivedTasks.map(\.title), ["Done"])
        XCTAssertEqual(undo.undoActionName, "Archive Done")
        let after = store.tasks
        store.undoManager = nil
        store.archiveDone()   // nothing finished left: no change
        XCTAssertEqual(store.tasks, after)
        store.undoManager = undo
        undo.undo()
        XCTAssertEqual(store.sortedTasks.map(\.title), ["Open", "Done"])
    }

    // MARK: Untouched tasks

    func testEditsMarkATaskTouched() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Task")
        let id = store.tasks[0].id
        XCTAssertNil(store.tasks[0].touchedAt)   // adding sets createdAt only
        let edits: [(String, () -> Void)] = [
            ("rename", { store.rename(id, to: "Task renamed") }),
            ("priority", { store.setPriority(.high, for: id) }),
            ("deadline", { store.setDeadline(Date(), for: id) }),
            ("link", { store.setLink("https://example.com", for: id) }),
            ("tag", { store.toggleTag("Work", for: id) }),
            ("tick", { store.toggle(id) }),
        ]
        for (name, edit) in edits {
            store.importBackup(Backup(exportedAt: Date(), tags: store.tags,
                                      tasks: store.tasks.map { var t = $0; t.touchedAt = nil; return t },
                                      activity: store.events), mode: .replace)
            XCTAssertNil(store.tasks[0].touchedAt, name)
            edit()
            XCTAssertNotNil(store.tasks[0].touchedAt, name)
        }
    }

    func testStaleMeansOpenAndUntouchedForThirtyDays() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let cal = Calendar(identifier: .gregorian)
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now)! }
        let tasks = [
            TaskItem(title: "30 days", createdAt: daysAgo(30)),
            TaskItem(title: "29 days", createdAt: daysAgo(29)),
            TaskItem(title: "Old but edited", createdAt: daysAgo(90), touchedAt: daysAgo(3)),
            TaskItem(title: "Old and done", isDone: true, createdAt: daysAgo(90)),
            TaskItem(title: "Old and archived", createdAt: daysAgo(90), archivedAt: daysAgo(40)),
            TaskItem(title: "Oldest", createdAt: daysAgo(200)),
        ]
        XCTAssertEqual(StaleTasks.find(in: tasks, now: now, calendar: cal).map(\.title), ["Oldest", "30 days"])
    }

    func testARestoredTaskIsNotStaleStraightAway() {
        let store = TaskStore(fileURL: fileURL)
        let old = TaskItem(title: "Learn Rust", createdAt: Date(timeIntervalSinceNow: -100 * 86_400))
        store.importBackup(Backup(exportedAt: Date(), tags: [], tasks: [old], activity: []), mode: .replace)
        XCTAssertEqual(StaleTasks.find(in: store.tasks).map(\.title), ["Learn Rust"])
        store.archive([old.id])
        XCTAssertTrue(StaleTasks.find(in: store.tasks).isEmpty)
        store.restore([old.id])
        XCTAssertTrue(StaleTasks.find(in: store.tasks).isEmpty)
    }

    func testNudgeReturnsOnlyForANewlyStaleTask() {
        let a = UUID(), b = UUID()
        XCTAssertTrue(StaleTasks.shouldNudge(stale: [a], dismissed: []))
        XCTAssertFalse(StaleTasks.shouldNudge(stale: [a], dismissed: [a]))
        XCTAssertTrue(StaleTasks.shouldNudge(stale: [a, b], dismissed: [a]))
        XCTAssertFalse(StaleTasks.shouldNudge(stale: [], dismissed: [a]))
        XCTAssertEqual(StaleTasks.decode(StaleTasks.encode([a, b])), [a, b])
        XCTAssertEqual(StaleTasks.decode("junk \(a.uuidString)"), [a])
        XCTAssertEqual(StaleTasks.summary(["Fix bike"]), "Fix bike")
        XCTAssertEqual(StaleTasks.summary(["Fix bike", "Learn Rust"]), "Fix bike and Learn Rust")
        XCTAssertEqual(StaleTasks.summary(["A", "B", "C", "D"]), "A, B and 2 more")
    }

    // MARK: Finding archived tasks

    func testSearchMatchesWordStartsInTitlesAndTags() {
        let passport = TaskItem(title: "Renew passport", tags: ["Errands"], archivedAt: Date(timeIntervalSince1970: 3))
        let cafe = TaskItem(title: "Café with Zoë", archivedAt: Date(timeIntervalSince1970: 2))
        let done = TaskItem(title: "Renew car insurance", isDone: true, archivedAt: Date(timeIntervalSince1970: 9))
        let listed = TaskItem(title: "Renew library books")
        let all = [passport, cafe, done, listed]
        XCTAssertEqual(ArchiveSearch.filter(all, query: "ren pass").map(\.title), ["Renew passport"])
        XCTAssertEqual(ArchiveSearch.filter(all, query: "REN").map(\.title),
                       ["Renew passport", "Renew car insurance"])         // open first, never listed tasks
        XCTAssertEqual(ArchiveSearch.filter(all, query: "errand").map(\.title), ["Renew passport"])
        XCTAssertEqual(ArchiveSearch.filter(all, query: "cafe zoe").map(\.title), ["Café with Zoë"])
        XCTAssertTrue(ArchiveSearch.filter(all, query: "assport").isEmpty)  // word starts only
        XCTAssertEqual(ArchiveSearch.filter(all, query: "  ").count, 3)     // blank: the whole archive
    }

    func testAddFieldOffersArchivedTasksAfterThreeLetters() {
        let tasks = (1...5).map { TaskItem(title: "Renew thing \($0)", archivedAt: Date(timeIntervalSince1970: Double($0))) }
            + [TaskItem(title: "Renew on the list")]
        XCTAssertTrue(ArchiveSearch.restoreSuggestions(for: "re", in: tasks).isEmpty)
        let three = ArchiveSearch.restoreSuggestions(for: "ren", in: tasks)
        XCTAssertEqual(three.map(\.title), ["Renew thing 5", "Renew thing 4", "Renew thing 3"])   // newest first, at most 3
        // Markers don't count as typed words: "#work", "!!", "@fri" and links are skipped.
        XCTAssertEqual(ArchiveSearch.restoreSuggestions(for: "renew thing 2 #work !! @fri https://x.com", in: tasks)
            .map(\.title), ["Renew thing 2"])
        XCTAssertTrue(ArchiveSearch.restoreSuggestions(for: "#ren !!", in: tasks).isEmpty)
        XCTAssertTrue(ArchiveSearch.restoreSuggestions(for: "Buy milk", in: tasks).isEmpty)
    }
}
