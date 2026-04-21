---
description: Scan tasks for overdue, due today, due soon, scheduled, and stale items — with optional macOS notifications
---

Check for urgent and time-sensitive tasks and surface them as a reminder summary.

## macOS osascript blocks

All `osascript` notification commands and the overdue-dialog command live in `${CLAUDE_PLUGIN_ROOT}/references/macos-integration.md`. Read that file in step 5 only if `macos_notifications: true` is set; skip it otherwise.

## Steps

1. **Resolve today's date**: Use the current date from context.

2. **Scan tasks**: Glob `Tasks/*.md`. For each file, read the frontmatter fields: `status`, `priority`, `due`, `scheduled`. Skip tasks with `status: done` or `status: cancelled`.

3. **Categorize by urgency** (a task may appear in only one category — highest urgency wins):

   | Category | Criteria |
   |----------|----------|
   | **Overdue** | `due` is set and `due` < today, status not `done` |
   | **Due today** | `due` == today, status not `done` |
   | **Due soon** | `due` is within 3 days from today (exclusive of today), status not `done` |
   | **Scheduled today** | `scheduled` == today, status `open` |
   | **Stale in-progress** | status `in-progress` or `in-review`, and the file has not been modified in 5 or more days |

   For stale detection: use the file's last-modified timestamp as a proxy for "last updated."

4. **Present reminder summary**:

   **Plain markdown** (default):
   ```
   ## Reminders — YYYY-MM-DD

   ### Overdue (N)
   - <Task name> — due YYYY-MM-DD (X days ago) [priority]

   ### Due Today (N)
   - <Task name> [priority]

   ### Due Soon — next 3 days (N)
   - <Task name> — due YYYY-MM-DD [priority]

   ### Scheduled Today (N)
   - <Task name>

   ### Stale In-Progress (N)
   - <Task name> — in-progress for X days
   ```

   **Obsidian profile check:** If `obsidian: true` is set in the Daily Notes Plugin Profile, use callouts matched to urgency level instead — `> [!danger]` (overdue), `> [!warning]` (due today), `> [!caution]` (due soon), `> [!note]` (scheduled today), `> [!info]` (stale in-progress).

   Omit sections with no items in either format. If no items appear in any category, say "No urgent reminders — you're clear."

5. **macOS notifications**: If `macos_notifications: true` in the Daily Notes Plugin Profile, fire `osascript` notifications using the commands in `references/macos-integration.md`:
   - One notification per **overdue** task (3 beeps).
   - One notification per **due-today** task (2 beeps).
   - One grouped notification each for **due-soon** and **stale in-progress** if any exist (1 beep each).

   On any `osascript` failure, surface the standard error pattern (also in the reference file) once, stop further `osascript` calls this run, but keep the chat summary intact. If `macos_notifications` is unset or `false`, skip this entire step — no `osascript` calls.

6. **Quick actions** (offer after the summary):
   > "Want to snooze or close any of these? Say `snooze <task name> 3 days` or `done <task name>`."
   - **Snooze**: extend `due` forward by N days in the task file. Confirm before writing.
   - **Done**: set `status: done` and add `completedDate: YYYY-MM-DD`. Confirm before writing.
   - If no updates are requested, nothing is written.

7. **macOS overdue dialogs** *(opt-in — only if `macos_notifications: true` and there is at least one overdue task)*: For each overdue task (cap **3 per run**, highest priority first; tie-break on oldest `due`), open the three-button dialog from `references/macos-integration.md`. Parse the returned button:
   - **Mark done** → set `status: done` + `completedDate: YYYY-MM-DD`. Print `✓ Marked done: <Task name>`.
   - **Snooze 1h** → bump `due` forward by 1 hour (full datetime semantics in the reference). Print `⏰ Snoozed 1h: <Task name> → <new due>`.
   - **Dismiss** (or cancel / close) → no write, no output.
   - If more than 3 overdue tasks exist, print: `Showed dialogs for 3 of N overdue tasks — re-run /reminders to cycle through the rest.`

   On `osascript` failure, surface the standard error message once and skip remaining dialogs. Chat summary from step 4 is never lost.

## Rules

- Read-only until the user requests a quick action in step 6 or interacts with a step-7 dialog.
- Confirm all writes before executing — never modify files silently (dialog button presses are themselves a confirmation).
- Stale detection uses file modification time as a proxy — if the OS does not expose mtime reliably, skip the stale category and note it.
- Never show tasks with `status: done` or `status: cancelled` in any category.
