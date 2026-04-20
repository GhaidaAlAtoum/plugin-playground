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

    TF -->|reads| ST["/start  /reminders  /task list"]
    TP -->|reads| TP_SK["/talking-points"]
    TP_SK -->|edits| TP
    TP -->|reads| PR["/prep"]
    PF -.->|reads| PR

    TF -->|edits| TU["/task update"]
    TU -->|writes| TF
    TF -->|moves| TA["/task archive"]
    TA --> ARC["📁 Tasks/Archive/"]

    TF -->|reads| WU["/wrap-up"]
    WU -->|updates| TF
    WU -->|writes| DN
    WU -->|clears| SP

    PF -->|reads| OOOP["/one-on-one-prep"]
    TP -->|reads| OOOP
    TF -->|reads| OOOP
    OOOP -.->|optional append| PF

    PF -->|reads| TR["/team-recap"]
    TF -->|reads| TR
    MF -->|reads| TR
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
jira: POE-1234          # optional — links to a Jira issue
jira_url: https://...   # optional — canonical Jira URL
release: v2.4           # optional — free-text release label consumed by /release-notes
tags: []
---
```

`in-review` and `blocked` are valid statuses — all skills that read or write `status` must handle all five values.

The `release:` field is a **free-text label** — exact string matching is used by `/release-notes <label>`. No validation beyond "a string." Skills that write tasks must never invent a label; only set `release:` if the user mentioned one.

### Contact log frontmatter — `People/<Name>/log.md`

Per-person log files accept an optional YAML frontmatter block. The only recognized field is:

```yaml
---
report: true
---
```

`report: true` marks a contact as a direct report. `/team-recap` iterates only over contacts with this field. `/one-on-one-prep` works regardless. No other fields are consumed by any skill — the rest of the log is free-form `## <heading>` + date + body entries.

File modification time (`mtime`) is used as a proxy for "last updated" — there is no explicit `lastUpdated` field. Skills that detect stale tasks (e.g. `/reminders`) rely on this.

### Profile fields (read from `~/.claude/CLAUDE.md`)

Skills read these fields at runtime via the "Daily Notes Plugin Profile" block in the user's global CLAUDE.md:

| Field | Type | Default | Consumed by |
|---|---|---|---|
| `role` | enum `ic \| manager \| po \| other` | `ic` | `/start`, `/wrap-up` (tone + role-specific nudges); gates which skills are surfaced in hints. Any unrecognized string is normalized to `ic`. |
| `track_contacts` | bool | false | `/sync`, `/prep`, `/recap`, `/one-on-one-prep`, `/team-recap` |
| `contacts_folder` | string | `People` | `/sync`, `/prep` |
| `recurring_meetings_label` | string | `1:1` | `/sync` |
| `macos_notifications` | bool | false | `/reminders` |
| `statusline_mode` | enum `quiet \| focus \| off` | `quiet` *(when wired)* | `statusline/daily-notes-status.sh` |

### Session hooks

Declared in `hooks/hooks.json` and implemented as POSIX shell scripts in `hooks/`. Both hooks must:

- Exit `0` silently when the cwd isn't a daily-notes vault (signature: `Scratch Pad.md` + `Tasks/` exist). Never fail a session for an unrelated project.
- Emit only JSON on stdout in the verified Claude Code hook shapes — `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}` for SessionStart, `{"decision":"block","reason":"..."}` for Stop.
- Never call external services or slash commands, never modify notes. Writes are restricted to `.claude/session-start.epoch` (SessionStart) and `.claude/wrap-up-hinted` (Stop one-shot flag).

`SessionStart` respects the `auto_start_suggestion` profile field (default `true`; set `false` to silence). `Stop` is always-on but self-limits to one nudge per session via the flag, which SessionStart clears on each startup/resume/clear.

When adding new hooks: follow the same gate-first pattern (vault signature → profile opt-out → work), keep runtime under the `timeout` budget declared in `hooks.json`, and document the new hook in `CLAUDE.md` under "Session hooks".

### Statusline (`statusline/daily-notes-status.sh`)

The statusline runs after every assistant message (Claude Code debounces at 300ms). It reads session JSON from stdin, prints one line to stdout, and exits 0. A user opts in by wiring the script path into `~/.claude/settings.json` under `statusLine.command` — `/init` offers to do this automatically; `/doctor` verifies it.

Non-negotiable rules for any future change to the statusline:

1. **Local only.** No network, no MCP calls, no shelling out to API clients. The bar fires on every user prompt; an API call here will rate-limit the user's account and stall the UI. The whole reason gcal meeting signals are out of v1 is that they'd require a 5-minute disk cache and a refresh daemon — revisit only with that infrastructure in place.
2. **Cache-or-die.** Every signal must be derivable from local files whose mtimes change when the signal should change. Cache in `.claude/statusline-cache.<session_id>.json`. Any signal that can't be invalidated via mtime belongs out of scope.
3. **Stable icon count within a mode.** Emoji widths vary across terminals (iTerm2, Terminal.app, VS Code, Warp). Adding and removing icons causes visible jitter. Quiet mode's "show only when non-zero" pattern is the quiet contract; focus mode's "always show `🔴N 🟠N`" is the focus contract. Don't blur them.
4. **Empty stdout = blank bar.** Every error path exits 0 with no output. Never print stack traces, warnings, or "broken" strings to stdout — the bar is user-visible. Errors surface through `/doctor` instead.
5. **Fail silent on every edge.** If `~/.claude/CLAUDE.md` is unreadable, the profile is malformed, stat is unavailable, or `Tasks/` contains a corrupt task file — print `📓` and move on. The Claude Code UI must never see a non-zero exit from this script.

Adding a new signal? Add it to `statusline/README.md` legend + mode tables, update the `daily-notes-status.sh` task-scan loop, and add an invalidation source to the mtime set. The `/doctor` check 7 dry-run should exercise it.

### Error messages — standard pattern

When a skill depends on something that's not available (MCP, macOS permission, missing profile field), it must surface the failure explicitly — never silent degradation. Use this exact pattern so users learn the shape and know where to look:

```
⚠️  <what's missing> — <what's affected>. Run /doctor to diagnose.
```

Examples:
- `⚠️  Atlassian MCP not available in this session — /jira-pull needs live Jira access. Run /doctor to see which integrations are detected, or add an Atlassian MCP in your Claude Code settings.`
- `⚠️  macOS notifications unavailable — osascript call failed. Run /doctor to diagnose …`
- `⚠️  Google Calendar MCP not available in this session — agenda skipped. Run /doctor …`

Rules:
1. **Never silently degrade.** If a feature is skipped, the user has to be told — even if the base skill still produces useful output.
2. **Point to /doctor.** Every message ends with "Run /doctor to …" so users learn one diagnostic entry point.
3. **Never fabricate data** to fill the gap (e.g. don't guess calendar events or ticket statuses).
4. **Don't prompt the user to install the missing MCP.** This plugin never manages MCP config — only detects it.

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`description:`) and natural-language steps.
2. Update `README.md` — add to skills table and usage examples.
3. Update this file — add the skill to the data flow diagram if it reads or writes any files.
4. Follow the error-message pattern above for every external dependency.
5. Bump the patch or minor version in `plugin.json`.
