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

    func testCorruptFileStartsEmpty() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        XCTAssertTrue(TaskStore(fileURL: fileURL).tasks.isEmpty)
    }
}
