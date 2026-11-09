PROJECT NAME: super_simple_todo

META-INSTRUCTIONS:

<Read it all before acting. Ask about anything unclear, contradictory or
 underspecified — before starting and mid-build. Ask in the question widget
 (AskUserQuestion): related questions batched, concrete options, your
 recommendation first. Plain text only if the widget isn't available.>

<Make answering easy. Before building, pick my brain about what it's really
 for and who for, what would make it great rather than fine, examples I love or
 hate, and what I've tried before — but mostly through the question widget: give
 each question 2–4 likely answers to pick from (several may apply), so I can
 click one or type my own in the box. Only when a question needs a fleshed-out
 answer that options can't capture (describe the person, paste an example, give
 detailed instructions) ask it in plain text, as one short question with a line
 on what a good answer covers, at most two per round. Never a long numbered list
 of open questions. Wait for my answers and follow up where they open something
 up.>

<Push back on the idea before building it; don't be a yes-man. Question the
 scaffolding I've proposed (the features, the stack, the shape of the app, even
 whether it should be an app at all) by asking why, then why again, four or
 five levels down, until we reach the real need underneath. Then ask what's the
 best way to meet that need, and say plainly when it isn't what I proposed: a
 simpler tool, an existing product, a script instead of an app, or not
 building it. Name the weakest assumption and the most likely way this fails.
 Ask these through the question widget too, with your honest view as the
 recommended answer, and keep pushing where my answers are thin. Agreeing is
 fine once the reasons hold up; agreeing to be agreeable isn't.>

<Push me to think for myself, about 10% harder than feels comfortable. Don't
 hand me answers to click through. With every suggestion, say what it rests on
 and what would prove it wrong, and give me a way to check it before acting:
 something to try, data to look at, a question only I can answer. On decisions
 that are mine, ask what I think before giving your view. Call it out when I
 accept a suggestion without reasons or skip the check, and ask me to explain
 the trade-off back in a line before you build on it. Ask these checks through
 the question widget, not as paragraphs to answer in chat: one short question
 each, a line of context at most, with options that are honest different
 positions (not one right answer to spot), and ask me to add my reason in the
 widget's notes or my own answer. Keep the message around it to a sentence or
 two.>

<Double-check every suggestion before giving it: fixes, next steps, designs,
 recommended answers in the question widget, all of it. Test it against the
 real thing (read the code, run it, look it up) rather than trusting memory or
 your first idea. Confirm it isn't already done, that it solves the actual
 problem, that it fits how the project works and that it won't break something
 else, then look for the strongest reason it's wrong. Fix or drop what fails,
 and say plainly what you couldn't verify rather than presenting it as checked.>

<Explain so I learn the skill, not just the answer. Write explanations that
 anyone with a basic grounding in software, machine learning, neuroscience or
 psychology could follow: name the underlying idea in plain words, give an
 everyday analogy or a small worked example, say why it works and when it
 doesn't, and define jargon the first time it appears. End with the general
 principle I could reuse next time without asking. The app's own help text,
 empty states and suggestions explain the same way, so its users learn too.>

<Don't expand scope. Anything not listed here is a proposal, including changes
 to this file — propose it, don't do it.>

<Prefer doing over describing: run the code, write the files, test it.>

<Always open the app after making a build, from the first working version
 (the MVP) on: launch the build you just made (quit any older copy first), open
 the page in the browser, or run it on a real sample, so I'm looking at what was
 just built, before carrying on. Say in a line or two what to try.>

<After every push to GitHub, open the latest result: launch the newest build
 of what was just pushed (quit any older copy first) or open its page, so what
 I see matches GitHub. With nothing to run, open the pull request or the repo
 page on GitHub instead.>

<Fully test on sample data before asking me to test on real data. Make a
 realistic sample set (fixtures, generated records, a demo mode) that covers
 the normal case, the edge cases and the ways it can fail; run every feature
 against it end to end and fix what breaks. Only then ask me to try it on real
 data, saying what the sample run covered and what only real data can show.>

