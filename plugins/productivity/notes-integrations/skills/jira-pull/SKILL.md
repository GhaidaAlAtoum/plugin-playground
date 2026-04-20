---
description: Pull your open Jira tickets and create task files in Tasks/
---

Fetch your open and in-progress Jira tickets and file them as tasks.

## Prerequisites

Requires the Atlassian MCP to be configured in your Claude Code session.

## Steps

1. **Fetch tickets**: Use the Atlassian MCP to query Jira for issues assigned to you in the active sprint. Use this JQL as the primary query:
   ```
   assignee = currentUser() AND sprint in openSprints() AND statusCategory != Done ORDER BY updated DESC
   ```
   Limit to 20 results unless told otherwise.

   **Fallback**: If the primary query returns 0 results (e.g. no active sprint, kanban board, or sprint function unsupported), automatically retry without the sprint filter:
   ```
   assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC
   ```
   If the fallback is used, note in chat: "No active sprint found — showing all open tickets."

   This handles custom workflow status names (e.g. "Ready to Develop", "In Review", "Blocked") without hardcoding specific status strings.

2. **Check for duplicates**: Glob `Tasks/*.md`. For each fetched ticket, check if a file already exists whose name contains the ticket key (e.g. `POE-1234`). Skip tickets that already have a task file.

3. **Propose new tasks**: For each new ticket, show the proposed task one at a time:
   ```
   Create task for [KEY-123]: <ticket summary>
   Status: In Progress | Priority: Medium | URL: <link>
   Proceed? [y/n/skip all]
   ```
   On approval, create `Tasks/KEY-123 — <slug>.md` with this frontmatter:
   ```markdown
   ---
   status: <open|in-progress|in-review>
   priority: <low|medium|high>
   jira: KEY-123
   jira_url: <ticket URL>
   due: ~
   tags: []
   ---
   # KEY-123: <Ticket Summary>

   <Ticket description, trimmed to 3-5 sentences>

   ## Notes

   ```

4. **Summary**: Report how many tasks were created, how many were skipped (already existed), and how many were declined.

## Rules

- Never overwrite an existing task file.
- If the Atlassian MCP is not available, print: `⚠️  Atlassian MCP not available in this session — /jira-pull needs live Jira access. Run /doctor to see which integrations are detected, or add an Atlassian MCP in your Claude Code settings.` and stop. Never guess or fabricate ticket data.
- Status mapping: Use `statusCategory` for broad mapping — `To Do` category (includes "Ready to Develop", "Open", etc.) → `open`; `In Progress` category (includes "In Progress", "In Review", "Blocked", etc.) → `in-progress`; `Done` category → skip entirely. If `statusCategory` is unavailable, fall back to: exact match `In Progress` or `In Review` → `in-progress`, everything else non-Done → `open`.
- Priority mapping: Jira `Highest`/`High` → `high`, `Medium` → `medium`, `Low`/`Lowest` → `low`.
