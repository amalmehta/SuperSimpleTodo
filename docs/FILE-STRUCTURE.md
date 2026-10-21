# Super Simple Todo — File Structure

```
.
├── README.md                     Overview with screenshots and links
├── project.yml                   XcodeGen spec that generates the Xcode project
├── SuperSimpleTodo.xcodeproj/    Generated Xcode project (committed so it opens without XcodeGen)
├── super_simple_todo.md          The project brief: instructions, decisions and changelog
├── Super Simple Todo/            The app's source
│   ├── SuperSimpleTodoApp.swift  App entry: main window, Settings window, menu shortcuts
│   ├── ContentView.swift         The three tabs; Tasks tab: greeting and progress ring, add field, cards (selection, keys, rename, tag filter),
│   │                             deadline labels and picker, empty states, celebration, right-click menus
│   ├── CalendarView.swift        Calendar tab: month grid with deadline dots, the selected day's due and finished tasks
│   ├── Theme.swift               Warm background and card colors for light and dark mode
│   ├── ActivityView.swift        Activity tab: summary line, daily chart, legend, hover tooltip, editable timeline, history editor
│   ├── SettingsView.swift        Settings: Hide done tasks, Tags list, History (Clear History…)
│   ├── TaskStore.swift           All data changes (tasks, tags, history) with undo; parsing #tags and !; loading, unreadable-file backup, saving
│   ├── TaskItem.swift            A task and the Priority levels
│   ├── ActivityEvent.swift       A logged action, the per-day counts behind the chart, today/this-week counts
│   └── Assets.xcassets/          App icon at every Mac size
├── Tests/
│   └── TaskStoreTests.swift      31 unit tests for the store
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
