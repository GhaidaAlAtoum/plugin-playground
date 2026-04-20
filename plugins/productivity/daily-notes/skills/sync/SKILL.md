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

## Steps

1. **Scratch Pad**: Read `Scratch Pad.md` in the project root. Parse every note, idea, to-do, and reference. Categorize each item as: action item, meeting note, reference/info, or idea. If the scratch pad is empty, say so and move on.

2. **Meeting transcripts**: Check the `Meetings/` folder for any files modified today (or since last sync). For each new/updated file:
   - Write a 3-5 bullet summary
   - Extract action items with owners if mentioned
   - Note any decisions made
   - **Profile check:** Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context. If `track_contacts: true` is set and the meeting matches the `recurring_meetings_label` (default: `1:1`), file it under `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` (default `contacts_folder`: `People`) instead of `Meetings/`. Otherwise, keep it in `Meetings/`.
   - **Obsidian profile check:** If `obsidian: true` is set, write the meeting note using Obsidian-native format — callout sections and wikilinks for people:
     ```markdown
     ---
     created: YYYY-MM-DD
     type: meeting
     people: ["[[Name]]"]
     tags: [meeting]
     ---
     # Meeting — YYYY-MM-DD
     > [!abstract] Summary
     > - bullet points
     > [!warning] Action Items
     > - [[Owner]] — task description
     > [!note] Decisions
     > - Decision made
     > [!question] Open Questions
     > - Anything unresolved
     ```
     Use `[[Name]]` wikilinks for all people references so Obsidian builds graph edges. If `obsidian` is false or not set, use plain markdown sections instead.

3. **Route Talking Points**: Before creating tasks, identify items that are talking points — conversation topics for a specific person, not standalone actions. Cues: "ask X about", "discuss with X", "mention to X", "talk to X about", "follow up with X on". For each:
   - Present for approval: show the topic, the person, and ask for confirmation
   - If the person is ambiguous, ask for clarification before filing
   - On approval, add to `Talking Points.md` under the person's `## Name` header with `(added YYYY-MM-DD)`
   - Create the file with `# Talking Points` header if it doesn't exist

4. **Create Task Files**: For each new action item from steps 1-2 (excluding talking points), propose tasks one at a time using the `/task create` skill. Do not duplicate — glob `Tasks/*.md` to check first.

5. **Daily Note**: Create or update today's note at `Daily Notes/YYYY-MM-DD.md`.

   **Plain markdown** (default):
   ```
   # YYYY-MM-DD
   ## Summary
   (brief narrative of what happened today — 2-3 sentences max)
   ## Notes Processed
   (items pulled from Scratch Pad)
   ## Meetings
   (summaries from step 2, or skip if none)
   ## New Tasks Added
   (list of tasks created)
   ```

   **Obsidian profile check:** If `obsidian: true` is set, use this format instead:
   ```markdown
   ---
   created: YYYY-MM-DD
   type: daily-note
   tags: [daily]
   ---
   # YYYY-MM-DD
   > [!abstract] Summary
   > Brief narrative — 2-3 sentences max
   > [!note] Notes Processed
   > Items pulled from Scratch Pad
   > [!check] New Tasks Added
   > - Task name
   ```

   If the daily note already exists, merge new content into existing sections — do not overwrite.

6. **Contact logs**: **Profile check:** Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context. If `track_contacts: true` is set, for any feedback or notable event about a person mentioned in notes, add a dated entry to `{contacts_folder}/<Name>/log.md` (default `contacts_folder`: `People`; create the file if it doesn't exist):
   ```
   ## <Quick title summarizing the event or feedback>
   - Date: YYYY-MM-DD
   - Source: <meeting or context if available>
   <Brief summary. Include business impact if relevant.>
   ```
   If `track_contacts` is not set or is `false`, skip this step entirely.

7. **Clear Scratch Pad**: After everything is filed, confirm what was processed, then replace `Scratch Pad.md` with a single blank line. Never clear silently.

## Rules

- Always confirm before clearing the Scratch Pad — show what you're about to file and where.
- If a note is ambiguous, ask rather than guessing.
- Create `Meetings/` and `Daily Notes/` directories if they don't exist. Only create `{contacts_folder}/` if `track_contacts: true`.
- Be concise in summaries. No fluff.
