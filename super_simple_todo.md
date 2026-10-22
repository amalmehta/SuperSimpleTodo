PROJECT NAME: super_simple_todo

META-INSTRUCTIONS:

<Read it all before acting. Ask about anything unclear, contradictory or
 underspecified — before starting and mid-build. Ask in the question widget
 (AskUserQuestion): related questions batched, concrete options, your
 recommendation first. Plain text only if the widget isn't available.>

<Don't expand scope. Anything not listed here is a proposal, including changes
 to this file — propose it, don't do it.>

<Prefer doing over describing: run the code, write the files, test it.>

<Always in scope, no proposal needed: when it goes on GitHub, a README that is
 easy to read at a glance — a line on what it is, then clear visuals
 (screenshots, a diagram or a chart), then links. Everything else goes in
 linked files: docs/INSTRUCTIONS.md (setup, run, use),
 docs/SYSTEM-DESIGN.md (see below) and docs/FILE-STRUCTURE.md (what's where). If what you're
 building is an application rather than a script, also a small unobtrusive feedback tab, and a settings
 button or tab (⌘, on the Mac) that gathers its preferences in one place.>

<If what you're building is an application, build it as a Mac app first; the
 website comes after, as its own step.>

<Name things the way a person would say them — "Goal Tracker", not
 goal_tracker — for the app, its windows, titles, files people open, repo
 descriptions and README headings. When you create the GitHub repo, name it
 with no "_" or "-": one word or joined words, e.g. GoalTracker.>

<Always in scope: a system design doc in the codebase, docs/SYSTEM-DESIGN.md,
 kept current as the build changes. Cover the architecture (with a Mermaid
 diagram), each component's job, the main flows, where data lives, the key
 design decisions and their trade-offs, how it's tested, and known limits.>

<Finish by listing every deliverable: path, what it is, how to check it works.>

<Git rules (no Claude attribution, never commit .claude/) are in
 ~/.claude/CLAUDE.md and apply on their own — nothing to repeat here.>

<Keep the changelog at the bottom current.>

CONTEXT:

just a very straightforward list that keeps track of tasks done

DELIVERABLES:

mac app

OPEN QUESTIONS / ASSUMPTIONS:

Asked and answered (2026-10-06):
- List model: a checklist. Add tasks, tick them off; done tasks stay visible, struck through, until "Clear Done".
- Feedback tab: skipped, at the owner's request.
- GitHub: local git only, no repo created or pushed. So no README, INSTRUCTIONS.md or FILE-STRUCTURE.md yet; those come with the GitHub step.
- Settings (⌘, and a gear button): one preference, "Hide done tasks".

Asked and answered (2026-10-10, priorities, colors and activity):
- Priorities: High / Medium / Low / None, auto-sorted High first; shown as the tick circle's color (red, orange, blue, grey).
- Set by right-click ▸ Priority, or by ending a new task with " !", " !!" or " !!!".
- Color meanings: a one-line key under the input field, plus a hover tooltip on each circle.
- Activity: a "Tasks | Activity" tab switcher in the main window. Logs added, completed, unticked, deleted/cleared and priority changes. Stacked bars per day (7/14/30 days) over a timeline.

Asked and answered (2026-10-11, sections):
- Layout: grouped, collapsible headers in one list, then "Other" for unfiled tasks.
- Filing and creating sections on the fly: type #name in a task ("Run 5k #fitness !!"); an unknown #name creates the section. Right-click ▸ Section moves a task.
- Starting sections: Daily, Fitness, Work, Study.
- Activity: each timeline row shows the task's section.

Asked and answered (2026-10-21, tags replace sections):
- "Make it just 1 singular list, with an option to add tags, not separate categories." Sections are gone; tasks carry tags.

Asked and answered (2026-10-21, next steps):
- "For relevant tasks provide a next step underneath, like the link to the thing or a link to a Claude session; don't overcomplicate it." Source: your own links plus an "Ask Claude" link (no API). Visibility: a task's link always shows; Ask Claude appears on hover or selection.

Decided without asking (2026-10-21, next steps):
- Ask Claude opens a new chat with the task title, deadline and a request for the first concrete step; nothing is sent until clicked. Changed 2026-10-21 at the owner's request: it opens in the Claude desktop app (claude://claude.ai/new?q=…), falling back to claude.ai in the browser when the app isn't installed.
- Links typed into a task need https:// or www. (so emails and plain words like "example.com" stay in the title); Add Link… also accepts a bare domain.
- A short hover delay (~0.45 s) before Ask Claude shows, so rows don't flicker.
- tools/screenshots.sh now launches the test copy in the background (open -g): bringing it to the front once captured the owner's keystrokes.

Asked and answered (2026-10-21, friendlier look, deadlines and calendar):
- Look: "warm & soft", with a greeting and progress ring, friendly empty states, a gentle tick animation (plus a small all-done celebration), and softer card rows.
- Deadlines: date only, set by typing @day (@fri, @tomorrow, @oct30…) or right-click ▸ Deadline; shown as a small label (red "Overdue"), without changing the sort.
- Calendar tab: month grid with deadline dots; clicking a day shows what's due and what you finished.

Decided without asking (2026-10-21, look, deadlines and calendar):
- Deadlines are stored as plain "yyyy-MM-dd" days so they don't move across time zones; @weekday includes today; past month-day dates mean next year.
- Setting a deadline isn't an Activity event (keeps the chart's five colors).
- Tabs are Tasks | Calendar | Activity (⌘1/⌘2/⌘3, moved to ⌥⌘1/⌥⌘2/⌥⌘3 on 2026-10-21 for priority keys); animations respect Reduce Motion.
- The footer's "N of M done" moved into the greeting's progress line and ring.

