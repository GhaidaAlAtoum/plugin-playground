---
description: Team-level recap for managers — per-report activity, blockers, 1:1 cadence health, and attention flags across a time window
---

Aggregate per-direct-report activity across a time window. For managers with `role: manager` and `track_contacts: true` in their profile.

## Profile gates

Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context.

- If `track_contacts` is not set or is `false`, emit exactly:
  ```
  ⚠️  /team-recap needs track_contacts: true — per-person logs are not tracked. Run /doctor to diagnose, or enable the field in ~/.claude/CLAUDE.md.
  ```
  Then stop.

- After step 2, if no contact in `{contacts_folder}/*/log.md` has `report: true` in YAML frontmatter, emit:
  ```
  ⚠️  /team-recap needs at least one contact with `report: true` in their log.md frontmatter. Add the field to each direct report's log.md — see daily-notes/CLAUDE.md for the schema. Run /doctor to diagnose.
  ```
  Then stop.

## Steps

1. **Resolve date range**: Parse the time window from the command arguments. Supported shorthands (same as `/recap`):
   - `last week` — the 7 days before today
   - `last month` — the calendar month before this one
   - `last quarter` — the last full calendar quarter
   - `this week`, `this month`, `this quarter` — from the start of the current period to today
   - `YYYY-MM-DD to YYYY-MM-DD` — explicit range

   If no window is specified, default to `last week` and say so in the report header.

2. **Identify direct reports**: Glob `{contacts_folder}/*/log.md`. For each, parse YAML frontmatter. Include only contacts where frontmatter has `report: true`. If none match, emit the second gate message above and stop.

3. **Per-report summary**: For each direct report in scope, compile:

   - **Activity** — log entries in `{contacts_folder}/<Name>/log.md` dated within the range. Summarize as 2-3 bullets. Entries tagged `win`, `shipped`, or matching keywords ("shipped", "landed", "completed") are noted separately for the Recognition section.
   - **Meeting mentions** — references to `<Name>` in `Meetings/*.md` files dated in the range (non-1:1 meetings: team syncs, demos, retros). List dates and a short context.
   - **1:1 cadence** — count meeting notes in `{contacts_folder}/<Name>/Meeting History/` dated within the range. Record the date of their most recent 1:1 (may be outside the range).
   - **Blockers** — glob `Tasks/*.md` for tasks mentioning `<Name>` in filename/body/frontmatter with `status: blocked`. Include the blocker reason if stated in the task body.

4. **Aggregate attention flags**: After the per-report pass, compute cross-team flags:
   - **Stale 1:1** — any report whose most recent 1:1 is more than 14 days before today (and the range is long enough to measure).
   - **Unsurfaced blockers** — any report with `status: blocked` tasks that aren't mentioned in their most recent 1:1 note.
   - **Quiet** — any report with zero activity, zero meeting mentions, and zero task updates in the range.

5. **Present the recap** (plain markdown):
   ```
   ## Team Recap — <Window Label> (<start> – <end>)

   N direct reports — N_active active, N_quiet quiet, N_flagged flagged

   ### Attention flags
   - No 1:1 with Sarah in 18 days — schedule one
   - Dave has 2 blocked tasks not mentioned in his last 1:1 (2026-04-10)

   ### Per-report

   **Sarah Chen** — last 1:1 2026-04-10 (10 days ago)
   - Shipped auth migration (POE-1234) per log 2026-04-12
   - Mentioned in 2 team meetings (Q2 planning, retro)
   - No current blockers

   **Dave Kim** — last 1:1 2026-04-15 (5 days ago)
   - Working on rate-limiter (POE-1289) — blocked on infra approval
   - No log updates this week

   ### Recognition-worthy
   - Sarah: shipped auth migration (POE-1234, 2026-04-12)
   ```

6. **Obsidian profile check**: If `obsidian: true` is set, wrap names in `[[<Name>]]` wikilinks and render attention flags in a `> [!warning]` callout.

## Rules

- Read-only — do not modify any files.
- Skip empty sections — do not show headers with no content.
- Never invent log entries, meetings, or tasks that don't exist in the files. If a report has no activity in the window, say so plainly.
- Be concise — signal over volume. Aggregate patterns across reports when they repeat.
- Flag missing 1:1s factually. Never editorialize on whether the manager is doing their job well.
