<img src="docs/images/icon.png" width="96" align="left" alt="Super Simple Todo icon">

# Super Simple Todo

A friendly, very simple Mac checklist: one list, priorities shown by color, optional #tags and deadlines, a calendar, and a chart of what you got done.

<br clear="left">

<p>
  <img src="docs/images/tasks.png" width="270" alt="Tasks tab: a greeting with a progress ring, then task cards with colored priority circles, deadline labels and tags">
  <img src="docs/images/calendar.png" width="270" alt="Calendar tab: a month grid with dots on days that have deadlines, and the selected day's tasks below">
  <img src="docs/images/activity.png" width="270" alt="Activity tab: actions per day as stacked bars, with a timeline below">
</p>

Type `Run 5k #fitness !! @fri` → a Medium-priority task tagged Fitness, due Friday. Paste a link into a task and it shows underneath as the next step; tasks without one offer **Ask Claude how to start**. Type `#` to pick a tag, click a tag to filter (Esc clears it), double-click to rename, ⌘Z to undo.

| Circle | Priority | Type at the end |
|---|---|---|
| 🔴 Red | High | `!!!` |
| 🟠 Orange | Medium | `!!` |
| 🔵 Blue | Low | `!` |
| ⚪ Grey | None | — |

```mermaid
flowchart LR
    You((You)) --> Tasks[Tasks tab] & Calendar[Calendar tab] & Activity[Activity tab] & Settings["Settings (⌘,)"]
    Tasks & Calendar & Activity & Settings --> Store[TaskStore]
    Store --> Tasks & Calendar & Activity
    Store --> Files[("Tasks.json · Tags.json · Activity.json")]
```

**Docs**
- [How to set up, run and use it](docs/INSTRUCTIONS.md)
- [System design](docs/SYSTEM-DESIGN.md)
- [What's where](docs/FILE-STRUCTURE.md)
