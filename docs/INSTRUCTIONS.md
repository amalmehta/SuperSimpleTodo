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

Run the tests (85 unit tests):

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

| A link | `https://…` or `www.…` anywhere becomes the task's next step, shown under its title. |

Example: `Finish report #work !!! @fri`

**Work with tasks:**
- Click the circle to tick a task done, and click again to untick it.
- Click a row to select it (⌘-click or ⇧-click for several). Then:
  - ⌫ deletes
  - Space ticks or unticks
  - Return renames (Return again saves, Esc cancels)
  - ↑↓ move the selection
- Double-click a task to rename it. Typing `#tag` or `!!` while renaming adds a tag or sets the priority.
- Right-click a task for **Rename**, **Priority ▸**, **Deadline ▸** (Today, Tomorrow, In a Week, Pick a Date…, Remove Deadline), **Tags ▸** (tick or untick a tag, or **New Tag…**), **Archive** and **Delete**.
- **Next steps:**
  - A task with a link shows **↗ Open <site>** under its title. Click it to open the page.
  - Add, change or remove a link with right-click ▸ **Add Link…** / **Edit Link…** / **Remove Link**. There, a bare `site.com/page` works too.
  - Tasks without a link show **✦ Ask Claude how to start** when you rest the pointer on them or select them. It opens a new chat in the Claude desktop app, or at claude.ai in your browser if the app isn't installed, with the task (and its deadline, if any) already typed in. Nothing is sent until you click; you press send in Claude yourself.
  - Right-click ▸ **Ask Claude How to Start** does the same for any task.
- A task with a deadline shows "Today", "Tomorrow", a weekday within the next week, or a date. Past deadlines on open tasks show a red "Overdue". Deadlines don't change the order. With several selected: **Tick or Untick** and **Delete**.
- Type `#` in the add field to pick from your tags, most used first. Keep typing to narrow the list, ↑↓ to choose, Tab or Return to add it, Esc to close it.
- Click a tag on a task to show only tasks with that tag. Click × on the "Showing" token, or press Esc, to show everything again.
- **Archive Done** (or ⇧⌘⌫) moves every finished task to the archive. Nothing is deleted.
- The list shows open tasks first, sorted High → None and then by the order you added them. Done tasks sit at the bottom.
- **⌘Z** undoes the last change and **⇧⌘Z** redoes it. That includes deletes, archiving and restoring, ticks, renames, tag changes and history edits.

**Archive** (for tasks that aren't for now):
- **Park a task:** right-click ▸ **Archive**, or select tasks and press ⌃⌘A. It leaves the list and the calendar but keeps its title, tags, priority, deadline and link.
- **Finished tasks:** **Archive Done** (⇧⌘⌫) moves them all to the archive.
- **Untouched tasks:** when an open task hasn't been added, edited, ticked or restored for 30 days, a bar above the list says so, e.g. "2 untouched for 30+ days: Learn Rust and Fix the bike". **Archive Them** archives them (⌘Z brings them back). **Not Now** hides the bar until another task goes stale. Nothing is ever archived without your click.
- **Open the archive:** click **Archived N** at the bottom left, or press ⇧⌘A. Parked tasks come first, then finished ones (struck through), newest first.
  - Type in the search field to narrow it: every word you type must start a word of the task or one of its tags, so `ren pass` finds "Renew passport" and `fit` finds Fitness tasks.
  - **Restore** with the ↺ button, Return on a selected task, a double-click, or right-click ▸ **Restore**. Return in the search field restores the top result. A restored task comes back **open**, even if it was finished, so recurring jobs are easy to bring back.
  - ⌫ or right-click ▸ **Delete for Good** deletes it (⌘Z still brings it back).
  - Esc clears the search, then a second Esc goes back to the list. So does **‹ Back to Tasks** or ⇧⌘A.
- **Bring one back while typing:** once you've typed three letters in the add field, archived tasks that match show up under it ("In your archive"). Press ↓ to pick one and Return to restore it, or click it. Without ↓, Return adds your text as a new task as usual.

**Shortcuts** (also listed in Settings ▸ Keyboard Shortcuts):
- ⌘N: new task (jumps to the add field)
- ↓ in the add field: into the list. ↑ / ↓: move the selection; ↑ on the first task goes back to the add field
- Space: tick or untick the selected tasks
- Return: rename the selected task (Esc stops), or go to the add field when nothing is selected
- ⌫: delete the selected tasks (⌘Z brings them back)
- ⌃⌘A: archive the selected tasks (in the archive: restore them)
- ⇧⌘A: open or leave the archive
- #: tag suggestions in the add field (↑ ↓ to pick, Tab or Return to add)
- Esc: close the suggestions, clear the tag filter, or (in the archive) clear the search and go back
- ⌘1 / ⌘2 / ⌘3: Low / Medium / High priority for the selected tasks; ⌘0: no priority
- ⌥⌘1 / ⌥⌘2 / ⌥⌘3: Tasks / Calendar / Activity tab
- ⇧⌘⌫: Archive Done
- ⌘,: Settings

**VoiceOver:** each task reads as its title, then done or not done, priority, tags, deadline and link. Its actions (VO-⌘-Space) tick it, rename it, open its next step or filter by a tag.

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
- `Tasks.json`: your tasks, archived ones included (marked with the date they were archived)
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
