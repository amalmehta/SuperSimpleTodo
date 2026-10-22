import XCTest
@testable import Super_Simple_Todo

@MainActor
final class TagFilterTests: XCTestCase {
    private func task(_ title: String, _ tags: [String], done: Bool = false) -> TaskItem {
        TaskItem(title: title, isDone: done, tags: tags)
    }

    // MARK: Parsing the "#word" being typed

    func testActiveQueryIsTheTrailingHashWord() {
        XCTAssertEqual(TagAutocomplete.activeQuery(in: "Run 5k #fit")?.query, "fit")
        XCTAssertEqual(TagAutocomplete.activeQuery(in: "#")?.query, "")
        XCTAssertEqual(TagAutocomplete.activeQuery(in: "Plan #deep-wo")?.query, "deep-wo")
        XCTAssertEqual(TagAutocomplete.activeQuery(in: "Call mum #daily #wo")?.query, "wo")
    }

    func testActiveQueryIgnoresWordsThatArentTagsInProgress() {
        XCTAssertNil(TagAutocomplete.activeQuery(in: "Run 5k #fitness "))   // finished with a space
        XCTAssertNil(TagAutocomplete.activeQuery(in: "Learn C#"))           // "#" inside a word
        XCTAssertNil(TagAutocomplete.activeQuery(in: "Fix bug #1"))         // must start with a letter
        XCTAssertNil(TagAutocomplete.activeQuery(in: "Buy milk"))
        XCTAssertNil(TagAutocomplete.activeQuery(in: ""))
    }

    func testTypedTagsAreReadBackByTheParser() {
        let parsed = TaskStore.parse("Write report #deep-work #Work !!")
        XCTAssertEqual(parsed.title, "Write report")
        XCTAssertEqual(parsed.tags.map(TaskStore.tagName(fromTag:)), ["Deep work", "Work"])
        // What accepting a suggestion types parses back to the same tag name.
        for tag in ["Deep work", "Work", "Study"] {
            let tags = TaskStore.parse("x " + TagAutocomplete.token(for: tag)).tags
            XCTAssertEqual(tags.map(TaskStore.tagName(fromTag:)).first?.lowercased(), tag.lowercased())
        }
    }

    // MARK: Ranking and matching

    func testRankingIsByUseCountThenKnownOrder() {
        let tasks = [task("a", ["Work"]), task("b", ["Work", "Gym"]), task("c", ["Gym"], done: true),
                     task("d", ["Work"])]
        let counts = TagAutocomplete.useCounts(in: tasks)
        XCTAssertEqual(counts, ["Work": 3, "Gym": 2])
        XCTAssertEqual(TagAutocomplete.ranked(["Daily", "Gym", "Study", "Work"], by: counts),
                       ["Work", "Gym", "Daily", "Study"])
    }

    func testSuggestionsMatchIgnoringCaseWithPrefixesFirst() {
        let tags = ["Daily", "Deep work", "Work", "Homework"]
        let tasks = [task("a", ["Homework"]), task("b", ["Deep work"]), task("c", ["Deep work"])]
        XCTAssertEqual(TagAutocomplete.suggestions(for: "", tags: tags, tasks: tasks),
                       ["Deep work", "Homework", "Daily", "Work"])
        XCTAssertEqual(TagAutocomplete.suggestions(for: "D", tags: tags, tasks: tasks), ["Deep work", "Daily"])
        // "wo" starts "Work" and the second word of "Deep work"; "Homework" only contains it.
        XCTAssertEqual(TagAutocomplete.suggestions(for: "wo", tags: tags, tasks: tasks), ["Work", "Deep work"])
        XCTAssertEqual(TagAutocomplete.suggestions(for: "deep-w", tags: tags, tasks: tasks), ["Deep work"])
        XCTAssertEqual(TagAutocomplete.suggestions(for: "zzz", tags: tags, tasks: tasks), [])
        XCTAssertEqual(TagAutocomplete.suggestions(for: "", tags: tags, tasks: tasks, limit: 2).count, 2)
    }

    func testAcceptingReplacesTheTrailingHashWord() {
        XCTAssertEqual(TagAutocomplete.accept("Fitness", in: "Run 5k #fi"), "Run 5k #fitness ")
        XCTAssertEqual(TagAutocomplete.accept("Deep work", in: "#"), "#deep-work ")
        XCTAssertEqual(TagAutocomplete.accept("Work", in: "No tag here"), "No tag here")
        XCTAssertTrue(TagAutocomplete.isTyped("Deep work", as: "Deep-Work"))
        XCTAssertFalse(TagAutocomplete.isTyped("Work", as: "wor"))
    }

    // MARK: Filtering

    func testFilterTogglesClearsAndForgetsMissingTags() {
        var filter = TagFilter()
        XCTAssertFalse(filter.isActive)
        filter.toggle("Work")
        XCTAssertEqual(filter.tag, "Work")
        filter.toggle("Gym")
        XCTAssertEqual(filter.tag, "Gym")       // another tag switches the filter
        filter.toggle("Gym")
        XCTAssertNil(filter.tag)                // the same tag again shows everything
        filter.toggle("Work")
        filter.keepOnly(knownTags: ["Work", "Gym"])
        XCTAssertEqual(filter.tag, "Work")
        filter.keepOnly(knownTags: ["Gym"])     // deleted or renamed in Settings
        XCTAssertNil(filter.tag)
        filter.toggle("Gym")
        filter.clear()                          // Esc or the token's ×
        XCTAssertNil(filter.tag)
    }

    func testFilterKeepsOrderAndHonoursHideDone() {
        let tasks = [task("a", ["Work"]), task("b", ["Gym"]), task("c", ["Work", "Gym"], done: true), task("d", [])]
        XCTAssertEqual(TagFilter().apply(to: tasks, hideDone: false).map(\.title), ["a", "b", "c", "d"])
        XCTAssertEqual(TagFilter().apply(to: tasks, hideDone: true).map(\.title), ["a", "b", "d"])
        XCTAssertEqual(TagFilter(tag: "Work").apply(to: tasks, hideDone: false).map(\.title), ["a", "c"])
        XCTAssertEqual(TagFilter(tag: "Work").apply(to: tasks, hideDone: true).map(\.title), ["a"])
        XCTAssertEqual(TagFilter(tag: "work").apply(to: tasks, hideDone: false).map(\.title), [])   // exact stored name
    }
}
