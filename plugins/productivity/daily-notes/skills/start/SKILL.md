---
description: Morning standup — surface open tasks, talking points, carry-forward context; adapts to show Jira status and Google Calendar agenda when those integrations are available
---

Morning standup — read my current state and help me plan the day. Adapts based on which optional integrations (Atlassian MCP, Google Calendar MCP, `gcal: true` profile flag) are available in this session.

## Steps

1. **Profile check**: Read the "Daily Notes Plugin Profile" block from `~/.claude/CLAUDE.md`. Capture `obsidian`, `gcal`, and `track_contacts` flags so later steps can branch correctly.

2. **Local tasks**: Glob all `Tasks/*.md` files. Read frontmatter (`status`, `priority`, `due`) of each. Filter to `open`, `in-progress`, `in-review`, or `blocked`. Group: `in-progress` / `in-review` first, then `open` (grouped by priority high first, then by due date), then `blocked` separately with the blocker noted. Skip `done`.

3. **Talking Points**: Read `Talking Points.md`. If non-empty, surface a summary: "You have talking points for: Name (count), Name (count)." List briefly so you know what's pending.

4. **Memory / Context**: Read `.claude/memory.md` (project-level) if it exists. Flag any follow-ups, reminders, or unfinished threads from previous sessions.

5. **Time-sensitive items**: From the tasks in step 2, call out anything due today or overdue.

6. **Jira status block (optional — Atlassian MCP)**:
   - **If any task from step 2 has a `jira:` frontmatter key AND the Atlassian MCP is available in this session**, fetch the live status for each of those keys from Jira. Annotate each task inline with the Jira status and flag drift — do NOT auto-update files.
     ```
     [POE-1234] Migrate auth tokens
       Local: in-progress | Jira: In Review ⚠️  — consider /jira-push to resolve
     ```
   - **If tasks have `jira:` keys but the Atlassian MCP is NOT available**, print once at the top of the section:
     `⚠️  Atlassian MCP not available in this session — live Jira status check skipped. Run /doctor to diagnose, or use /jira-push later to resolve drift.`
     Keep the local-only task list — do not fail the whole standup.
   - **If no tasks have `jira:` keys**, skip this block silently (no warning — nothing to check).

7. **Google Calendar agenda block (optional — requires both `gcal: true` in profile AND a Google Calendar MCP)**:
   - **If `gcal: true` AND a Google Calendar MCP exposing `list_events` is available**, call `list_events` with:
     - `timeMin`: today at 00:00 local time
     - `timeMax`: today at 23:59 local time
     - `maxResults`: 20
     Then:
       - **Meeting-heavy day check**: if 3 or more events, flag: "Meeting-heavy day — budget focus time accordingly."
       - **Prep check**: for each event, compare attendees against names in `Talking Points.md`; flag any match as "You have talking points for [Name] — meeting at HH:MM."
       - **Focus-block check**: if gaps between meetings are under 90 minutes, flag that deep work may be difficult.
   - **If `gcal: true` in profile but the Google Calendar MCP is NOT available**, print once:
     `⚠️  Google Calendar MCP not available in this session — today's agenda skipped. Run /doctor to confirm which integrations are detected, or add a Google Calendar MCP in your Claude Code settings.`
     Continue with the rest of the standup.
   - **If `gcal: false` or unset**, skip this block silently.

8. **Prioritization**: Based on everything above (local tasks, Jira drift, meeting density), suggest a prioritized plan for today — top 3 things to focus on. Be opinionated. If something looks blocked, say so. If it's a meeting-heavy day, bias the plan toward quick wins.

9. **Scratch Pad check**: Read `Scratch Pad.md`. If it has content, note it as a reminder to run `/sync` when ready.

10. **Cleanup check**: Ask if there's anything completed yesterday that should be removed from Tasks or memory. Update them if confirmed.

## Output format — plain markdown (default)

```
## Good morning — YYYY-MM-DD

### Today's Meetings          ← only if GCal block ran
- HH:MM–HH:MM  Meeting title [⚠️ talking points for Name]
- HH:MM–HH:MM  Meeting title

### In Progress
- [POE-1234] Task name  (Jira: In Review — local says in-progress ⚠️)
- Task name (no Jira link)

### Open / Up Next
- [KEY-456] Task name [high] — due YYYY-MM-DD

### Blocked
- Task name — blocked on: <reason>

### Talking Points Pending
Sarah (2), Dave (1)

### Suggested Focus
1. First priority
2. Second priority
3. Third priority

### Scratch Pad
Has content — run /sync when ready.
```

Skip any section with nothing notable.

## Output format — Obsidian (`obsidian: true` in profile)

Wrap sections in Obsidian callouts matched to urgency:

```
> [!danger] Overdue
> - Task name — due YYYY-MM-DD (N days ago)

> [!warning] Due Today
> - Task name [high]

> [!note] In Progress
> - Task name

> [!info] Talking Points Pending
> Sarah (2), Dave (1)

> [!tip] Suggested Focus
> 1. First priority
> 2. Second priority
> 3. Third priority
```

Meetings (if GCal block ran) go under `> [!abstract] Today's Meetings`.

## Tone

Quick and direct, like a 2-minute standup. No preamble. Use bullets. Skip sections that have nothing notable.

## Rules

- Do not modify any files during the standup — read-only except for the optional cleanup in step 10.
- Never fabricate data for a missing integration. If an MCP is unavailable, state it and move on.
- Integrations are purely additive — `/start` must produce a useful local-only standup whenever the MCPs are absent.