Asked and answered (2026-10-21, improvements):
- "Do all that": the ten proposed improvements (row selection with ⌫/Space/Return, unreadable-file backup, done tasks sink, undo, rename, tag filter, menu shortcuts, completed today/this week, install script, screenshot script).
- "There should be a way to delete / modify the history of tasks": history entries can be edited (title, action, date and time, tags) or deleted from the Activity timeline, and the whole log cleared in Settings.

Decided without asking (2026-10-21, improvements):
- History edits never change tasks; they're undoable like everything else.
- Undo uses a snapshot of tasks, tags and history per change, and lives in the main window (⌘Z in Settings doesn't undo).
- Plain renames aren't logged in Activity; a rename that changes priority is.
- The timeline's day headers became plain rows, because pinned List headers could hide the row beneath them (seen in the owner's screenshot).
- tools/install.sh was run: the app is installed in /Applications.

Decided without asking (2026-10-21):
- A task can have several tags, shown as small grey labels after its title; the list stays one list sorted by priority.
- Add tags by typing #name (every #word counts; new names create tags), or right-click ▸ Tags ▸ tick a tag / New Tag…; manage them in Settings ▸ Tags.
- The four starter names (Daily, Fitness, Work, Study) carry over as suggested tags; any old section on a task becomes a tag (see the upgrade decisions below).
- Adding or removing a tag isn't an Activity event; no tag filter yet.

Decided without asking (2026-10-21, upgrading from sections):
- Saved sections data is migrated once, on the first launch: each task's section becomes the tag of the same name (matched ignoring case; "Other" and blank sections get no tag), keeping task order, priority and done state.
- The old section list becomes the tag list in the same order, empty sections included; the starter tags aren't added on top.
- Logged actions keep their old section as a tag, even one deleted since, without adding it back to the tag list.
- The migrated files are saved straight away in the tags format. Sections.json is renamed Sections.migrated.json rather than deleted, and the leftover "collapsed sections" preference is removed.
- No section code, Settings UI or strings remain; only the migration reads the old format.

