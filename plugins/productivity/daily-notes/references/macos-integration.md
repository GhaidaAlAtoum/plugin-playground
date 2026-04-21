# macOS integration reference

Shared reference for every skill that fires `osascript` notifications or dialogs. Gated by `macos_notifications: true` in the Daily Notes Plugin Profile. If the flag is false/unset, skip every command block here.

Consumers: `/reminders` (notifications + overdue dialogs).

---

## Platform gate

Before any `osascript` call, verify `uname -s` returns `Darwin`. On any non-macOS platform, skip all blocks below and note: *"Non-macOS detected — skipping macOS notifications."*

---

## Notification commands (display + beep)

One-shot notifications. The `beep` count encodes urgency.

**Overdue** — one notification per overdue task (3 beeps):
```bash
osascript -e 'display notification "Overdue since YYYY-MM-DD" with title "daily-notes" subtitle "<Task name>"' && osascript -e 'beep 3'
```

**Due today** — one notification per due-today task (2 beeps):
```bash
osascript -e 'display notification "Due today" with title "daily-notes" subtitle "<Task name>"' && osascript -e 'beep 2'
```

**Due soon** — one grouped notification if there are due-soon items (1 beep):
```bash
osascript -e 'display notification "N tasks due in the next 3 days" with title "daily-notes" subtitle "Due soon"' && osascript -e 'beep 1'
```

**Stale in-progress** — one grouped notification if there are stale in-progress items (1 beep):
```bash
osascript -e 'display notification "N tasks stalled — check in?" with title "daily-notes" subtitle "Stale in progress"' && osascript -e 'beep 1'
```

---

## Overdue action dialogs (opt-in, opt-out)

For each overdue task (up to 3 per run; show highest-priority first), open a three-button dialog:

```bash
osascript -e 'display dialog "Overdue since YYYY-MM-DD\n\n<Task name>" with title "daily-notes — overdue" buttons {"Dismiss", "Snooze 1h", "Mark done"} default button "Mark done" cancel button "Dismiss" with icon caution'
```

The command prints `button returned:<label>` on stdout. Parse that:

- **Mark done** → update the task file: set `status: done`, add `completedDate: YYYY-MM-DD` (today). Print `✓ Marked done: <Task name>`.
- **Snooze 1h** → update `due`. If `due` already has a time (`YYYY-MM-DDTHH:MM`), add one hour; otherwise set it to today + 1 hour (`YYYY-MM-DDT<now+1h>`). Print `⏰ Snoozed 1h: <Task name> → <new due>`.
- **Dismiss** (or cancel / window close) → no write, no output.

Cap at **3 dialogs per run** — if more overdue tasks exist, print:
```
Showed dialogs for 3 of N overdue tasks — re-run /reminders to cycle through the rest.
```

Priority tie-break for which 3 to show: `high` > `normal` > `low`, then oldest `due` first.

---

## Failure handling

If any `osascript` call fails (permission denied, not on macOS, dialog cancelled with error), surface the standard error pattern and stop issuing further `osascript` calls this run — but **keep the chat summary intact**:

```
⚠️  macOS notifications unavailable — osascript call failed. Run /doctor to diagnose (likely: Apple Events permission not granted in System Settings → Privacy & Security → Automation).
```

The chat-based reminder summary is never skipped — notifications and dialogs are additive.

---

## Permission setup (for user reference)

First `osascript` call triggers a macOS permission prompt. Grant in **System Settings → Privacy & Security → Automation** — approve Terminal (or the host app) controlling **System Events**.

To pre-approve silently in Claude Code settings, add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(osascript:*)"
    ]
  }
}
```
