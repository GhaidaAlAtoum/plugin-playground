---
description: Morning standup with local tasks and live Jira ticket statuses
---

Start the day with a combined view of local tasks and current Jira ticket statuses.

## Prerequisites

Requires the Atlassian MCP to be configured in your Claude Code session.

## Steps

1. **Local task summary**: Glob `Tasks/*.md`. Read each file and group by status:
   - `in-progress` / `in-review` — list first, these are today's focus
   - `open` — list second, potential picks for today
   - `blocked` — list separately with the blocker noted
   - Skip `done` and `cancelled`.

2. **Jira status sync**: For each task file that has a `jira:` frontmatter key, fetch the current status from Jira via the Atlassian MCP. Note any tickets whose local status differs from Jira (e.g. local says `in-progress` but Jira says `In Review`). Flag these — do not auto-update the files.

3. **Today's priorities**: Based on steps 1-2, suggest 2-3 things to focus on today. Factor in priority, in-flight work, and any Jira status drift noted in step 2.

4. **Check Scratch Pad**: Read `Scratch Pad.md`. If it has content, note it as a reminder to run `/sync` to process it.

5. **Present standup summary**:
   ```
   ## Good morning — <date>

   ### In Progress
   - [KEY-123] Task name (Jira: In Review — local says in-progress ⚠️)
   - Task name (no Jira link)

   ### Open / Up Next
   - [KEY-456] Task name

   ### Blocked
   - Task name — blocked on: <reason>

   ### Suggested Focus
   1. ...
   2. ...

   ### Scratch Pad
   Has content — run /sync when ready.
   ```

## Rules

- Do not modify any files during standup.
- If the Atlassian MCP is unavailable, fall back to local tasks only and note that Jira sync was skipped.
- Flag status drift — do not silently correct it. The user decides whether to update.
- Skip sections that have no content.
