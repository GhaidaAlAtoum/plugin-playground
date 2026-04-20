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
| `role` | No | `ic` | **Recognized values:** `ic`, `manager`, `po`, `other`. Any free text (e.g. `Software Engineer`, `Product Designer`) is treated as `ic`. Controls which role-specific skills are surfaced and shapes tone in `/start`, `/wrap-up`. `manager` unlocks `/one-on-one-prep` and `/team-recap`; `po` surfaces `/release-notes` in standups and hints. See the "What `role` changes" section below for the full behavior table. |
| `track_contacts` | No | `false` | **Main gate.** Set to `true` to enable per-person meeting routing and contact logs. Required by `/one-on-one-prep` and `/team-recap`. |
| `contacts_folder` | No | `People` | Folder name for per-person notes (e.g. `People`, `Clients`, `Advisors`). |
| `recurring_meetings_label` | No | `1:1` | Label used to identify recurring per-person meetings in transcripts (e.g. `1:1`, `check-in`, `sync`). |
| `macos_notifications` | No | `false` | Set to `true` to enable native macOS notifications when running `/reminders`. Fires one notification per overdue/due-today task; groups due-soon and stale items. |
| `obsidian` | No | `false` | Set to `true` to enable Obsidian-optimised output: callouts, `[[wikilinks]]`, and richer frontmatter (`created`, `type`) across all writing skills. Run `/obsidian-setup` once after enabling. |
| `obsidian_tasks` | No | `false` | Set to `true` to add Tasks-plugin emoji syntax (`📅 ⏫ 🔼`) inside task files. Requires the **Tasks** community plugin in Obsidian. Only meaningful when `obsidian: true`. |
| `auto_start_suggestion` | No | `true` | Controls the `SessionStart` hook nudge. When a Claude Code session opens inside a daily-notes vault, the hook injects a one-line reminder to run `/start` (and a summary of open tasks + Scratch Pad state). Set to `false` to silence the nudge — the hook exits silently and no context is injected. The companion `Stop` hook (one nudge per session to run `/wrap-up` after 30+ min of active work) is always on; end a session fresh to reset its per-session flag. |
| `statusline_mode` | No | `quiet` *(when wired)* | Controls the daily-notes Claude Code status line. Values: `quiet` (at-a-glance reassurance — only surfaces overdue / dirty-scratch when present), `focus` (opt-in "ADHD mode" — always shows overdue + due-today counts, even at zero, for persistent visibility), `off` (script runs but prints nothing). Only meaningful after the statusline is wired into `~/.claude/settings.json` — run `/init` to opt in, or see `statusline/README.md` for manual install. |

## What `role` changes

The `role` field has four recognized values. Any other string is normalized to `ic`.

| Value | Role-specific skills surfaced | Behavior differences |
|---|---|---|
| `ic` | — (default skill palette) | Plain tone in `/start` and `/wrap-up`. |
| `manager` | `/one-on-one-prep`, `/team-recap` | `/start` includes a "Direct reports to check on" nudge if any `{contacts_folder}/*/log.md` has `report: true` and hasn't been updated recently. `/wrap-up` asks whether any 1:1 notes need filing. |
| `po` | `/release-notes` (from `notes-integrations`) | `/start` surfaces tasks with `release:` labels grouped by label. `/wrap-up` asks whether the release cut is affected by today's changes. |
| `other` | — | Same as `ic`. Set this if you want to silence the `ic` default label. |

Skills listed above still work for any role — the `role` field just controls whether they're *surfaced* in `/start` and `/wrap-up` nudges. You can always invoke them directly.

## Direct-report tracking — `report: true` in `log.md` frontmatter

For `/team-recap` and `/one-on-one-prep` to treat a person as a direct report, add a frontmatter block at the top of their `{contacts_folder}/<Name>/log.md`:

```markdown
---
report: true
---

## <existing log entries below>
```

Only contacts with `report: true` are included in `/team-recap`. `/one-on-one-prep <name>` works for anyone in `{contacts_folder}/` regardless of the field — the field gates bulk iteration, not per-person prep.

## Release labels — `release:` in task frontmatter

`/release-notes` (in `notes-integrations`) buckets tasks by a free-text release label set in task frontmatter:

```yaml
---
status: in-progress
priority: high
jira: POE-1234
release: v2.4
---
```

The label is a free string — pick a convention your team recognizes (`v2.4`, `Q2-2026`, `april-release`). `/task create` and `/task update` accept a `release:` value when you mention one (e.g. "for the v2.4 release"). `/release-notes v2.4` aggregates all tasks with an exact matching label.

## What `obsidian: true` unlocks

- **All writing skills** (`/sync`, `/wrap-up`) — output uses Obsidian callouts (`> [!abstract]`, `> [!warning]`, `> [!check]`) for structured sections, and `[[wikilinks]]` for people references. Meeting notes and daily notes get `created: YYYY-MM-DD` and `type:` frontmatter fields for Dataview queries.
- **`/task create`** — task files gain `created` and `type: task` frontmatter. If `obsidian_tasks: true` is also set, a Tasks-plugin checkbox line is appended to the task body.
- **`/start`, `/reminders`** — chat output uses callouts matching urgency (`> [!warning]`, `> [!danger]`, `> [!tip]`).
- **`/obsidian-setup`** — unlocks the one-time vault scaffold: `Dashboard.md` (Dataview queries), `Templates/Daily Note.md`, `Templates/Meeting Note.md`.

Without `obsidian: true`, all output uses plain markdown — no callouts, no wikilinks, no emoji syntax.

## What `macos_notifications: true` unlocks

- **`/reminders`** — fires native macOS notifications via `osascript` for overdue and due-today tasks (one each), plus grouped notifications for due-soon and stale in-progress items.

Without `macos_notifications: true`, `/reminders` still shows the full summary in chat — notifications are simply not sent.

## What `statusline_mode` unlocks

Opt-in via `/init` (offers to wire the statusline + writes this field), or manually — see `statusline/README.md`. The script is fully local: reads `Scratch Pad.md` + `Tasks/` only, no network calls, no MCP dependencies.

- **`statusline_mode: quiet` *(default when wired)*** — at-a-glance reassurance. The bar shows `📓` in a clean vault. Surfaces `🔴N` only if there are overdue tasks and `📝` only if Scratch Pad has unflushed content. Designed to fade into the background when things are fine.
- **`statusline_mode: focus` *("ADHD mode")*** — persistent visibility, even at zero. Always shows `🔴N 🟠N` (overdue + due today). Adds `⏸N` when any task is stale in-progress, and `📝` when Scratch Pad is dirty. Chosen for users where "out of sight, out of mind" leads to missed work.
- **`statusline_mode: off`** — script runs but prints nothing. The bar blanks. Useful for temporarily silencing without unwinding the `settings.json` wiring.

Outside a vault (cwd missing `Scratch Pad.md` or `Tasks/`), the script always prints nothing — your status bar stays unaffected in unrelated projects.

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
- role: manager
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```
> Use `role: manager` (not `Engineering Manager`) to enable `/one-on-one-prep` and `/team-recap` nudges in `/start`. Add `report: true` to each direct report's `log.md` frontmatter.

**Product Manager / PO**
```markdown
## Daily Notes Plugin Profile
- role: po
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```
> `role: po` surfaces `/release-notes` in `/start` and groups open tasks by `release:` label.

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

**Obsidian vault user**
```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- obsidian: true
- obsidian_tasks: true
```
