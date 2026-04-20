---
description: Morning standup — surface open tasks, talking points, and carry-forward context to plan your day
---

Morning standup — read my current state and help me plan the day.

## Steps

1. **Tasks**: Glob all `Tasks/*.md` files. Read frontmatter (status, priority, due) of each. Filter to `status: open` or `status: in-progress`. Group by priority (high first) then due date. Summarize in brief bullet points.

2. **Talking Points**: Read `Talking Points.md`. If non-empty, surface a summary: "You have talking points for: Name (count), Name (count)." List them briefly so you know what's pending.

3. **Memory/Context**: Read `.claude/memory.md` (project-level) if it exists. Flag any follow-ups, reminders, or unfinished threads from previous sessions.

4. **Time-sensitive items**: From the Tasks filtered in step 1, call out anything due today or overdue.

5. **Prioritization**: Based on the above, suggest a prioritized plan for today — top 3 things to focus on. Be opinionated. If something looks blocked, say so.

6. **Cleanup check**: Ask if there's anything completed yesterday that should be removed from Tasks or memory. Update them if confirmed.

## Tone

Quick and direct, like a 2-minute standup. No fluff. Use bullets. Skip sections that have nothing notable.

## Obsidian profile check

If `obsidian: true` is set in the Daily Notes Plugin Profile, wrap the chat output sections in Obsidian callouts instead of plain headers:

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

If `obsidian` is false or not set, use plain bullet lists with markdown headers as before.
