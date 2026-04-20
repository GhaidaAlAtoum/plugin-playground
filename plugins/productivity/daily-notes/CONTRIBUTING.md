# Contributing to daily-notes

## Technical architecture

### Data flow — what each skill reads and writes

This diagram shows the full file I/O map for every skill. Use it when adding a new skill or changing how an existing one interacts with the file system.

```mermaid
flowchart LR
    SP["📄 Scratch Pad.md\n(inbox)"]

    SP -->|processes & clears| SY["/sync"]
    SY --> TP["📄 Talking Points.md"]
    SY --> TF["📁 Tasks/"]
    SY --> MF["📁 Meetings/"]
    SY --> DN["📁 Daily Notes/"]
    SY -.->|if track_contacts| PF["📁 People/"]

    TF -->|reads| ST["/start  /reminders  /task-list"]
    TP -->|reads| TP_SK["/talking-points"]
    TP_SK -->|edits| TP
    TP -->|reads| PR["/prep"]
    PF -.->|reads| PR

    TF -->|edits| TU["/task-update"]
    TU -->|writes| TF
    TF -->|moves| TA["/task-archive"]
    TA --> ARC["📁 Tasks/Archive/"]

    TF -->|reads| WU["/wrap-up"]
    WU -->|updates| TF
    WU -->|writes| DN
    WU -->|clears| SP
```

### Task frontmatter schema

Every task file in `Tasks/` uses this YAML frontmatter. All skills must stay consistent with this schema.

```yaml
---
status: open | in-progress | in-review | blocked | done
priority: high | medium | low
due: YYYY-MM-DD          # optional
scheduled: YYYY-MM-DD   # optional
completedDate: YYYY-MM-DD # set when status → done
tags: []
---
```

`in-review` and `blocked` are valid statuses — all skills that read or write `status` must handle all five values.

File modification time (`mtime`) is used as a proxy for "last updated" — there is no explicit `lastUpdated` field. Skills that detect stale tasks (e.g. `/reminders`) rely on this.

### Profile fields (read from `~/.claude/CLAUDE.md`)

Skills read these fields at runtime via the "Daily Notes Plugin Profile" block in the user's global CLAUDE.md:

| Field | Type | Default | Consumed by |
|---|---|---|---|
| `role` | string | — | `/start`, `/wrap-up` (tone only) |
| `track_contacts` | bool | false | `/sync`, `/prep`, `/recap` |
| `contacts_folder` | string | `People` | `/sync`, `/prep` |
| `recurring_meetings_label` | string | `1:1` | `/sync` |
| `macos_notifications` | bool | false | `/reminders` |

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`description:`) and natural-language steps.
2. Update `README.md` — add to skills table and usage examples.
3. Update this file — add the skill to the data flow diagram if it reads or writes any files.
4. Bump the patch or minor version in `plugin.json`.
