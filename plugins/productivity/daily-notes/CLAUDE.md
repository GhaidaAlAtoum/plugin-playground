# daily-notes Plugin — Profile schema

Skills in this plugin read the `## Daily Notes Plugin Profile` section from the user's global `~/.claude/CLAUDE.md`. This file is the **schema-only** reference — just the fields and one-line meanings. For role behavior, example profiles, and what each flag unlocks, see [`docs/role-profile-reference.md`](docs/role-profile-reference.md).

## Profile template

```markdown
## Daily Notes Plugin Profile
- display_name: Alex
- role: ic
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- macos_notifications: false
- obsidian: false
- obsidian_tasks: false
- auto_start_suggestion: true
```

Only fields you actually configure need to be present — omitted fields fall back to defaults.

## Fields

| Field | Type | Default | Meaning |
|---|---|---|---|
| `display_name` | string | — | Used in standup output only. |
| `role` | `ic` / `manager` / `po` / `other` / free text | `ic` | Gates role-specific skills. Unrecognized strings normalize to `ic`. See [role reference](docs/role-profile-reference.md#what-role-changes). |
| `track_contacts` | bool | `false` | Main gate for per-person meeting routing and contact logs. Required by `/one-on-one-prep`, `/team-recap`. |
| `contacts_folder` | string | `People` | Folder name for per-person notes. |
| `recurring_meetings_label` | string | `1:1` | Label identifying recurring per-person meetings. |
| `macos_notifications` | bool | `false` | Enables native macOS notifications for `/reminders`. |
| `obsidian` | bool | `false` | Enables Obsidian-optimised output: callouts, `[[wikilinks]]`, richer frontmatter. |
| `obsidian_tasks` | bool | `false` | Adds Tasks-plugin emoji syntax to task files. Requires `obsidian: true`. |
| `auto_start_suggestion` | bool | `true` | Gates the `SessionStart` hook nudge. Set `false` to silence. |

## See also

- [`docs/role-profile-reference.md`](docs/role-profile-reference.md) — role behavior table, example profiles for IC / manager / PO / consultant / PhD student, direct-report tracking via `report: true`, release labels, what Obsidian/macOS flags unlock, session-hook behavior.
- [`docs/first-time-guide.md`](docs/first-time-guide.md) / [`docs/first-time-guide-obsidian.md`](docs/first-time-guide-obsidian.md) — setup walkthroughs.
- [`docs/day-in-the-life.md`](docs/day-in-the-life.md) — one weekday end-to-end.
- [`references/`](references/) — canonical note formats, Obsidian templates, macOS osascript blocks (skill-internal).
