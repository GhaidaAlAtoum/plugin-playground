---
description: Scan tasks for overdue, due today, due soon, scheduled today, and stale in-progress items — with optional macOS notifications
---

Check for urgent and time-sensitive tasks and surface them as a reminder summary.

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

   **Obsidian profile check:** If `obsidian: true` is set in the Daily Notes Plugin Profile, use callouts matched to urgency level instead:
   ```
   > [!danger] Overdue (N)
   > - Task name — due YYYY-MM-DD (X days ago) [priority]

   > [!warning] Due Today (N)
   > - Task name [priority]

   > [!caution] Due Soon — next 3 days (N)
   > - Task name — due YYYY-MM-DD [priority]

   > [!note] Scheduled Today (N)
   > - Task name

   > [!info] Stale In-Progress (N)
   > - Task name — in-progress for X days
   ```

   Omit sections with no items in either format. If no items appear in any category, say "No urgent reminders — you're clear."

5. **macOS notifications**: **Profile check:** Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context. If `macos_notifications: true` is set, fire macOS notifications via `osascript`:
   - One notification per **overdue** task (3 beeps — most urgent):
     `osascript -e 'display notification "Overdue since YYYY-MM-DD" with title "daily-notes" subtitle "<Task name>"' && osascript -e 'beep 3'`
   - One notification per **due-today** task (2 beeps):
     `osascript -e 'display notification "Due today" with title "daily-notes" subtitle "<Task name>"' && osascript -e 'beep 2'`
   - One grouped notification if there are **due-soon** items (1 beep):
     `osascript -e 'display notification "N tasks due in the next 3 days" with title "daily-notes" subtitle "Due soon"' && osascript -e 'beep 1'`
   - One grouped notification if there are **stale in-progress** items (1 beep):
     `osascript -e 'display notification "N tasks stalled — check in?" with title "daily-notes" subtitle "Stale in progress"' && osascript -e 'beep 1'`
   - If `osascript` fails or is unavailable, surface it explicitly: print `⚠️  macOS notifications unavailable — osascript call failed. Run /doctor to diagnose (likely: Apple Events permission not granted in System Settings → Privacy & Security → Automation).` Continue with the chat summary — reminders are not lost, only the OS-level notification.
   - If `macos_notifications` is not set or is `false`, skip this step entirely — no `osascript` calls.

6. **Quick actions** (offer after the summary):
   > "Want to snooze or close any of these? Say `snooze <task name> 3 days` or `done <task name>`."
   - **Snooze**: extend `due` forward by N days in the task file. Confirm before writing.
   - **Done**: set `status: done` and add `completedDate: YYYY-MM-DD`. Confirm before writing.
   - If no updates are requested, nothing is written.

## Rules

- Read-only until the user requests a quick action in step 6.
- Confirm all writes before executing — never modify files silently.
- Stale detection uses file modification time as a proxy — if the OS does not expose mtime reliably, skip the stale category and note it.
- Never show tasks with `status: done` or `status: cancelled` in any category.
