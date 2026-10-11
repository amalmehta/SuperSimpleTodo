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

    func testFreshStoreHasStarterSections() {
        XCTAssertEqual(TaskStore(fileURL: fileURL).sections, ["Daily", "Fitness", "Work", "Study"])
    }

    func testHashTagFilesTaskAndCreatesSections() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Run 5k #fitness !!")
        store.add("!!! Ship report #Work")
        store.add("Read paper #deep-work")
        store.add("Fix C# bug #1")
        store.add("#study")
        XCTAssertEqual(store.tasks.map(\.title), ["Run 5k", "Ship report", "Read paper", "Fix C# bug #1", "#study"])
        XCTAssertEqual(store.tasks.map(\.section), ["Fitness", "Work", "Deep work", nil, nil])
        XCTAssertEqual(store.tasks.map(\.priority), [.medium, .high, .none, .none, .none])
        XCTAssertEqual(store.sections, ["Daily", "Fitness", "Work", "Study", "Deep work"])
        XCTAssertEqual(TaskStore(fileURL: fileURL).sections, store.sections)
    }

    func testGroupedFollowsSectionOrderThenOther() {
        let store = TaskStore(fileURL: fileURL)
        store.add("a"); store.add("b #work"); store.add("c #daily"); store.add("d #work !!!")
        let groups = store.grouped(store.sortedTasks)
        XCTAssertEqual(groups.map(\.section), ["Daily", "Work", nil])
        XCTAssertEqual(groups[1].tasks.map(\.title), ["d", "b"])
    }

    func testRenameAndDeleteSection() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Squats #fitness")
        XCTAssertFalse(store.renameSection("Fitness", to: "work"))   // taken
        XCTAssertTrue(store.renameSection("Fitness", to: "Gym"))
        XCTAssertEqual(store.tasks[0].section, "Gym")
        store.deleteSection("Gym")
        XCTAssertNil(store.tasks[0].section)
        XCTAssertFalse(store.sections.contains("Gym"))
    }

    func testSetSectionAndEventsCarrySection() {
        let store = TaskStore(fileURL: fileURL)
        store.add("Plan week #work")
        store.setSection("Daily", for: store.tasks[0].id)
        store.toggle(store.tasks[0].id)
        XCTAssertEqual(store.events.map(\.section), ["Work", "Daily"])
    }

    func testCorruptFileStartsEmpty() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        XCTAssertTrue(TaskStore(fileURL: fileURL).tasks.isEmpty)
    }
}
