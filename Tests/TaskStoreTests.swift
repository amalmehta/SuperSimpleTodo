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

    // MARK: Deadlines

    /// Wednesday 21 October 2026, noon, in a fixed calendar.
    private var wednesday: (now: Date, cal: Calendar) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return (cal.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 12))!, cal)
    }

    private func ymd(_ date: Date?, _ cal: Calendar) -> String? {
        date.map { let c = cal.dateComponents([.year, .month, .day], from: $0); return "\(c.year!)-\(c.month!)-\(c.day!)" }
    }

    func testParseDayUnderstandsCommonWords() {
        let (now, cal) = wednesday
        let cases: [(String, String?)] = [
            ("today", "2026-10-21"), ("tomorrow", "2026-10-22"), ("tmrw", "2026-10-22"),
            ("fri", "2026-10-23"), ("Friday", "2026-10-23"), ("wed", "2026-10-21"), ("tue", "2026-10-27"),
            ("oct30", "2026-10-30"), ("october30", "2026-10-30"), ("30oct", "2026-10-30"), ("10/30", "2026-10-30"),
            ("2026-11-02", "2026-11-2"), ("jan5", "2027-1-5"), ("oct1", "2027-10-1"),
            ("sunny", nil), ("feb30", nil), ("foo", nil), ("12", nil),
        ]
        for (word, expected) in cases {
            XCTAssertEqual(ymd(TaskStore.parseDay(word, now: now, calendar: cal), cal), expected, word)
        }
    }

    func testAtDayInTextSetsDeadlineAndOtherAtsStay() {
        let (now, cal) = wednesday
        let parsed = TaskStore.parse("Pay rent @fri #daily !!!", now: now, calendar: cal)
        XCTAssertEqual(parsed.title, "Pay rent")
        XCTAssertEqual(ymd(parsed.deadline, cal), "2026-10-23")
        XCTAssertEqual(parsed.priority, .high)
        let email = TaskStore.parse("Email sam@example.com @nowhere", now: now, calendar: cal)
        XCTAssertEqual(email.title, "Email sam@example.com @nowhere")
        XCTAssertNil(email.deadline)
    }

    func testSetDeadlineRenameAndUndo() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.undoManager = undo
        func step(_ action: () -> Void) { undo.beginUndoGrouping(); action(); undo.endUndoGrouping() }

        step { store.add("Ship report @tomorrow") }
        let id = store.tasks[0].id
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        XCTAssertEqual(store.tasks[0].deadline, tomorrow)
        step { store.setDeadline(Date(), for: id) }
        XCTAssertEqual(store.tasks[0].deadline, Calendar.current.startOfDay(for: Date()))   // time dropped
        step { store.setDeadline(nil, for: id) }
        XCTAssertNil(store.tasks[0].deadline)
        undo.undo()
        XCTAssertEqual(store.tasks[0].deadline, Calendar.current.startOfDay(for: Date()))
        step { store.rename(id, to: "Ship the report @tomorrow") }
        XCTAssertEqual(store.tasks[0].title, "Ship the report")
        XCTAssertEqual(store.tasks[0].deadline, tomorrow)
    }

    func testDeadlineIsSavedAsPlainDate() throws {
        let store = TaskStore(fileURL: fileURL)
        store.add("Plan @2026-11-02")
        let saved = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(saved.contains("\"deadline\" : \"2026-11-02\""), saved)
        XCTAssertEqual(TaskStore(fileURL: fileURL).tasks[0].deadline, store.tasks[0].deadline)
        store.add("Nothing due")   // a task without a deadline writes no deadline key
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8).components(separatedBy: "\"deadline\"").count, 2)
    }

    func testDayListsForTheCalendar() {
        let store = TaskStore(fileURL: fileURL)
        store.add("low @today !"); store.add("high @today !!!"); store.add("later @2099-01-01"); store.add("none")
        store.toggle(store.tasks[3].id)
        let today = Date()
        XCTAssertEqual(store.tasks(dueOn: today).map(\.title), ["high", "low"])
        XCTAssertEqual(store.completions(on: today).map(\.taskTitle), ["none"])
        XCTAssertTrue(store.completions(on: Date(timeIntervalSinceNow: -86_400 * 3)).isEmpty)
    }

    func testDeadlineLabelText() {
        let (now, cal) = wednesday
        let day = { (offset: Int) in cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now))! }
        XCTAssertEqual(DeadlineLabel.text(for: day(-1), now: now, calendar: cal), "Overdue")
        XCTAssertEqual(DeadlineLabel.text(for: day(0), now: now, calendar: cal), "Today")
        XCTAssertEqual(DeadlineLabel.text(for: day(1), now: now, calendar: cal), "Tomorrow")
        XCTAssertEqual(DeadlineLabel.text(for: day(2), now: now, calendar: cal),
                       day(2).formatted(.dateTime.weekday(.abbreviated)))
        XCTAssertEqual(DeadlineLabel.text(for: day(9), now: now, calendar: cal),
                       day(9).formatted(.dateTime.month(.abbreviated).day()))
    }

    // MARK: Next steps

    func testLinksInTypedTextBecomeTheNextStep() {
        let (now, cal) = wednesday
        let a = TaskStore.parse("Pay toyota https://www.toyotafinancial.com/us/en.html, @fri !!", now: now, calendar: cal)
        XCTAssertEqual(a.title, "Pay toyota")
        XCTAssertEqual(a.link?.absoluteString, "https://www.toyotafinancial.com/us/en.html")
        XCTAssertEqual(ymd(a.deadline, cal), "2026-10-23")
        let b = TaskStore.parse("Read www.example.com/guide.", now: now, calendar: cal)
        XCTAssertEqual(b.title, "Read")
        XCTAssertEqual(b.link?.absoluteString, "https://www.example.com/guide")
        let c = TaskStore.parse("Email sam@example.com about example.com", now: now, calendar: cal)
        XCTAssertEqual(c.title, "Email sam@example.com about example.com")   // needs http(s):// or www.
        XCTAssertNil(c.link)
    }

    func testSetLinkAcceptsAddressesAndUndoes() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.undoManager = undo
        func step(_ action: () -> Void) { undo.beginUndoGrouping(); action(); undo.endUndoGrouping() }

        step { store.add("Buy keyboard") }
        let id = store.tasks[0].id
        XCTAssertFalse(store.setLink("not a link", for: id))
        XCTAssertNil(store.tasks[0].link)
        step { XCTAssertTrue(store.setLink("keychron.com/products", for: id)) }   // bare domain is fine here
        XCTAssertEqual(store.tasks[0].link?.absoluteString, "https://keychron.com/products")
        XCTAssertEqual(TaskStore(fileURL: fileURL).tasks[0].link, store.tasks[0].link)   // saved
        step { store.setLink(nil, for: id) }
        XCTAssertNil(store.tasks[0].link)
        undo.undo()
        XCTAssertEqual(store.tasks[0].link?.host(), "keychron.com")
        step { store.rename(id, to: "Buy a keyboard https://www.apple.com/shop") }
        XCTAssertEqual(store.tasks[0].title, "Buy a keyboard")
        XCTAssertEqual(store.tasks[0].link?.host(), "www.apple.com")
    }

    func testNextStepLabelAndClaudeLink() throws {
        XCTAssertEqual(NextStep.linkLabel(URL(string: "https://www.toyotafinancial.com/x")!), "Open toyotafinancial.com")
        var task = TaskItem(title: "File taxes & receipts")
        task.deadline = Calendar.current.date(from: DateComponents(year: 2027, month: 4, day: 15))
        XCTAssertEqual(NextStep.claudeURL(for: task, inApp: false).scheme, "https")
        let url = NextStep.claudeURL(for: task, inApp: true)
        XCTAssertEqual(url.scheme, "claude")              // the Claude desktop app's link
        XCTAssertEqual(url.host(), "claude.ai")
        XCTAssertEqual(url.path(), "/new")
        let prompt = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "q" }?.value)
        XCTAssertTrue(prompt.contains("\u{201C}File taxes & receipts\u{201D}"), prompt)   // & survives encoding
        XCTAssertTrue(prompt.contains("It's due"), prompt)
        XCTAssertTrue(prompt.contains("first concrete step"), prompt)
    }
}
