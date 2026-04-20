---
description: Nudge for meetings that ended in the last 2 hours with no notes written — prompts to capture while it's fresh
---

Check for recently ended meetings that have no notes yet, and prompt to capture while memory is fresh.

## Prerequisites

Requires a Google Calendar MCP configured in your Claude Code session.

> **Compatibility:** This skill calls `list_events` with `timeMin`, `timeMax`, and `maxResults` parameters. It works with any Google Calendar MCP that exposes a `list_events` tool with this signature. If your MCP uses a different tool name, this skill will fail with a clear "Google Calendar unavailable — check MCP config." message; the rest of the plugin is unaffected.

Also requires `gcal: true` in your Daily Notes Plugin Profile in `~/.claude/CLAUDE.md`.

If the MCP is unavailable, print: `⚠️  Google Calendar MCP not available in this session — meeting reminders require live calendar data. Run /doctor to see which integrations are detected.` and stop.

## Steps

1. **Profile check**: Confirm `gcal: true` is set. If not set, say "Add `gcal: true` to your Daily Notes Plugin Profile to enable Google Calendar." and stop.

2. **Fetch recent events**: Call `list_events` with:
   - `timeMin`: 2 hours ago (ISO 8601 with local offset)
   - `timeMax`: now
   - `maxResults`: 10

3. **Filter to ended meetings**: Keep only events where `end` is in the past (already over). Skip all-day events (no `dateTime` on start/end).

4. **Cross-reference with local notes**: Glob `Meetings/*.md`. For each ended meeting, check if a file exists whose name contains the meeting title or today's date + title. Also check `Scratch Pad.md` for any mention of the meeting title.

5. **Report**:
   - If all ended meetings have notes: "You're all caught up — notes exist for all recent meetings."
   - If some are missing:
     ```
     ## Meeting Reminder — HH:MM

     These meetings ended in the last 2 hours with no notes:

     - HH:MM–HH:MM  Meeting title [attendees]
     ```

6. **Offer quick capture**: For each unnoticed meeting, ask:
   > "Want me to open a note for '[Meeting title]'? I can create a blank template or you can start dictating and I'll structure it."

   - **Blank template**: create `Meetings/YYYY-MM-DD [Meeting title].md` with standard sections (Notes, Action Items, Decisions). Confirm before writing.
   - **Dictate**: prompt the user to paste or type their raw notes, then format and save as a meeting note via the same flow as `/sync`.

7. **Scratch Pad check**: If the user dictates notes, add them to `Scratch Pad.md` and suggest running `/sync` to fully process them, or process inline if the content is self-contained.

## Rules

- Read-only until the user confirms a write action in step 6.
- Never overwrite an existing meeting note — check first.
- Confirm all file paths before writing.
- Skip events shorter than 5 minutes (likely auto-created blocks or declined events with `status: cancelled`).
