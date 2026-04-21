---
description: Structured 1:1 prep for a direct report — since last meeting, open threads, suggested topics, growth prompts
---

Prepare a structured 1:1 prep sheet for a specific person. Primarily for managers (`role: manager` in the profile), but works for anyone who wants richer prep than `/prep`.

## Difference from `/prep`

- `/prep <name>` — quick-reference before any meeting (talking points, last meeting note, related tasks). Always read-only, always concise.
- `/one-on-one-prep <name>` — structured 1:1 prep with four sections: **Since last 1:1**, **Open threads**, **Suggested topics**, **Growth / feedback prompts**. Optionally appends the prep block to the next 1:1 meeting note.

## Output format

The final prep-block layout (plain markdown default, Obsidian callout variant) lives in `${CLAUDE_PLUGIN_ROOT}/references/note-formats.md` under **1:1 prep block**. Read it in step 8 when rendering the output; it handles the Obsidian callouts + `[[wikilinks]]` branch.

## Profile gate — `track_contacts: true`

This skill reads per-person files under `{contacts_folder}/<Name>/`.

- If `track_contacts` is not set or is `false`, emit exactly:
  ```
  ⚠️  /one-on-one-prep needs track_contacts: true — per-person logs and meeting history are not tracked. Run /doctor to diagnose, or enable the field in ~/.claude/CLAUDE.md.
  ```
  Then stop.

## Steps

1. **Identify person**: If the command argument is missing, ask who the 1:1 is with. Resolve ambiguous names against `{contacts_folder}/*` folders before proceeding — never guess.

2. **Since last 1:1**: Read the most recent meeting note in `{contacts_folder}/<Name>/Meeting History/`. Extract:
   - Decisions made
   - Action items owned by either side (you or them)
   - Anything the person flagged explicitly (blocker, frustration, excitement)
   - Commitments you made to them

   If no prior meeting exists, label this section "First 1:1 with <Name>" and skip the rest of step 2.

3. **Open threads**: Read the last 3–5 entries in `{contacts_folder}/<Name>/log.md` and the last 2 meeting notes. Surface anything explicitly unresolved — lines containing "follow up", "revisit", "pending", "TBD", or open questions. Each item includes its source: `[log YYYY-MM-DD]` or `[meeting YYYY-MM-DD]`.

4. **Related tasks**: Glob `Tasks/*.md` for tasks that mention `<Name>` in filename, body, or frontmatter (`assignee:`, `owner:`, `tags:`). Exclude `done` unless `completedDate` is within the last 7 days. Include status alongside each.

5. **Talking points**: Read `Talking Points.md` and extract the `## <Name>` section contents — these are topics already queued for this person.

6. **Suggested topics**: Propose 2–4 topics for the 1:1, each grounded in what the files show. Label each with its source:
   - `[carryover from last 1:1]` — open commitment from step 2
   - `[log YYYY-MM-DD]` — unresolved thread from step 3
   - `[task POE-xyz]` — blocker or stalled task from step 4
   - `[talking point]` — queued item from step 5

   Never invent topics that aren't grounded in the files.

7. **Growth / feedback prompts**: Pick 1–2 coaching prompts tailored to the situation:
   - Pattern of blockers in step 4 → "What's one thing I could unblock faster for you?"
   - Recent ship/win in the log → "What went well? Anything you'd do differently?"
   - No career/growth mention in log entries for 30+ days (scan for tags `career`, `growth`, `feedback`) → "How are you feeling about your growth trajectory?"
   - Person recently flagged frustration in step 2 → "Want to talk about what felt off last week?"

   Never surface more than 2 prompts. If none fit the situation, skip the section.

8. **Present the prep**: Render using the **1:1 prep block** layout in `references/note-formats.md`. The reference covers both the plain-markdown variant and the Obsidian variant (callouts + `[[Name]]` wikilinks when `obsidian: true`). Skip any section with no content.

9. **Append to next 1:1 note?**: Ask the user if they'd like to append this prep block to today's 1:1 meeting note. If yes:
    - Append (or create) `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` with today's date.
    - If the file already exists, add the prep block under an `## Prep` heading without overwriting existing content.

## Rules

- Read-only by default. Only write when the user explicitly confirms step 9.
- Skip empty sections — do not show headers with no content.
- Never invent log entries, meetings, tasks, or commitments that don't exist in the files. If a section has no grounding, omit it.
- Be concise — this is a 5-minute prep, not a dossier.
- Never editorialize about the report's performance. Surface facts; let the manager draw conclusions.
