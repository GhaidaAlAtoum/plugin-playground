---
description: Enrich Jira ticket references in Scratch Pad with title, status, and description before /sync processes them
---

Find Jira ticket keys in Scratch Pad.md and enrich them with live data from Jira before running /sync.

## Prerequisites

Requires the Atlassian MCP to be configured in your Claude Code session.

## Steps

1. **Scan Scratch Pad**: Read `Scratch Pad.md`. Find all Jira ticket key patterns (e.g. `ABC-123`, `POE-4567`). If none are found, say so and stop.

2. **Fetch ticket data**: For each unique ticket key found, fetch from Jira via the Atlassian MCP:
   - Summary (title)
   - Status
   - Description (first 3-4 sentences)
   - Assignee and reporter
   - Priority

3. **Preview enrichment**: Show the user what will be inserted into the Scratch Pad for each ticket:
   ```
   **[KEY-123]** <Ticket Summary>
   - Status: In Progress | Priority: High
   - Assignee: <name>
   - <Short description excerpt>
   - URL: <link>
   ```
   Ask: "Enrich these ticket references in `Scratch Pad.md`?" before writing.

4. **Update Scratch Pad**: On approval, for each ticket key found in the Scratch Pad, replace or annotate the bare key reference with the enriched block from step 3. Preserve surrounding context (notes, action items) — only add to what's there, don't remove anything.

5. **Confirm**: Report which tickets were enriched. Remind the user to run `/sync` to file everything.

## Rules

- Do not clear or restructure the Scratch Pad — only enrich ticket references in place.
- If a ticket key returns no results (e.g. wrong key, no access), note it clearly and skip that key.
- If the Atlassian MCP is unavailable, say so and stop.
- Never fabricate ticket data — all information must come from the MCP response.
