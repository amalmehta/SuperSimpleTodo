# Super Simple Todo — Instructions

## Set up

You need a Mac with macOS 14 or later and Xcode installed.

[XcodeGen](https://github.com/yonaskolb/XcodeGen) is only needed if you add or remove source files. The generated Xcode project is already in the repo.

```bash
brew install xcodegen
```

## Run

Open `SuperSimpleTodo.xcodeproj` in Xcode and press ⌘R. Or build from the terminal:

```bash
xcodebuild -project SuperSimpleTodo.xcodeproj -scheme "Super Simple Todo" -derivedDataPath build build
open "build/Build/Products/Debug/Super Simple Todo.app"
```

Run the tests (18 unit tests):

```bash
xcodebuild -project SuperSimpleTodo.xcodeproj -scheme "Super Simple Todo" -derivedDataPath build test
```

After adding or removing a source file, regenerate the project:

```bash
xcodegen generate
```

## Use

**Add a task:** type in "Add a task" and press Return. Add these anywhere in the text:

| Type | Does |
|---|---|
| `!`, `!!`, `!!!` | Low, Medium, High priority (red, orange, blue circle; grey is none) |
| `#name` | Adds a tag. A new name creates the tag, e.g. `#deep-work` → "Deep work". Use as many as you like. |

Example: `Finish report #work !!!`

**Work with tasks:**
- Click the circle to tick a task done, and click again to untick it.
- Right-click a task for **Priority ▸**, **Tags ▸** (tick or untick a tag, or **New Tag…**) and **Delete**.
- **Clear Done** removes every finished task.
- The list is sorted High → None, and keeps the order you added tasks within each level.

**Activity tab:** a bar chart of what you did each day (Added, Completed, Deleted, Unticked, Priority changed) over 7, 14 or 30 days. Hover a bar for that day's numbers. The timeline below lists every action with its tags.

**Settings (⌘, or the gear):**
- **Hide done tasks.**
- **Tags:** add, rename, delete, or drag to reorder. Renaming or deleting a tag updates every task that has it.

## Your data

Everything stays on your Mac, in `~/Library/Application Support/Super Simple Todo/`:
- `Tasks.json`: your tasks
- `Tags.json`: your tags
- `Activity.json`: the history behind the Activity tab

The app saves after every change.

## Trying it on sample data

Two launch options, for testing and screenshots. Neither touches your real data:

```bash
open "build/Build/Products/Debug/Super Simple Todo.app" --args -TasksFile /path/to/Tasks.json -StartTab activity
```

- `-TasksFile`: read and write tasks from that file. `Tags.json` and `Activity.json` come from the same folder.
- `-StartTab activity`: open on the Activity tab.

## Redraw the icon

```bash
swift tools/MakeIcon.swift Icon-1024.png
```

Then scale the result into `Super Simple Todo/Assets.xcassets/AppIcon.appiconset`. See [SYSTEM-DESIGN.md](SYSTEM-DESIGN.md).
