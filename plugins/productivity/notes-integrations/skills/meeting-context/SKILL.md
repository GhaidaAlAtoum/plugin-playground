---
description: Surface Unblocked context (PRs, Slack, decisions) for a person or topic and append it to their most recent meeting note
---

Enrich a meeting note with relevant institutional context from Unblocked.

## Prerequisites

Requires the Unblocked MCP to be configured in your Claude Code session.

## Steps

1. **Identify target**: If not specified in arguments, ask: "Who or what topic should I pull context for?" Accept a person's name or a topic string (e.g. "auth migration", "Sarah").

2. **Find the meeting note**:
   - **Profile check:** Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context.
   - If `track_contacts: true` is set and the input is a person's name, look for their most recent file in `{contacts_folder}/<Name>/Meeting History/` (default `contacts_folder`: `People`).
   - Otherwise, look for the most recent file in `Meetings/` whose name or content mentions the person/topic.
   - If no meeting note is found, ask the user to confirm which file to enrich before continuing.

3. **Pull Unblocked context**: Call the Unblocked MCP with the person's name or topic as the query. Apply these time windows:
   - **Related PRs**: last 7 days
   - **Slack threads**: last 3 days
   - **Decisions / Background**: no time limit (architectural and team decisions stay relevant indefinitely)
   - **In Progress**: no time limit (scope to open/active work only)

   Limit to 5-7 most relevant results total.

   **Override**: If the user passes a duration argument (e.g. `/meeting-context Sarah 90d`), apply that window to PRs and Slack threads instead of the defaults.

4. **Present before writing**: Show the context you're about to append:
   ```
   ## Unblocked Context — <Name/Topic> (<date>)
   
   **Related PRs**
   - PR #123: <title> — <status> (<link>)
   
   **Decisions / Background**
   - <summary of relevant decision or thread>
   
   **In Progress**
   - <any work in flight that's relevant>
   ```
   Ask: "Append this to `<file path>`?" before writing.

5. **Append to meeting note**: On approval, append the context block to the end of the target meeting note file. Do not overwrite any existing content.

## Rules

- Read-only until the user approves the append in step 4.
- If the Unblocked MCP is not available, print: `⚠️  Unblocked MCP not available in this session — this skill enriches meeting notes with Unblocked context and can't run without it. Run /doctor to see which integrations are detected.` and stop.
- If results are sparse or irrelevant, say so — do not pad with filler.
- Limit context block to what's genuinely useful for the upcoming meeting.
