---
description: Push local task status changes back to Jira — surface drift and let you choose which source of truth wins
---

Sync local task status changes back to Jira for tasks that have a `jira:` frontmatter key.

**Requires Atlassian MCP.**

## Steps

1. **Check MCP availability**: If the Atlassian MCP is not available, stop immediately:
   > "Atlassian MCP is not connected. Configure it in your Claude Code session to use /jira-push."

2. **Collect Jira-linked tasks**: Glob `Tasks/*.md` (and `Tasks/Archive/*.md`). For each file, read frontmatter. Collect all tasks with a `jira:` field (e.g., `jira: KEY-123`). Skip tasks with `status: cancelled`.

3. **If no Jira-linked tasks found**: Report "No tasks with a `jira:` key found. Run /jira-pull to import tickets first." and stop.

4. **Fetch live Jira statuses**: For each collected task, fetch the live ticket status from Jira via Atlassian MCP. Handle errors per-ticket (ticket not found, permission error) — log and skip gracefully.

5. **Identify drift**: Compare local `status` to Jira status using this mapping:

   | Local status | Jira equivalent |
   |---|---|
   | open | To Do |
   | in-progress | In Progress |
   | in-review | In Review |
   | done | Done |
   | blocked | (no Jira equivalent — flag separately) |

   Collect tasks where local status does not match Jira status.

6. **If no drift**: Report "All Jira-linked tasks are in sync. No updates needed." and stop.

7. **Present drift summary** (one task at a time):
   ```
   [KEY-123] Fix login bug
   Local: done | Jira: In Progress

   Which is correct?
   1. Push local → Jira  (update Jira to "Done")
   2. Pull Jira → local  (update local task to "in-progress")
   3. Skip this task
   ```
   Wait for user response before moving to the next task.

8. **Apply selected action**:
   - **Push local → Jira**: Transition the Jira ticket to the mapped status via Atlassian MCP. Confirm success.
   - **Pull Jira → local**: Update the local task file's `status` frontmatter. Show old → new before writing.
   - **Skip**: No change.

9. **Report results** after all tasks:
   ```
   ## Jira Push Summary
   - KEY-123: Jira updated → Done ✓
   - KEY-124: Local updated → in-review ✓
   - KEY-125: Skipped
   ```

## Rules

- Never auto-update either source — always ask which direction to sync, per task.
- Never push `blocked` status to Jira (no equivalent) — flag it: "Local status is 'blocked' — no direct Jira equivalent. Update Jira manually or skip."
- If a Jira transition fails (e.g., workflow rules block it), report the error clearly and skip that task — do not abort the whole run.
- If the user has multiple Jira projects, tasks without a `jira_url` field may require the user to confirm the correct project.
- Archived tasks (`Tasks/Archive/*.md`) are included in drift detection — useful for confirming Jira is also marked done.
