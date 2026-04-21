---
description: Morning standup — open tasks, talking points, carry-forward; adds live Jira status when Atlassian MCP is present
---

Morning standup — read my current state and help me plan the day. Adapts based on whether the Atlassian MCP is available in this session.

## Steps

1. **Profile check**: Read the "Daily Notes Plugin Profile" block from `~/.claude/CLAUDE.md`. Capture `obsidian` and `track_contacts` flags so later steps can branch correctly.

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

7. **Prioritization**: Based on everything above (local tasks, Jira drift), suggest a prioritized plan for today — top 3 things to focus on. Be opinionated. If something looks blocked, say so.

8. **Scratch Pad check**: Read `Scratch Pad.md`. If it has content, note it as a reminder to run `/sync` when ready.

9. **Cleanup check**: Ask if there's anything completed yesterday that should be removed from Tasks or memory. Update them if confirmed.

## Output format — plain markdown (default)

```
## Good morning — YYYY-MM-DD

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

## Tone

Quick and direct, like a 2-minute standup. No preamble. Use bullets. Skip sections that have nothing notable.

## Rules

- Do not modify any files during the standup — read-only except for the optional cleanup in step 9.
- Never fabricate data for a missing integration. If an MCP is unavailable, state it and move on.
- Integrations are purely additive — `/start` must produce a useful local-only standup whenever the MCPs are absent.
