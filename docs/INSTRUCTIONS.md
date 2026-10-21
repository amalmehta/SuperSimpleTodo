# Super Simple Todo — Instructions

## Install

To put the app in /Applications (and in Launchpad and Spotlight):

```bash
./tools/install.sh
```

The script builds a Release copy, quits the running app, replaces `/Applications/Super Simple Todo.app`, and opens it. Your tasks aren't affected.

## Set up for development

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

Run the tests (31 unit tests):

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
| `@day` | Sets a deadline: `@today`, `@tomorrow`, `@fri` (the next Friday, today included), `@oct30`, `@30oct`, `@10/30` or `@2026-10-30`. A date that has already passed this year means next year. Other `@` words, like an email address, stay in the title. |

Example: `Finish report #work !!! @fri`

**Work with tasks:**
- Click the circle to tick a task done, and click again to untick it.
- Click a row to select it (⌘-click or ⇧-click for several). Then:
  - ⌫ deletes
  - Space ticks or unticks
  - Return renames (Return again saves, Esc cancels)
  - ↑↓ move the selection
- Double-click a task to rename it. Typing `#tag` or `!!` while renaming adds a tag or sets the priority.
- Right-click a task for **Rename**, **Priority ▸**, **Deadline ▸** (Today, Tomorrow, In a Week, Pick a Date…, Remove Deadline), **Tags ▸** (tick or untick a tag, or **New Tag…**) and **Delete**.
- A task with a deadline shows "Today", "Tomorrow", a weekday within the next week, or a date. Past deadlines on open tasks show a red "Overdue". Deadlines don't change the order. With several selected: **Tick or Untick** and **Delete**.
- Click a tag label to show only tasks with that tag. Click × in the "Showing" bar to show everything again.
- **Clear Done** (or ⇧⌘⌫) removes every finished task.
- The list shows open tasks first, sorted High → None and then by the order you added them. Done tasks sit at the bottom.
- **⌘Z** undoes the last change and **⇧⌘Z** redoes it. That includes deletes, Clear Done, ticks, renames, tag changes and history edits.

**Shortcuts:**
- ⌘N: new task
- ⌘1 / ⌘2 / ⌘3: Tasks / Calendar / Activity tab
- ⇧⌘⌫: Clear Done
- ⌘,: Settings

**Calendar tab:**
- **Month grid:** each day shows up to three dots in the priority colors of tasks due that day. Grey dots are done tasks. A small green check marks days you finished something.
- **Moving around:** the ‹ › arrows or a sideways swipe change the month, and **Today** jumps back.
- **Day details:** click a day to see what's due (tick tasks right there) and what you finished.

**Activity tab:**
- **Summary line:** how many tasks you completed today and this week.
- **Chart:** a bar chart of what you did each day (Added, Completed, Deleted, Unticked, Priority changed) over 7, 14 or 30 days. Hover a bar for that day's numbers.
- **Timeline:** every action with its tags.

**Editing history** (this never changes your tasks):
- Select entries and press ⌫ to delete them.
- Right-click or double-click an entry to edit its task name, action, date and time, or tags.
- To delete all history: Settings ▸ History ▸ **Clear History…**
- ⌘Z in the main window undoes any of these.

**Settings (⌘, or the gear):**
- **Hide done tasks.**
- **Tags:** add, rename, delete, or drag to reorder. Renaming or deleting a tag updates every task that has it.
- **History:** how many actions are recorded, and **Clear History…**

## Your data

Everything stays on your Mac, in `~/Library/Application Support/Super Simple Todo/`:
- `Tasks.json`: your tasks
- `Tags.json`: your tags
- `Activity.json`: the history behind the Activity tab

The app saves after every change. If a file is ever damaged and can't be read, the app keeps it as `Tasks.unreadable-<date>.json` (or the equivalent for the other files) and starts fresh, rather than overwriting it.

## Refresh the README screenshots

```bash
./tools/screenshots.sh
```

This builds the app, runs a separate test copy (with its own app ID) on generated sample data, and saves `docs/images/tasks.png`, `calendar.png` and `activity.png`. Keep the window on a Retina screen for sharp images. Your real tasks are never read. The first run may ask you to allow screen recording for your terminal.

## Trying it on sample data

Two launch options, for testing and screenshots. Neither touches your real data:

```bash
open "build/Build/Products/Debug/Super Simple Todo.app" --args -TasksFile /path/to/Tasks.json -StartTab activity
```

- `-TasksFile`: read and write tasks from that file. `Tags.json` and `Activity.json` come from the same folder.
- `-StartTab calendar` or `-StartTab activity`: open on that tab.

## Redraw the icon

```bash
swift tools/MakeIcon.swift Icon-1024.png
```

Then scale the result into `Super Simple Todo/Assets.xcassets/AppIcon.appiconset`. See [SYSTEM-DESIGN.md](SYSTEM-DESIGN.md).
