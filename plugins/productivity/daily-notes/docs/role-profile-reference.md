# Role profile reference — daily-notes

Extended docs for the `## Daily Notes Plugin Profile` block you added to `~/.claude/CLAUDE.md` via `/init` (or by hand). The **slim schema** lives in [`../CLAUDE.md`](../CLAUDE.md) — this file covers everything else: what each role changes, example profiles for common roles, how direct-report tracking works, and what the Obsidian / macOS flags unlock.

`/init` and `/doctor` both point here when they need more than the one-line field summary.

---

## What `role` changes

Four recognized values. Any other string is normalized to `ic`.

| Value | Role-specific skills surfaced | Behavior differences |
|---|---|---|
| `ic` | — (default palette) | Plain tone in `/start` and `/wrap-up`. |
| `manager` | `/one-on-one-prep`, `/team-recap` | `/start` adds a "Direct reports to check on" nudge when any `{contacts_folder}/*/log.md` has `report: true` and hasn't been updated recently. `/wrap-up` asks whether any 1:1 notes need filing. |
| `po` | `/release-notes` (from `notes-integrations`) | `/start` surfaces tasks with `release:` labels grouped by label. `/wrap-up` asks whether the release cut is affected by today's changes. |
| `other` | — | Same as `ic`. Set this to silence the `ic` default label. |

Skills listed above still work for any role — the `role` field just controls whether they're *surfaced* in `/start` and `/wrap-up` nudges. You can always invoke them directly.

---

## Direct-report tracking — `report: true` in `log.md` frontmatter

For `/team-recap` and `/one-on-one-prep` to treat a person as a direct report, add a frontmatter block at the top of their `{contacts_folder}/<Name>/log.md`:

```markdown
---
report: true
---

## <existing log entries below>
```

Only contacts with `report: true` are included in `/team-recap`. `/one-on-one-prep <name>` works for anyone in `{contacts_folder}/` regardless of the field — the field gates bulk iteration, not per-person prep.

---

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

---

## What `obsidian: true` unlocks

- **All writing skills** (`/sync`, `/wrap-up`) — output uses Obsidian callouts (`> [!abstract]`, `> [!warning]`, `> [!check]`) for structured sections, and `[[wikilinks]]` for people references. Meeting notes and daily notes get `created: YYYY-MM-DD` and `type:` frontmatter fields for Dataview queries.
- **`/task create`** — task files gain `created` and `type: task` frontmatter. If `obsidian_tasks: true` is also set, a Tasks-plugin checkbox line is appended to the task body.
- **`/start`, `/reminders`** — chat output uses callouts matching urgency (`> [!warning]`, `> [!danger]`, `> [!tip]`).
- **`/obsidian-setup`** — unlocks the one-time vault scaffold: `Dashboard.md` (Dataview queries), `Templates/Daily Note.md`, `Templates/Meeting Note.md`.

Without `obsidian: true`, all output uses plain markdown — no callouts, no wikilinks, no emoji syntax.

---

## What `macos_notifications: true` unlocks

- **`/reminders`** — fires native macOS notifications via `osascript` for overdue and due-today tasks (one each), plus grouped notifications for due-soon and stale in-progress items. Also enables up to 3 action-button dialogs per run for overdue tasks (Mark done / Snooze 1h / Dismiss) that write straight back to the task file.

Without `macos_notifications: true`, `/reminders` still shows the full summary in chat — notifications and dialogs are simply not sent.

---

## Session hooks (always on)

The plugin ships two hooks that fire automatically in every Claude Code session — they never write to any file you own, never call external services, and exit silently when the cwd doesn't look like a daily-notes vault (no `Scratch Pad.md` + `Tasks/`).

- **`SessionStart`** — on startup / resume / clear, if the cwd is a vault, injects a one-line reminder listing open-task count and Scratch Pad state, and suggests `/start` (or `/sync` if the Scratch Pad already has content). Seeds `.claude/session-start.epoch` so the Stop hook can measure session length. Gated by `auto_start_suggestion` (default `true`).
- **`Stop`** — once per session, if elapsed ≥ 30 min and `Scratch Pad.md` or any `Tasks/*.md` has been modified since the session started, nudges the model to recommend `/wrap-up`. The one-shot `.claude/wrap-up-hinted` flag is cleared by the next `SessionStart`, so every fresh session gets at most one Stop nudge.

Both hooks write only to `.claude/session-start.epoch` and `.claude/wrap-up-hinted` in the current vault. No network, no MCP calls, no external I/O.

---

## What `track_contacts: true` unlocks

- **`/sync`** — Meetings matching `recurring_meetings_label` are filed under `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` instead of `Meetings/`. Notable feedback and events are logged to `{contacts_folder}/<Name>/log.md`.
- **`/prep`** — Surfaces meeting history from `{contacts_folder}/<Name>/Meeting History/` and recent entries from `{contacts_folder}/<Name>/log.md` in the pre-meeting summary.

Without `track_contacts: true`, all meetings route to `Meetings/` and no per-person logs are created.

---

## Example profiles

**IC Software Engineer (has 1:1s with manager)**
```markdown
## Daily Notes Plugin Profile
- display_name: Alex
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```

**Engineering Manager**
```markdown
## Daily Notes Plugin Profile
- display_name: Jamie
- role: manager
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```
> Use `role: manager` (not `Engineering Manager`) to enable `/one-on-one-prep` and `/team-recap` nudges in `/start`. Add `report: true` to each direct report's `log.md` frontmatter.

**Product Manager / PO**
```markdown
## Daily Notes Plugin Profile
- display_name: Pat
- role: po
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```
> `role: po` surfaces `/release-notes` in `/start` and groups open tasks by `release:` label.

**Management Consultant**
```markdown
## Daily Notes Plugin Profile
- display_name: Morgan
- role: Management Consultant
- track_contacts: true
- contacts_folder: Clients
- recurring_meetings_label: sync
```

**PhD Student**
```markdown
## Daily Notes Plugin Profile
- display_name: Sam
- role: PhD Student
- track_contacts: true
- contacts_folder: Advisors
- recurring_meetings_label: check-in
```

**No recurring per-person meetings**
```markdown
## Daily Notes Plugin Profile
- display_name: Casey
- role: Product Designer
- track_contacts: false
```

**Obsidian vault user**
```markdown
## Daily Notes Plugin Profile
- display_name: Alex
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- obsidian: true
- obsidian_tasks: true
```
