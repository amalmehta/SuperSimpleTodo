import XCTest
@testable import Super_Simple_Todo

@MainActor
final class KeyboardControlTests: XCTestCase {
    private var fileURL: URL!
    private let a = UUID(), b = UUID(), c = UUID()

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Tasks.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    // MARK: Arrow keys

    func testArrowsWithNothingSelectedPickFirstOrLast() {
        XCTAssertEqual(ListNavigation.move(.down, from: [], in: [a, b, c]), .select(a))
        XCTAssertEqual(ListNavigation.move(.up, from: [], in: [a, b, c]), .select(c))
        XCTAssertEqual(ListNavigation.move(.down, from: [], in: []), .none)
        XCTAssertEqual(ListNavigation.move(.up, from: [a], in: []), .none)
    }

    func testArrowsStepThroughTheList() {
        XCTAssertEqual(ListNavigation.move(.down, from: [a], in: [a, b, c]), .select(b))
        XCTAssertEqual(ListNavigation.move(.down, from: [b], in: [a, b, c]), .select(c))
        XCTAssertEqual(ListNavigation.move(.up, from: [c], in: [a, b, c]), .select(b))
    }

    func testArrowsAtTheEnds() {
        XCTAssertEqual(ListNavigation.move(.down, from: [c], in: [a, b, c]), .select(c))
        XCTAssertEqual(ListNavigation.move(.up, from: [a], in: [a, b, c]), .addField)
    }

    func testArrowsFromSeveralSelectedCollapseToOne() {
        XCTAssertEqual(ListNavigation.move(.down, from: [a, b], in: [a, b, c]), .select(c))
        XCTAssertEqual(ListNavigation.move(.up, from: [b, c], in: [a, b, c]), .select(a))
    }

    func testSelectionNoLongerShownCountsAsNothingSelected() {
        XCTAssertEqual(ListNavigation.move(.down, from: [UUID()], in: [a, b]), .select(a))
    }

    // MARK: Selection after the list changes

    func testSelectionKeepsTasksStillShown() {
        XCTAssertEqual(ListNavigation.reconcile([a, b], old: [a, b, c], new: [b, c]), [b])
        XCTAssertEqual(ListNavigation.reconcile([b], old: [a, b, c], new: [c, a, b]), [b])   // re-sorted
        XCTAssertEqual(ListNavigation.reconcile([], old: [a, b], new: [a]), [])
    }

    func testDeletingSelectsTheNextTaskOrElseThePrevious() {
        XCTAssertEqual(ListNavigation.reconcile([b], old: [a, b, c], new: [a, c]), [c])
        XCTAssertEqual(ListNavigation.reconcile([a, b], old: [a, b, c], new: [c]), [c])
        XCTAssertEqual(ListNavigation.reconcile([c], old: [a, b, c], new: [a, b]), [b])
        XCTAssertEqual(ListNavigation.reconcile([a], old: [a], new: []), [])
    }

    // MARK: Keyboard actions against the store

    func testSpaceTicksTheSelectionAndItKeepsItsPlaceWhenDoneShows() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B"); store.add("C")
        let old = store.visibleTasks(hideDone: false, tag: nil).map(\.id)
        let selection: Set = [old[0]]
        store.toggle(selection)
        let new = store.visibleTasks(hideDone: false, tag: nil).map(\.id)
        XCTAssertEqual(new.last, old[0])                     // done tasks sink…
        XCTAssertEqual(ListNavigation.reconcile(selection, old: old, new: new), selection)   // …still selected
    }

    func testSpaceWithDoneHiddenMovesSelectionToTheNextTask() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A"); store.add("B"); store.add("C")
        let old = store.visibleTasks(hideDone: true, tag: nil).map(\.id)
        store.toggle(Set([old[1]]))
        let new = store.visibleTasks(hideDone: true, tag: nil).map(\.id)
        XCTAssertEqual(ListNavigation.reconcile([old[1]], old: old, new: new), [old[2]])
    }

    func testSpaceOnMixedSelectionTicksAllThenUndoRestores() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.add("A"); store.add("B")
        store.toggle(store.tasks[0].id)
        store.undoManager = undo
        let both = Set(store.tasks.map(\.id))
        undo.beginUndoGrouping(); store.toggle(both); undo.endUndoGrouping()
        XCTAssertEqual(store.tasks.map(\.isDone), [true, true])
        undo.undo()
        XCTAssertEqual(store.tasks.map(\.isDone), [true, false])
    }

    func testDeleteThenUndoBringsTheTaskBack() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.add("A"); store.add("B")
        store.undoManager = undo
        let b = store.tasks[1]
        undo.beginUndoGrouping(); store.delete(Set([b.id])); undo.endUndoGrouping()
        XCTAssertEqual(store.tasks.map(\.title), ["A"])
        XCTAssertEqual(undo.undoActionName, "Delete Task")
        undo.undo()
        XCTAssertEqual(store.tasks, [store.tasks[0], b])
    }

    func testPrioritySetsSeveralTasksAsOneUndoStep() {
        let store = TaskStore(fileURL: fileURL)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.add("A"); store.add("B !"); store.add("C")
        store.undoManager = undo
        let ab = Set(store.tasks.prefix(2).map(\.id))
        undo.beginUndoGrouping(); store.setPriority(.high, for: ab); undo.endUndoGrouping()
        XCTAssertEqual(store.tasks.map(\.priority), [.high, .high, .none])
        XCTAssertEqual(store.events.filter { $0.kind == .priorityChanged }.count, 2)
        undo.undo()
        XCTAssertEqual(store.tasks.map(\.priority), [.none, .low, .none])
    }

    func testSettingTheSamePriorityChangesNothing() {
        let store = TaskStore(fileURL: fileURL)
        store.add("A !!!")
        let events = store.events.count
        store.setPriority(.high, for: Set([store.tasks[0].id]))
        XCTAssertEqual(store.events.count, events)
    }

    // MARK: VoiceOver

    func testVoiceOverDescribesDoneStatePriorityAndTags() {
        let open = TaskItem(title: "Run 5k", priority: .medium, tags: ["Fitness", "Health"])
        XCTAssertEqual(TaskRow.accessibilityValue(for: open),
                       "Not done. Medium priority. Tags: Fitness, Health")
        let done = TaskItem(title: "Call mum", isDone: true)
        XCTAssertEqual(TaskRow.accessibilityValue(for: done), "Done. No priority")
    }

    func testVoiceOverMentionsDeadlineAndLink() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 9)))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)))
        let task = TaskItem(title: "Pay bill", priority: .high, deadline: yesterday,
                            link: URL(string: "https://www.example.com/pay"))
        let value = TaskRow.accessibilityValue(for: task, now: now, calendar: calendar)
        XCTAssertTrue(value.hasPrefix("Not done. High priority. Overdue, was due "), value)
        XCTAssertTrue(value.hasSuffix(". Next step: Open example.com"), value)
        let ticked = TaskItem(title: "Pay bill", isDone: true, deadline: yesterday)
        XCTAssertTrue(TaskRow.accessibilityValue(for: ticked, now: now, calendar: calendar).contains("Due "))
    }

    func testShortcutKeysAreSpelledOut() {
        XCTAssertEqual(SettingsView.spoken("⇧⌘⌫"), "Shift Command Delete")
        XCTAssertEqual(SettingsView.spoken("⌘1 / ⌘2"), "Command 1 or Command 2")
    }
}
