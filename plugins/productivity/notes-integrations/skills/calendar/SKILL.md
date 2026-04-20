---
description: Show today's and upcoming Google Calendar meetings — flag which have no notes yet, offer to create a blank meeting note
---

Pull today's Google Calendar agenda and cross-reference with local meeting notes.

## Prerequisites

Requires a Google Calendar MCP configured in your Claude Code session.

> **Compatibility:** This skill calls `list_events` with `timeMin`, `timeMax`, and `maxResults` parameters. It works with any Google Calendar MCP that exposes a `list_events` tool with this signature. If your MCP uses a different tool name, this skill will fail with a clear "Google Calendar unavailable" message; the rest of the plugin is unaffected.

Also requires `gcal: true` in your Daily Notes Plugin Profile in `~/.claude/CLAUDE.md`.

If the MCP is unavailable, skip the calendar section and note: "Google Calendar unavailable — check MCP config."

## Steps

1. **Profile check**: Confirm `gcal: true` is set. If not set, say "Add `gcal: true` to your Daily Notes Plugin Profile to enable Google Calendar." and stop.

2. **Fetch today's events**: Call `list_events` with:
   - `timeMin`: today at 00:00 local time (ISO 8601 with offset)
   - `timeMax`: today at 23:59 local time
   - `maxResults`: 20

3. **Fetch upcoming events**: Call `list_events` with:
   - `timeMin`: tomorrow at 00:00 local time
   - `timeMax`: 7 days from now at 23:59

4. **Cross-reference with local notes**: Glob `Meetings/*.md`. For each today event, check if a file exists whose name contains the meeting title or date. Mark events that have no corresponding note as **no notes yet**.

5. **Present the agenda**:

   **Plain markdown** (default):
   ```
   ## Calendar — YYYY-MM-DD

   ### Today
   - HH:MM–HH:MM  Meeting title [attendees count] ⚠️ no notes
   - HH:MM–HH:MM  Meeting title ✓ notes exist

   ### Upcoming (next 7 days)
   - Mon Apr 07  HH:MM  Meeting title
   ```

   **Obsidian profile check:** If `obsidian: true` is set, use callouts:
   ```
   > [!note] Calendar — YYYY-MM-DD
   > **Today**
   > - HH:MM–HH:MM [[Meeting title]] ⚠️ no notes
   >
   > **Upcoming**
   > - Mon Apr 07 HH:MM [[Meeting title]]
   ```

   Omit the Upcoming section if empty.

6. **Offer to create blank meeting notes**: For each today event flagged "no notes yet", ask:
   > "Want me to create a blank meeting note for '[Meeting title]'?"

   If confirmed, create `Meetings/YYYY-MM-DD [Meeting title].md` with:
   ```markdown
   # YYYY-MM-DD [Meeting title]

   **Attendees:** [list from calendar]
   **Time:** HH:MM–HH:MM

   ## Notes

   ## Action Items

   ## Decisions
   ```
   Confirm the filename before writing. Never overwrite an existing file.

## Rules

- Read-only until the user requests a meeting note in step 6.
- Confirm all writes before executing.
- If `list_events` errors, show the error message and stop — do not guess at calendar contents.
