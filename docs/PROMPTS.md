# Super Simple Todo — Prompt Log

The prompts given in each session, word for word and in order, each with a line on what it led to. Started on 2026-11-14. Earlier sessions weren't logged; their decisions are recorded in [super_simple_todo.md](../super_simple_todo.md).

## 2026-11-14 — Archive old tasks and bring them back

1. > super_simple_todo: update this existing project. It's already built, so change what's here rather than starting it again.
   >
   > What I want changed, in my words:
   > create the ability to archive old tasks and pull them back when relevasnt
   >
   > How to go about it:
   > - Read super_simple_todo.md and follow its META-INSTRUCTIONS, then the README and docs, and work the way the project already does.
   > - Edit what's here in place. Before rewriting a file wholesale or deleting anything, show me what would change and wait for my yes.
   > - Keep the README and docs in step with what changes, and add a CHANGELOG line if the project keeps one.

   Led to two rounds of design questions, then the archive: right-click ▸ Archive (⌃⌘A), Archive Done replacing Clear Done, a bar offering tasks untouched for 30+ days, a searchable "Archived N" screen in the Tasks tab, and archived tasks offered under the add field while typing. 12 new tests (85 in all) and a run on sample data.

2. Answers in the question widget (round 1): "Open tasks not for now" and "Tasks that went stale"; come back "By hand, from a searchable archive" and "Offer it while I type"; "Toggle on the Tasks tab"; Clear Done should "Archive instead".

   Set what goes in the archive, how tasks come back, where it lives, and that Clear Done archives.

3. Answers in the question widget (round 2): "A quiet nudge I accept"; "No edits for 30 days"; "Mixed, open ones first".

   Set the untouched-task bar, the 30-day definition with a saved last-edit date, and the archive's order.
