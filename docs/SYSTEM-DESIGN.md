# Super Simple Todo — System Design

A single-window Mac checklist: add tasks, tick them off, clear the finished ones.

## Architecture

```mermaid
flowchart LR
    User((You)) -->|type, tick, delete| CV[ContentView<br/>main window]
    User -->|⌘,| SV[SettingsView<br/>Settings window]
    CV -->|add / toggle / delete / clearDone| TS[TaskStore<br/>ObservableObject]
    TS -->|@Published tasks| CV
    TS -->|save after every change| JSON[(Tasks.json<br/>Application Support)]
    JSON -->|load on launch| TS
    SV -->|hideDoneTasks| UD[(UserDefaults)]
    UD -->|@AppStorage| CV
```

## Components

| Component | File | Job |
|---|---|---|
| `SuperSimpleTodoApp` | `Super Simple Todo/SuperSimpleTodoApp.swift` | App entry point. Owns the one `TaskStore`, declares the main window and the Settings scene (⌘,). |
| `ContentView` / `TaskRow` | `Super Simple Todo/ContentView.swift` | The list: input field, rows with a tick button, right-click Delete, footer with "N of M done", Clear Done, and a gear button that opens Settings. |
| `SettingsView` | `Super Simple Todo/SettingsView.swift` | All preferences in one place. Today that's one: **Hide done tasks**. |
| `TaskStore` | `Super Simple Todo/TaskStore.swift` | The only place tasks change. Holds the list in memory and writes it to disk after every change. |
| `TaskItem` | `Super Simple Todo/TaskItem.swift` | One task: id, title, done flag, created date. |

## Main flows

- **Add:** type in "Add a task" and press Return. `TaskStore.add` flattens line breaks, trims spaces, ignores blanks, appends the task, and saves.
- **Tick / untick:** click the circle. `toggle` flips `isDone` and saves. Done tasks are struck through and greyed out.
- **Delete one:** right-click a task and choose Delete (or press ⌫ on a selected row).
- **Clear Done:** the footer button removes every finished task. It's disabled when nothing is done.
- **Hide done tasks:** a Settings toggle stored in UserDefaults. It only filters the view; the data isn't touched.
- **Launch:** `TaskStore` reads `Tasks.json`. If the file is missing or unreadable, the list starts empty.

## Where data lives

- Tasks: `~/Library/Application Support/Super Simple Todo/Tasks.json` (pretty-printed JSON, ISO 8601 dates, written atomically).
- Preferences: UserDefaults for `com.amalmehta.SuperSimpleTodo`, key `hideDoneTasks`.
- Nothing leaves the Mac. No network, no accounts, no sync.

## Key decisions and trade-offs

- **SwiftUI with a JSON file instead of SwiftData or Core Data.** A few dozen tasks don't need a database. The file is human-readable and easy to back up. The trade-off is rewriting the whole file on every change, which is fine at this size.
- **Save on every change.** There's no "unsaved" state to lose. The cost is one small disk write per click.
- **Atomic writes.** A crash mid-save can't leave a half-written file.
- **The store takes a file URL.** Tests use a temporary file and never touch real data.
- **Hiding is a view filter, not a delete.** Turning the setting off brings everything back.
- **XcodeGen (`project.yml`) generates the Xcode project.** The project file is reproducible and diff-friendly. It means XcodeGen must be installed to regenerate it; the generated `.xcodeproj` is committed so it opens without XcodeGen.
- **No feedback tab.** Left out at the owner's request (2026-10-06).

## Testing

- `Tests/TaskStoreTests.swift` has 6 XCTest unit tests: adding trims and ignores blanks, adding flattens line breaks, tick/untick and the done count, delete and Clear Done, saving and reloading across launches, and a corrupt file starting empty.
- Run: `xcodebuild -project SuperSimpleTodo.xcodeproj -scheme "Super Simple Todo" -derivedDataPath build test`
- Manual check (done 2026-10-06 in the running app): add, tick, right-click Delete, ⌘, Settings, Hide done tasks, Clear Done, quit and relaunch.

## Known limits

- One list only: no due dates, reordering, editing a title, or undo.
- If `Tasks.json` is corrupt, the app starts empty, and the next change overwrites the file. There's no backup.
- Only one copy of the app should run at a time; two copies would overwrite each other's saves.
- The app is ad-hoc signed for local use, not notarized for distribution.