Decided without asking (sections, superseded 2026-10-21):
- Section rename, delete and reorder live in Settings ▸ Sections (deleting moves tasks to Other).
- #tags must start with a letter ("#1", "C#" stay in the title); "#deep-work" becomes "Deep work"; the first tag wins; one section per task.
- Every section always shows, with an "Add one with #name" hint when empty (changed 2026-10-11 — hiding empty sections made them look missing); collapsed sections are remembered.
- Moving a task between sections isn't an Activity event (it wasn't in the chosen list of actions).
- App icon: a white checklist tile with red (ticked), orange and blue circles matching the priority colors; drawn by tools/MakeIcon.swift.
- Activity chart colors come from a separate palette checked for color-blind separation (blue, orange, aqua, yellow, pink), with a legend; the timeline also uses icons.
- History from before tracking started is filled in only as "Added" events, from task creation dates.
- Activity saved as Activity.json next to Tasks.json; the log is never trimmed.
- A developer launch option (-StartTab activity) opens on the Activity tab, for screenshots.
- GitHub: private repo SuperSimpleTodo (owner's choice, 2026-10-21).
- A developer launch option (-TasksFile) points the app at sample data, so testing never touches real tasks.
- SwiftUI app for macOS 14+, Xcode project generated by XcodeGen from project.yml.
- Tasks saved as JSON in ~/Library/Application Support/Super Simple Todo/Tasks.json after every change; preferences in UserDefaults.
- Delete a single task by right-clicking it (or ⌫ on a selected row).
- Pasted line breaks in a task become spaces.
- Ad-hoc code signing (runs on this Mac; not notarized).

CHANGELOG:

- 2026-10-21 — sections data from earlier versions is now migrated to tags once on load (saved straight away, Sections.json kept as Sections.migrated.json, old collapsed-sections preference cleared); section handling removed from tasks and history; upgrade tests against a sections-version fixture; 54 unit tests (an earlier Sections.migrated.json gets a dated name instead of blocking the rename)
- 2026-10-21 — Ask Claude now opens a new chat in the Claude desktop app instead of the browser (browser only if the app isn't installed)
- 2026-10-21 — next steps: task links ("↗ Open site") and "✦ Ask Claude how to start" (claude.ai prefilled) under tasks; right-click Add/Edit/Remove Link; screenshot script no longer takes focus; 34 unit tests
- 2026-10-21 — friendlier look (warm background, greeting + progress ring, card rows, empty states, tick animation, all-done celebration); deadlines (@day, right-click ▸ Deadline, Overdue label); Calendar tab; 31 unit tests
- 2026-10-21 — added selection and keys (⌫, Space, Return), rename, tag filter, undo/redo, menu shortcuts, done tasks at the bottom, completed today/this week, editable and clearable history, unreadable-file backup, tools/install.sh and tools/screenshots.sh; fixed day headers hiding timeline rows; 25 unit tests
- 2026-10-21 — pushed to a private GitHub repo (SuperSimpleTodo) with README, screenshots, docs/INSTRUCTIONS.md and docs/FILE-STRUCTURE.md; added a -StartTab launch option for screenshots
- 2026-10-21 — replaced sections with tags: one priority-sorted list, several #tags per task shown as labels, right-click ▸ Tags, Settings ▸ Tags; old sections load as tags; 18 unit tests
- 2026-10-11 — sections now always show, even when empty, with an "Add one with #name" hint
- 2026-10-11 — added the app icon (tools/MakeIcon.swift → Assets.xcassets) and rebuilt
- 2026-10-11 — added sections: #tag filing with on-the-fly creation, collapsible grouped headers, right-click ▸ Section, Settings ▸ Sections (add/rename/delete/reorder), section shown in the Activity timeline; 17 unit tests
- 2026-10-10 — added priorities (High/Medium/Low, colored circles, color key, auto-sort), an Activity tab (daily chart + timeline of every action) and a -TasksFile option for sample data; 12 unit tests
- 2026-10-06 — built the Mac app (checklist, Settings with "Hide done tasks", JSON storage, 6 unit tests) and docs/SYSTEM-DESIGN.md; feedback tab skipped at the owner's request
- 2026-10-06 — created
- 2026-09-15 — added meta-instruction: built-out applications include a small feedback tab
- 2026-09-15 — added meta-instruction: no "Claude" attribution in commits, PRs, or branches
- 2026-09-16 — added meta-instruction: always include a README when adding to GitHub
- 2026-09-16 — changed meta-instruction: ask clarifying questions in the question widget
- 2026-09-17 — added meta-instructions: Claude never a contributor; never commit .claude/
- 2026-09-26 — compressed the meta-instructions and every field prompt; git rules moved to the global instruction file
- 2026-09-27 — added meta-instruction: applications are built as a Mac app first, then a website
- 2026-09-28 — folded inputs, instructions, constraints, deliverables and done criteria into one free-form CONTEXT
- 2026-09-28 — changed meta-instruction: a README on GitHub always includes a visual
- 2026-09-28 — added meta-instruction: name things like a person would, never snake_case
- 2026-09-28 — changed meta-instruction: README leads with visuals; instructions live in a linked guide
- 2026-09-28 — changed meta-instruction: README is visuals and links; details in docs/INSTRUCTIONS.md and docs/FILE-STRUCTURE.md
- 2026-09-29 — changed meta-instruction: GitHub repo names have no "_" or "-"
- 2026-10-02 — added a DELIVERABLES field after CONTEXT
- 2026-10-02 — added meta-instruction: every project has a system design doc at docs/SYSTEM-DESIGN.md
- 2026-10-05 — added meta-instruction: applications include a settings button or tab

Decided without asking (2026-10-21, full keyboard control):
- ⌘1/⌘2/⌘3 set Low/Medium/High priority (matching !, !!, !!!), ⌘0 clears it; tab switching moved to ⌥⌘1/⌥⌘2/⌥⌘3.
- "Return in an empty field" read as Return with no task selected: it jumps to the add field. ↓ in the add field enters the list; ↑ on the first task returns.
- Deleting or hiding the selected tasks selects the next task (or the previous one at the end).
- The shortcut list lives in Settings ▸ Keyboard Shortcuts.
- VoiceOver reads each card as one element with tick, rename, next-step and tag actions.