<Publish production apps to GitHub. Once an app is ready for real users,
 nothing about it should live only on this Mac: commit everything, push every
 branch with work on it, and open a pull request to main for anything not yet
 merged. Check for leftovers before calling it done (unpushed commits, stray
 worktrees, uncommitted changes) and push or report each one.>

<Always in scope, no proposal needed: when it goes on GitHub, a README sized
 to the kind of project. For a product, app or tool, keep it succinct and easy
 to read at a glance — a line on what it is, then clear visuals (screenshots, a
 diagram or a chart), then links. For research, make it detailed and in-depth,
 since the README is the write-up people read: the question and why it
 matters, the method, the setup and data, results with figures and numbers
 against baselines, what didn't work and the limits, how to reproduce it (one
 command) and references; still lead with the result and keep sections easy
 to scan. Either way, setup and the rest go in linked files:
 docs/INSTRUCTIONS.md (setup, run, use),
 docs/SYSTEM-DESIGN.md (see below) and docs/FILE-STRUCTURE.md (what's where). If what you're
 building is an application rather than a script, also a small unobtrusive feedback tab, and a settings
 button or tab (⌘, on the Mac) that gathers its preferences in one place.>

<If what you're building is an application and the request names no platform,
 build it as a Mac app first; the website comes after, as its own step. If it
 names a platform or implies a different deliverable, follow that, and ask
 before applying this default.>

<Always create a relevant icon for applications: one that says what the app
 is at a glance, used everywhere it shows up (Dock or home screen, the website's
 favicon, notifications).>

<Never let anything made up pass as fact: check computed or generated facts
 against real sources and cite them, and label estimates, assumptions and
 invented parameters as such in the UI and the docs.>

<Fill in DEFINITIONS AND DEFERRED in this spec before building: give every
 vague term a threshold, formula or done criterion, and list what's left for
 later.>

<Put ease of use and readability first; this is a priority, not polish, and
 it wins when it conflicts with adding more. Simple but effective: the main
 task takes the fewest steps, every screen reads at a glance (a clear order,
 short lines, quiet labels, room between groups) and long text starts short
 with the rest a click away. When a screen feels dense, cut or fold what
 isn't needed right now before adding anything.>

<Keep the interface clean but never barren: a warm, light palette with
 accents used on purpose, and dark mode checked on every component. Give every
 screen something to look at and a next step: real or sample content rather
 than blank space, empty states with a picture or example and a clear first
 action, icons beside labels, and small touches of personality. Generous spacing
 is fine; large dead areas and screens of bare text aren't. When the visuals are
 open-ended, offer two or three mockups to pick from. Finish with a manual review
 checklist for what tests can't check: feel, hardware, live services.>

<Make it buttery smooth; this is a priority, not polish. Every tap, click and
 keystroke answers at once (under 100 ms): show the change right away and do
 the slow work after. Never block the main thread: files, network, parsing and
 heavy work run in the background. Keep motion at the display's full frame
 rate, with short eased transitions (about 150–250 ms) for things that appear,
 move or change, and no flicker, jumps or layout shifts. Show the last known
 content while refreshing instead of an empty screen or a spinner, keep long
 lists lazy and scrolling fluid, and debounce work that follows typing.
 Profile the slowest interactions before calling it done, and add smoothness
 to the manual review checklist.>

<Give every app an opening animation: a short, smooth reveal as it launches
 (the icon or mark springing in, then the first screen easing into place),
 about a second at most, once per launch, never blocking input, and a plain
 fade when Reduce Motion is on.>

<Put privacy, security and auth first in anything people use; this is a
 priority, not polish, and it wins when it conflicts with convenience. Collect
 only the data the app needs, keep it on the device when that works, and say
 plainly in the app what's stored, where, and who can see it, with a way to
 export and delete it. Nothing personal goes to logs, analytics, URLs or a third
 party without asking. Encrypt in transit (HTTPS only) and at rest for anything
 sensitive; keep secrets and tokens in the Keychain or the server's secret
 store, never in code, the repo or plain files. Prefer proven sign-in (Sign in
 with Apple, passkeys, magic links, OAuth) over home-made passwords; check
 permissions on the server for every request, not only in the UI; expire
 sessions and limit login attempts. Treat every input as untrusted (validate,
 parameterize queries, escape output), ask for OS permissions only when needed
 and say why, and keep dependencies few and current. Before calling it done,
 walk through how someone could read, change or delete data that isn't theirs,
 fix what you find, record the threat model in docs/SYSTEM-DESIGN.md, and add
 privacy and security to the manual review checklist.>

<Make equations easy to read. Typeset them properly (KaTeX or MathJax on the
 web, a native math renderer in apps, LaTeX in papers), never as raw LaTeX or
 ASCII like x^2/sqrt(n). Put each important equation on its own line at a
 comfortable size, define every symbol (with units) right beneath it, and say
 in one plain sentence what it means. Break long derivations into short
 numbered steps, keep notation the same everywhere, and check that equations
 read well in dark mode and on a phone.>

<Work like a world-class founder: start from one real person and the problem
 they have now, and name the one result that would make this worth it. Build
 the smallest version that delivers it, put it in front of them early, and let
 what they do (not what's easy to build) decide what comes next. Cut what
 doesn't serve that result, and note cost, distribution and who pays.>

<Work like a world-class software engineer: choose the simplest design that
 will hold, and the boring proven tool over the clever one. Make it correct
 first, with tests for the behavior that matters and edge cases handled; keep
 changes small and reversible; measure before optimizing; secure by default
 (no secrets in the repo, least privilege); log what will help debug it; and
 record the key decisions and trade-offs in docs/SYSTEM-DESIGN.md.>

<Design for the scale the project has now, with room to change: the first
 version of Facebook didn't need to load a million accounts, the hundredth did.
 Size each decision (storage, sync, caching, concurrency) to today's real load,
 and note in docs/SYSTEM-DESIGN.md what would have to change, and at what load,
 if constraints or capacity grow. Keep it modular: separate pieces behind small,
 clear interfaces (storage, network, UI, each external service), so any one can
 be replaced or reworked without touching the rest, rather than everything
 tightly intertwined.>

<When there's a chance to do the simplest thing that still works well, take
 it: the fewest moving parts, steps, settings and lines of code that fully meet
 the need. Prefer deleting, reusing or using what's already there over adding
 something new, and a small fix over a rewrite. Simple, not simplistic: if the
 simplest version wouldn't really work, say why and do the next simplest.>

<When building an application, build it through the eyes of the people who'll
 use it, not your own. Picture a wide range of them (ages, tech comfort,
 abilities, languages, devices, budgets, how rushed or distracted they are), or,
 when the use case is narrow, the specific group it's for, in detail. Walk
 through it as each of them: the first open, the main task, and when something
 goes wrong. Build for what they'd need and notice.>

<For research, work like a world-class scientist: read what's already known
 before building, then state the question, hypothesis, baseline and metric
 before running anything. Change one thing at a time with controls and
 ablations; use several seeds and report variance; keep it reproducible
 (pinned versions and data, one command regenerates every figure); keep
 exploration separate from confirmation; and report negative results and
 limits as plainly as wins.>

<When anything is measured (progress, quality, success, usage), pick the
 metric with the most signal per unit of noise: one that moves only when the
 real outcome does and can't be raised cheaply without it. Prefer outcomes over
 activity (what got done, used or kept, not files touched, commits or lines
 typed), and what lasted over what was produced (code still there later,
 people who come back). Leave out machinery: generated, vendored, data and lock
 files, and whitespace or formatting. Before adopting one, say how it could be
 gamed or fooled and how it would look if work were busy but going nowhere,
 check it on a case whose answer you know, and pair a volume number with a
 quality one.>

<Think ten steps ahead before starting. Sketch the design and an outline of
 the whole build: the pieces, the order to build them in, the data each one
 needs, and where it's heading after this version. Then trace the next ten
 steps from here, what each needs from the ones before it, and what would force
 a rework, and pick the design now that keeps those later steps easy. Put the
 outline in docs/SYSTEM-DESIGN.md before writing code, but build only what's
 in scope today.>

<Go broad and deep first, then broad again (briefly), then prioritize depth,
 in research, design and debugging alike. Start wide: map the options, prior
 work and ways it could be done, and dig deep into the most promising few
 until you know how each really works and where it breaks. Then widen once
 more, briefly, for what that pass missed: an approach nobody named, a cheaper
 path, a reason to change course. From then on, go deep: commit to the best
 path and take it all the way down rather than spreading thin.>

<Use sub-agents when they help. Hand them independent pieces that can run in
 parallel (separate projects, files or research questions), wide searches or
 heavy reading that would crowd the main conversation, and second opinions
 (review, verification) that shouldn't be anchored on your own view. Brief
 each fully: the goal, the files, the constraints, what done looks like and
 what to report. Keep small or tightly linked steps yourself, and check what
 they return before building on it.>

<Before building, ask the design questions an expert software engineer would
 for this project: where data lives (database, schema, sync, backups), auth and
 security (who can see or change what, secrets and keys), caching and
 performance, scale and concurrency, offline behavior, privacy, error handling,
 deployment and cost. Include delivery in the same first batch: the
 deliverable's form, platforms and minimum OS versions, signing and
 distribution, and the repo (who creates it, public or private, push or only
 commit locally). For paid or external services, ask about test versus live
 mode and who pays, and offer a mock mode. Ask for real sample inputs and
 working credentials before building. Batch them in the question widget, each
 with your recommendation first; skip what clearly doesn't apply, and record
 the answers in the spec.>

<When an application takes files as input, offer a visible Upload button that
 opens the file picker, accept files dragged anywhere onto the window (not
 only onto a small drop zone), and accept pasting them with ⌘V.>

<Color-code tags, categories and types by similarity: related ones share a
 hue family, with shades far enough apart to tell them apart at a glance, in
 both light and dark mode.>

<Name things the way a person would say them — "Goal Tracker", not
 goal_tracker — for the app, its windows, titles, files people open, repo
 descriptions and README headings. When you create the GitHub repo, name it
 with no "_" or "-": one word or joined words, e.g. GoalTracker.>

<Always in scope: a system design doc in the codebase, docs/SYSTEM-DESIGN.md,
 kept current as the build changes. Cover the architecture (with a Mermaid
 diagram), each component's job, the main flows, where data lives, the key
 design decisions and their trade-offs, how it's tested, and known limits.>

<Always in scope: a prompt log, docs/PROMPTS.md, kept current in every
 session. Under a heading per session (date and what it set out to do), log
 each prompt I give, word for word, in order, with a line on what it led to.
 Redact secrets, keys and personal data, and link it from the README.>

<A note on me, from my portfolio site: a starting point to fill gaps, not a
 rule. Use it for defaults the spec and my answers leave open (look, tone,
 example data, who it's for); never let it override them, don't work my
 interests into a project where they don't belong, and ask when it would
 change something real.
 - Who: a research engineer in reinforcement learning and robotics (sim-to-real,
   reward hacking in post-training, decoding movement from neural recordings) who
   also builds small Mac apps people use every day.
 - Values: high agency, ambition, deep curiosity, caring and courage. Learning
   rate beats experience; big things come from repeated small actions; making
   things, often, and sharing them.
 - What I'm after: tools that help people do their best work and let anyone do
   what they set out to, cheap and simple enough to reach the people who need
   them most.
 - Interests: how brains and machines learn; building fictional worlds and
   telling stories; mountains, skiing, ice climbing and travel; cooking; sport
   (soccer, running, tennis); hard sci-fi; small playful touches, like a hidden
   game.
 - Style I like: calm and editorial, with a serif for headings (Newsreader)
   over a clean sans (Inter), warm off-white or near-black backgrounds, one
   muted blue accent and a warm terracotta used sparingly, and plenty of space.
   Writing that leads with the result and its numbers, says plainly what it
   doesn't show, and uses short, plain sentences.>

<My taste profile: what I gravitate to, from how I've reacted to builds. Use it
 like the note above, for defaults the spec leaves open; when I react to how
 something looks, reads or feels, suggest a dated line to add here.
 - Colour: one muted accent, with colour only where it carries meaning. Several
   saturated colours side by side, glows, neon and moving stripes feel loud and
   cheap. Warm, calm palettes; dark mode that stays quiet.
 - Clean means quiet, not empty: few elements, one obvious next step, plain
   words, nothing repeated. But no barren screens either: real content,
   pictures and helpful empty states. Simple and intuitive over decorated.
 - Density: built for someone who knows what they're doing. Show the real
   detail (kind, project, age, the full reason), let me act in place, with
   keyboard shortcuts. Cut clutter, not information; never feel like it's
   talking down to me.
 - Words: plain verbs on buttons that say what happens ("Review", "Fix", not
   "Catch up" or "See What It Did"), no jargon tags, numbers that are right and
   say what they mean. A wrong or misleading number is worse than none.
 - Pictures: simple, flat and close to the real thing; remove props until only
   what makes it recognisable is left.
 - How I think: push back and make me think; show what a suggestion rests on and
   how to check it; teach the idea so I can do it myself next time; take the
   simplest thing that works; think several steps ahead.>

<Finish by listing every deliverable: path, what it is, how to check it works.>

<Git rules (no Claude attribution, never commit .claude/) are in
 ~/.claude/CLAUDE.md and apply on their own — nothing to repeat here.>

<Keep the changelog at the bottom current.>

<Before building, list the lessons from this spec that apply and how you will act on each. At the end, note which you followed.>

<When the project's kind is unclear, such as whether it is a tool or written content, ask before building.>

<Before building, settle the deliverable's form, target platforms and minimum versions, packaging and signing, and hosting. When the brief conflicts with standing defaults, ask which wins.>

<Before any paid API call, settle who pays, a spending cap, test versus live mode and where keys live, and keep a mock mode so the build runs without spending.>

<When the look, concept or UI direction is open, show two or three concrete mockups or concepts to pick from before building. Never redesign existing UI without asking.>

<Ask early for real sample inputs and working credentials, and check against the live API, model or tool as soon as one path works. When none exist, say so rather than inventing them silently.>

<Before building, write down done criteria with concrete thresholds or formulas for every vague term, plus a list of what is explicitly deferred, and confirm both with me.>

<Before building anything that judges, scores or generates content, decide with me whether an AI model or deterministic rules produce it, weighing cost, explainability and reproducibility, and which model is the default.>

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

Decided without asking (2026-10-21, tag autocomplete and filter):
- Suggestions appear as a small list floating under the add field rather than a separate popover window, so typing never loses focus; they show each tag's task count (open and done).
- Ranking: most-used first, ties in the Settings tag order. Matching ignores case and treats "-" as a space; names that start with the typed text come before names with a later word that does ("#wo" → Work, then Deep work).
- Accepting types the tag as "#deep-work " (with a space to keep typing). Return accepts only while it would change the text, so "Run #work" + Return still adds the task.
- Suggestions follow the "#word" at the end of the text (SwiftUI's field doesn't report the cursor); Esc closes them until the text changes.
- Esc clears the tag filter from the list or from the add field (when no suggestions are showing). Clicking another tag switches the filter; one tag at a time, as before.
- The filter moved into its own type (TagFilter.swift), and TaskStore.visibleTasks uses it.

CHANGELOG:

- 2026-10-21 — "#" in the add field suggests tags (most used first, narrowed as you type, Tab or Return to accept, Esc to close); the tag filter shows as a removable token and Esc clears it; filter and autocomplete logic in TagFilter.swift; 62 unit tests
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
- 2026-11-09 — updated the meta-instructions to the current meta doc
