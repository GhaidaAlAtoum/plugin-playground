---
description: Morning standup combining local tasks and Google Calendar agenda — flags meeting-heavy days and surfaces prep needs
---

Start the day with a unified view of local tasks and today's Google Calendar schedule.

## Prerequisites

Requires a Google Calendar MCP configured in your Claude Code session.

> **Compatibility:** This skill calls `list_events` with `timeMin`, `timeMax`, and `maxResults` parameters. It works with any Google Calendar MCP that exposes a `list_events` tool with this signature. If your MCP uses a different tool name, this skill falls back to the standard `/start` standup (local tasks only) with a note: "Google Calendar unavailable — showing local tasks only."

Also requires `gcal: true` in your Daily Notes Plugin Profile in `~/.claude/CLAUDE.md`.

If the MCP is unavailable, fall back to the standard `/start` standup (local tasks only) and note: "Google Calendar unavailable — showing local tasks only."

## Steps

1. **Local tasks**: Glob `Tasks/*.md`. Read frontmatter (status, priority, due). Filter to `open` and `in-progress`. Group: high priority first, then by due date. Note anything overdue or due today.

2. **Talking Points**: Read `Talking Points.md`. If non-empty, note who has pending agenda items and the count.

3. **Memory/Context**: Read `.claude/memory.md` if it exists. Surface carry-forward notes and open threads.

4. **Today's calendar**: Call `list_events` with:
   - `timeMin`: today at 00:00 local time
   - `timeMax`: today at 23:59 local time
   - `maxResults`: 20

5. **Meeting-heavy day check**: Count today's events. If 3 or more, flag: "Meeting-heavy day — budget focus time accordingly."

6. **Prep check**: For each calendar event today, check if the attendees match anyone in `Talking Points.md`. If so, note: "You have talking points for [Name] — meeting at HH:MM."

7. **Prioritized plan**: Suggest 2-3 things to focus on today, accounting for meeting gaps. If focus blocks are short (under 90 minutes between meetings), flag that deep work may be difficult.

8. **Scratch Pad check**: Read `Scratch Pad.md`. If it has content, remind to run `/sync`.

9. **Present standup**:

   **Plain markdown** (default):
   ```
   ## Good morning — YYYY-MM-DD

   ### Today's Meetings
   - HH:MM–HH:MM  Meeting title [⚠️ talking points for Name]
   - HH:MM–HH:MM  Meeting title

   ### Tasks — In Progress
   - Task name [high] — due today

   ### Tasks — Open / Up Next
   - Task name [priority] — due YYYY-MM-DD

   ### Suggested Focus
   1. First priority
   2. Second priority
   3. Third priority
   ```

   **Obsidian profile check:** If `obsidian: true` is set, wrap sections in callouts matched to urgency (same pattern as `/start` and `/reminders`).

   Skip any section with nothing notable.

## Tone

Quick and direct — 2-minute standup. Bullets only. No preamble.
