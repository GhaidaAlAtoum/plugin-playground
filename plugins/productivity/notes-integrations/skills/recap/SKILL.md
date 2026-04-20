---
description: Aggregate daily notes, meetings, and tasks over a time window (last week, last month, last quarter, or custom range)
---

Generate a summary report across a window of time from your local notes and tasks.

## Steps

1. **Resolve date range**: Parse the time window from the command arguments. Supported shorthands:
   - `last week` — the 7 days before today
   - `last month` — the calendar month before this one
   - `last quarter` — the last full calendar quarter (Q1 = Jan–Mar, Q2 = Apr–Jun, Q3 = Jul–Sep, Q4 = Oct–Dec)
   - `this month` — from the 1st of the current month to today
   - `this quarter` — from the start of the current quarter to today
   - `YYYY-MM-DD to YYYY-MM-DD` — explicit range
   If no window is specified, ask the user before continuing.

2. **Daily notes**: Glob `Daily Notes/*.md`. Read all files whose date falls within the range. Extract:
   - Key themes and recurring topics across summaries
   - Days with the most activity
   - Any explicit wins, blockers, or notable callouts mentioned in the notes

3. **Meetings**: Glob `Meetings/*.md` for files in the range. Also, if the "Daily Notes Plugin Profile" in your CLAUDE.md context has `track_contacts: true`, glob `{contacts_folder}/*/Meeting History/*.md` for files in the range. Across all meetings:
   - Count total meetings and unique people/groups met with
   - List recurring themes or decisions
   - Surface any unresolved open items or follow-ups

4. **Tasks**: Glob `Tasks/*.md`. For each file, read the `status` and `completedDate` (or `due`) frontmatter fields:
   - **Completed in range**: status is `done` and `completedDate` falls within the window
   - **Created in range**: file creation date falls within the window (use file modification time as proxy if no frontmatter date)
   - **Still open**: status is `open`, `in-progress`, `in-review`, or `blocked` regardless of when created
   Report counts for each bucket and list the completed ones by name.

5. **Jira (optional)**: If the Atlassian MCP is available, offer to fetch Jira issues resolved during the window (assigned to you, resolved within the date range). Prepend the offer before generating the report:
   > "Atlassian MCP is available. Include Jira tickets resolved in this period? [y/n]"
   If yes, fetch and add a **Jira Closed** section. If the MCP is unavailable, skip silently.

6. **Present recap report**:
   ```
   ## Recap: <Window Label> (<start date> – <end date>)

   ### Highlights
   - <2-4 key themes or wins distilled from daily notes>

   ### Meetings
   - Total: X meetings with Y unique people
   - Recurring themes: ...
   - Unresolved follow-ups: ...

   ### Tasks
   - Completed: X  |  Opened: Y  |  Still open: Z  |  Blocked: N
   **Completed:**
   - Task name (done YYYY-MM-DD)

   ### Jira Closed  ← only if MCP was used
   - [KEY-123] Ticket title (resolved YYYY-MM-DD)

   ### Blockers / Carryover
   - <anything that was unresolved or carried into the next period>
   ```

## Rules

- Read-only — do not modify any files.
- Skip sections that have no content — don't show empty headers.
- If the date range covers a period with no daily notes, say so clearly rather than showing an empty report.
- Be concise — this is a summary, not a transcript. Aim for signal over volume.
- If a task file has no `completedDate` frontmatter, use the last-modified date as a proxy only if the status is `done`.
