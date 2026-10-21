# Super Simple Todo — File Structure

```
.
├── README.md                     Overview with screenshots and links
├── project.yml                   XcodeGen spec that generates the Xcode project
├── SuperSimpleTodo.xcodeproj/    Generated Xcode project (committed so it opens without XcodeGen)
├── super_simple_todo.md          The project brief: instructions, decisions and changelog
├── Super Simple Todo/            The app's source
│   ├── SuperSimpleTodoApp.swift  App entry: main window + Settings window
│   ├── ContentView.swift         Tasks | Activity tabs; the task list, rows, tag labels, color key, right-click menus
│   ├── ActivityView.swift        Activity tab: daily chart, legend, hover tooltip, timeline
│   ├── SettingsView.swift        Settings: Hide done tasks, Tags list
│   ├── TaskStore.swift           All data changes: add, tick, priority, tags, delete; parsing #tags and !; loading and saving
│   ├── TaskItem.swift            A task and the Priority levels
│   ├── ActivityEvent.swift       A logged action, and the per-day counts behind the chart
│   └── Assets.xcassets/          App icon at every Mac size
├── Tests/
│   └── TaskStoreTests.swift      18 unit tests for the store
├── tools/
│   └── MakeIcon.swift            Draws the 1024 px app icon
└── docs/
    ├── INSTRUCTIONS.md           Set up, run, use
    ├── SYSTEM-DESIGN.md          Architecture, flows, data, decisions, tests, limits
    ├── FILE-STRUCTURE.md         This file
    └── images/                   README screenshots and icon
```

Not in the repo: `build/` (build output, ignored by git) and your data in `~/Library/Application Support/Super Simple Todo/`.
