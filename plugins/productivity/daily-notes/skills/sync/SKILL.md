---
description: Process loose notes from Scratch Pad — route to tasks, talking points, meeting summaries, and daily note
---

Process my loose notes and file everything into the right places.

## Preview mode (`/sync --preview` or `/sync --dry-run`)

If the user invoked this skill with `--preview` or `--dry-run` in the arguments, run a **read-only plan** instead of executing:

1. Run steps 1–2 below to parse `Scratch Pad.md` and review `Meetings/` — read-only, never write.
2. Run step 3 classification (talking points vs. tasks) in memory only — do not append to `Talking Points.md`.
3. For each would-be write, emit a single numbered line in this form:
   - `1. CREATE Tasks/<name>.md — <short summary>`
   - `2. UPDATE Tasks/<key>.md — change status open → in-progress`
   - `3. APPEND Talking Points.md → ## Sarah — "Ask about the Q2 plan"`
   - `4. CREATE Meetings/2026-04-20 Meeting.md — summary of today's sync`
   - `5. CREATE Daily Notes/2026-04-20.md — 4 items processed`
   - `6. CLEAR Scratch Pad.md — replace with blank line`
4. Group the plan under headings: **Would create**, **Would update**, **Would append**, **Would clear**. If a category is empty, omit the heading.
5. Count total operations and print a one-line summary, e.g. `Plan: 3 creates, 1 append, 1 clear. No files written. Run /sync to apply.`
6. **Do not write any files. Do not clear the Scratch Pad. Do not ask for confirmation** — preview mode always exits after printing the plan.

Normal `/sync` (no `--preview` flag) follows the steps below and writes as usual.

## Note formats

Canonical meeting-note, daily-note, task-file, and contact-log formats live in `${CLAUDE_PLUGIN_ROOT}/references/note-formats.md`. Read that file once at the start of a real run and branch between the plain-markdown and Obsidian variants based on the `obsidian` profile flag. Never emit both variants.

## Steps

1. **Scratch Pad**: Read `Scratch Pad.md` in the project root. Parse every note, idea, to-do, and reference. Categorize each item as: action item, meeting note, reference/info, or idea. If the scratch pad is empty, say so and move on.

2. **Meeting transcripts**: Check the `Meetings/` folder for any files modified today (or since last sync). For each new/updated file:
   - Write a 3-5 bullet summary
   - Extract action items with owners if mentioned
   - Note any decisions made
   - **Profile check (routing):** If `track_contacts: true` is set and the meeting matches `recurring_meetings_label` (default `1:1`), file it under `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` (default `contacts_folder`: `People`). Otherwise, keep it in `Meetings/`.
   - Write the file using the meeting-note format from `references/note-formats.md` — plain markdown by default, Obsidian callouts + wikilinks if `obsidian: true`.

3. **Route Talking Points**: Before creating tasks, identify items that are talking points — conversation topics for a specific person, not standalone actions. Cues: "ask X about", "discuss with X", "mention to X", "talk to X about", "follow up with X on". For each:
   - Present for approval: show the topic, the person, and ask for confirmation
   - If the person is ambiguous, ask for clarification before filing
   - On approval, add to `Talking Points.md` under the person's `## Name` header with `(added YYYY-MM-DD)`
   - Create the file with `# Talking Points` header if it doesn't exist

4. **Create Task Files**: For each new action item from steps 1-2 (excluding talking points), propose tasks one at a time using the `/task create` skill. Do not duplicate — glob `Tasks/*.md` to check first.

5. **Daily Note**: Create or update today's `Daily Notes/YYYY-MM-DD.md` using the daily-note format in `references/note-formats.md` (plain markdown default, Obsidian variant if `obsidian: true`). If the file already exists, merge new content into existing sections — do not overwrite.

6. **Contact logs**: **Profile check:** If `track_contacts: true` is set, for any feedback or notable event about a person mentioned in notes, append a dated entry to `{contacts_folder}/<Name>/log.md` using the contact-log format in `references/note-formats.md`. Create the file if missing. If `track_contacts` is unset or `false`, skip this step entirely.

7. **Clear Scratch Pad**: After everything is filed, confirm what was processed, then replace `Scratch Pad.md` with a single blank line. Never clear silently.

## Rules

- Always confirm before clearing the Scratch Pad — show what you're about to file and where.
- If a note is ambiguous, ask rather than guessing.
- Create `Meetings/` and `Daily Notes/` directories if they don't exist. Only create `{contacts_folder}/` if `track_contacts: true`.
- Be concise in summaries. No fluff.
