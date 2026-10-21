<img src="docs/images/icon.png" width="96" align="left" alt="Super Simple Todo icon">

# Super Simple Todo

A very simple Mac checklist: one list, priorities shown by color, optional #tags, and a chart of what you got done.

<br clear="left">

<p>
  <img src="docs/images/tasks.png" width="380" alt="Tasks tab: one list sorted by priority, colored circles, tag labels">
  <img src="docs/images/activity.png" width="380" alt="Activity tab: actions per day as stacked bars, with a timeline below">
</p>

Type `Run 5k #fitness !!` → a Medium-priority task tagged Fitness. Click a tag to filter, double-click to rename, ⌘Z to undo.

| Circle | Priority | Type at the end |
|---|---|---|
| 🔴 Red | High | `!!!` |
| 🟠 Orange | Medium | `!!` |
| 🔵 Blue | Low | `!` |
| ⚪ Grey | None | — |

```mermaid
flowchart LR
    You((You)) --> Tasks[Tasks tab] & Activity[Activity tab] & Settings["Settings (⌘,)"]
    Tasks & Settings --> Store[TaskStore]
    Store --> Activity
    Store --> Files[("Tasks.json · Tags.json · Activity.json")]
```

**Docs**
- [How to set up, run and use it](docs/INSTRUCTIONS.md)
- [System design](docs/SYSTEM-DESIGN.md)
- [What's where](docs/FILE-STRUCTURE.md)
