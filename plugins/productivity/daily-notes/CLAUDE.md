# daily-notes Plugin — Role Profile

The daily-notes plugin works for anyone out of the box. Optionally, you can enable per-person contact tracking by adding a profile block to your global `~/.claude/CLAUDE.md`.

## Profile template

Copy this block into `~/.claude/CLAUDE.md` and fill in your values:

```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```

## Fields

| Field | Required | Default | Description |
|---|---|---|---|
| `role` | No | — | Free text. Helps Claude tailor language — no behavioral effect. |
| `track_contacts` | No | `false` | **Main gate.** Set to `true` to enable per-person meeting routing and contact logs. |
| `contacts_folder` | No | `People` | Folder name for per-person notes (e.g. `People`, `Clients`, `Advisors`). |
| `recurring_meetings_label` | No | `1:1` | Label used to identify recurring per-person meetings in transcripts (e.g. `1:1`, `check-in`, `sync`). |
| `macos_notifications` | No | `false` | Set to `true` to enable native macOS notifications when running `/reminders`. Fires one notification per overdue/due-today task; groups due-soon and stale items. |
| `obsidian` | No | `false` | Set to `true` to enable Obsidian-optimised output: callouts, `[[wikilinks]]`, and richer frontmatter (`created`, `type`) across all writing skills. Run `/obsidian-setup` once after enabling. |
| `obsidian_tasks` | No | `false` | Set to `true` to add Tasks-plugin emoji syntax (`📅 ⏫ 🔼`) inside task files. Requires the **Tasks** community plugin in Obsidian. Only meaningful when `obsidian: true`. |
| `gcal` | No | `false` | Set to `true` to enable Google Calendar enrichment in `/start` (agenda block) and the `notes-integrations` skills `/calendar` and `/meeting-reminder`. Requires a Google Calendar MCP configured in your Claude Code session. |
| `auto_start_suggestion` | No | `true` | Controls the `SessionStart` hook nudge. When a Claude Code session opens inside a daily-notes vault, the hook injects a one-line reminder to run `/start` (and a summary of open tasks + Scratch Pad state). Set to `false` to silence the nudge — the hook exits silently and no context is injected. The companion `Stop` hook (one nudge per session to run `/wrap-up` after 30+ min of active work) is always on; end a session fresh to reset its per-session flag. |

## What `obsidian: true` unlocks

- **All writing skills** (`/sync`, `/wrap-up`) — output uses Obsidian callouts (`> [!abstract]`, `> [!warning]`, `> [!check]`) for structured sections, and `[[wikilinks]]` for people references. Meeting notes and daily notes get `created: YYYY-MM-DD` and `type:` frontmatter fields for Dataview queries.
- **`/task create`** — task files gain `created` and `type: task` frontmatter. If `obsidian_tasks: true` is also set, a Tasks-plugin checkbox line is appended to the task body.
- **`/start`, `/reminders`** — chat output uses callouts matching urgency (`> [!warning]`, `> [!danger]`, `> [!tip]`).
- **`/obsidian-setup`** — unlocks the one-time vault scaffold: `Dashboard.md` (Dataview queries), `Templates/Daily Note.md`, `Templates/Meeting Note.md`.

Without `obsidian: true`, all output uses plain markdown — no callouts, no wikilinks, no emoji syntax.

## What `macos_notifications: true` unlocks

- **`/reminders`** — fires native macOS notifications via `osascript` for overdue and due-today tasks (one each), plus grouped notifications for due-soon and stale in-progress items.

Without `macos_notifications: true`, `/reminders` still shows the full summary in chat — notifications are simply not sent.

## Session hooks (always on)

The plugin ships two hooks that fire automatically in every Claude Code session — they never write to any file you own, never call external services, and exit silently when the cwd doesn't look like a daily-notes vault (no `Scratch Pad.md` + `Tasks/`).

- **`SessionStart`** — on startup / resume / clear, if the cwd is a vault, injects a one-line reminder listing open-task count and Scratch Pad state, and suggests `/start` (or `/sync` if the Scratch Pad already has content). Seeds `.claude/session-start.epoch` so the Stop hook can measure session length. Gated by `auto_start_suggestion` (default `true`).
- **`Stop`** — once per session, if elapsed ≥ 30 min and `Scratch Pad.md` or any `Tasks/*.md` has been modified since the session started, nudges the model to recommend `/wrap-up`. The one-shot `.claude/wrap-up-hinted` flag is cleared by the next `SessionStart`, so every fresh session gets at most one Stop nudge.

Both hooks write only to `.claude/session-start.epoch` and `.claude/wrap-up-hinted` in the current vault. No network, no MCP calls, no external I/O.

## What `track_contacts: true` unlocks

- **`/sync`** — Meetings matching `recurring_meetings_label` are filed under `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` instead of `Meetings/`. Notable feedback and events are logged to `{contacts_folder}/<Name>/log.md`.
- **`/prep`** — Surfaces meeting history from `{contacts_folder}/<Name>/Meeting History/` and recent entries from `{contacts_folder}/<Name>/log.md` in the pre-meeting summary.

Without `track_contacts: true`, all meetings route to `Meetings/` and no per-person logs are created.

## Example profiles

**IC Software Engineer (has 1:1s with manager)**
```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```

**Engineering Manager**
```markdown
## Daily Notes Plugin Profile
- role: Engineering Manager
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```

**Management Consultant**
```markdown
## Daily Notes Plugin Profile
- role: Management Consultant
- track_contacts: true
- contacts_folder: Clients
- recurring_meetings_label: sync
```

**PhD Student**
```markdown
## Daily Notes Plugin Profile
- role: PhD Student
- track_contacts: true
- contacts_folder: Advisors
- recurring_meetings_label: check-in
```

**No recurring per-person meetings**
```markdown
## Daily Notes Plugin Profile
- role: Product Designer
- track_contacts: false
```

**Obsidian vault user with Google Calendar**
```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- obsidian: true
- obsidian_tasks: true
- gcal: true
```
