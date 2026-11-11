# Super Simple Todo — File Structure

```
.
├── README.md                     Overview with screenshots and links
├── project.yml                   XcodeGen spec that generates the Xcode project
├── SuperSimpleTodo.xcodeproj/    Generated Xcode project (committed so it opens without XcodeGen)
├── super_simple_todo.md          The project brief: instructions, decisions and changelog
├── Super Simple Todo/            The app's source
│   ├── SuperSimpleTodoApp.swift  App entry: main window, Settings window, menu shortcuts
│   ├── ContentView.swift         The three tabs; Tasks tab: greeting and progress ring, add field, cards (selection, keys, rename, tag chips and filter token),
│   │                             # tag suggestions under the add field,
│   │                             deadline labels and picker, next-step links (NextStep), empty states, celebration, right-click menus
│   ├── CalendarView.swift        Calendar tab: month grid with deadline dots, the selected day's due and finished tasks
│   ├── Theme.swift               Warm background and card colors for light and dark mode
│   ├── ActivityView.swift        Activity tab: summary line, daily chart, legend, hover tooltip, editable timeline, history editor
│   ├── TagFilter.swift           The tag filter (TagFilter) and the # autocomplete's parsing, ranking and matching (TagAutocomplete)
│   ├── KeyboardControl.swift     Arrow-key and after-delete selection (ListNavigation), the shortcut list for Settings
│   ├── SettingsView.swift        Settings: Hide done tasks, Tags list, History (Clear History…), Keyboard Shortcuts
│   ├── TaskStore.swift           All data changes (tasks, tags, history) with undo; parsing #tags and !; loading, unreadable-file backup, saving
│   ├── Backup.swift              The versioned export file: encoding, checked decoding, error messages
│   ├── BackupPanels.swift        File ▸ Export… and Import…: save and open panels, Merge or Replace question, alerts
│   ├── TaskItem.swift            A task and the Priority levels
│   ├── ActivityEvent.swift       A logged action, the per-day counts behind the chart, today/this-week counts
│   └── Assets.xcassets/          App icon at every Mac size
├── Tests/
│   ├── TaskStoreTests.swift      38 unit tests for the store
│   ├── TagFilterTests.swift      8 tests: the #word being typed, ranking by use, matching, accepting, filtering
│   ├── BackupTests.swift         11 tests: export/import round trip incl. Activity data, merge dedupe, undo, file format, errors
│   ├── KeyboardControlTests.swift 16 tests: arrow keys, selection after changes, Space/⌫/priority with undo, VoiceOver text
│   └── Fixtures/SectionsVersion/ Tasks.json, Sections.json and Activity.json as the sections version saved them, for the upgrade tests
├── tools/
│   ├── MakeIcon.swift            Draws the 1024 px app icon
│   ├── install.sh                Builds a Release copy and installs it in /Applications
│   └── screenshots.sh            Retakes the three README screenshots on sample data
└── docs/
    ├── INSTRUCTIONS.md           Set up, run, use
    ├── SYSTEM-DESIGN.md          Architecture, flows, data, decisions, tests, limits
    ├── FILE-STRUCTURE.md         This file
    └── images/                   README screenshots and icon
```

Not in the repo: `build/` (debug and `build/release` output, ignored by git) and your data in `~/Library/Application Support/Super Simple Todo/`.
