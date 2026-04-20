# daily-notes

A personal note-tracking system for Claude Code. Keeps your scratch pad, tasks, meetings, and daily log organized — without leaving your editor.

Works out of the box for anyone. Optionally enable per-person contact tracking by setting a role profile in your global `~/.claude/CLAUDE.md` (see [Configuration](#configuration)).

---

## Requirements

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** — installed and authenticated. That's it.
- **A dedicated folder for your notes** — your project root, `~/Documents/notes/`, anywhere you open Claude Code.
- **Optional: [Obsidian](https://obsidian.md)** — for browsing and editing your notes visually. Any Markdown editor works; Obsidian adds backlinks, graph view, and the Dataview plugin for filtered task views. Nothing in this plugin is Obsidian-specific.

---

## Skills

| Skill | Invoke | What it does |
|-------|--------|--------------|
| First-run setup | `/init` | Interactive scaffold: folder tree, starter files, profile block. Idempotent. |
| Health check | `/doctor` | Verifies folder structure, profile fields, and detects which optional MCPs are available. |
| Morning standup | `/start` | Lists open tasks, suggests today's focus, flags a loaded Scratch Pad. Auto-enriches with live Jira status and today's GCal agenda when those MCPs are available. |
| Sync notes | `/sync` | Processes Scratch Pad, summarizes new meeting notes, routes talking points, creates tasks, writes daily note |
| Meeting prep | `/prep <name>` | Quick-reference sheet before a meeting: talking points, recent history, related tasks |
| 1:1 prep | `/one-on-one-prep <name>` | Structured 1:1 prep: since-last-1:1, open threads, suggested topics, growth prompts. Optionally appends to the next 1:1 note. Needs `track_contacts: true`. |
| Team recap | `/team-recap <window>` | Manager-oriented per-direct-report summary across a time window: activity, blockers, 1:1 cadence, attention flags. Needs `track_contacts: true` and `report: true` in each report's `log.md`. |
| Manage tasks | `/task [verb]` | Single entry point — `create`, `list` (default), `update`, `archive`. E.g. `/task create`, `/task list high`, `/task update`, `/task archive 14` |
| Reminders | `/reminders` | Scans tasks for overdue, due today, due soon, stale in-progress — with optional macOS notifications |
| Talking points | `/talking-points` | View and manage all talking points grouped by person — add, remove, or clear inline |
| Obsidian setup | `/obsidian-setup` | One-time vault scaffold: Dashboard.md with Dataview queries, daily note + meeting templates |
| End of day | `/wrap-up` | Closes out the day: reviews tasks, prompts for wins/blockers, writes daily note summary |

---

## How it works

### The core idea — one inbox, everything else is automatic

The central habit is simple: **put everything into `Scratch Pad.md`, then run `/sync`**. Claude reads it, files action items as tasks, routes agenda items to the right person, saves meeting notes, and writes your daily log — you never manually sort anything.

```mermaid
flowchart LR
    You(("👤 You"))
    You -->|"jot anything —\nideas, action items,\nmeeting notes, reminders"| SP["📄 Scratch Pad.md\nyour inbox"]

    SP -->|"/sync\nClaude sorts it all"| tasks["✅ Tasks/\naction items"]
    SP -->|"/sync"| tp["💬 Talking Points.md\nagenda items per person"]
    SP -->|"/sync"| mtg["📅 Meetings/\nmeeting summaries"]
    SP -->|"/sync"| dn["📓 Daily Notes/\nyour daily log"]
```

### Your day — when to use each skill

```mermaid
flowchart LR
    subgraph morning["☀️ Morning (2 min)"]
        start["/start\nWhat's on my plate?"]
        rem["/reminders\nAnything overdue?"]
    end

    subgraph day["🔨 During the day"]
        tp2["/talking-points\nCheck agenda before a meeting"]
        prep["/prep &lt;name&gt;\nQuick context before a 1:1"]
        tc["/task create\nCapture something new"]
        tu["/task update\nMove a task forward"]
        sp2["📄 Scratch Pad.md\njot notes during meetings"]
        sync["/sync\nFile everything after"]
    end

    subgraph evening["🌙 End of day"]
        wrap["/wrap-up\nClose out & log the day"]
        arch["/task archive\nWeekly cleanup"]
    end

    morning --> day
    sp2 --> sync
    sync --> evening
    day --> evening
    evening -.->|next morning| morning
```

> See [CONTRIBUTING.md](CONTRIBUTING.md) for the full file I/O map and schema reference.

---

## File structure

```
<project root>/
├── Scratch Pad.md           # Inbox — dump anything here, /sync files it
├── Talking Points.md        # Topics to raise with specific people
├── Tasks/
│   └── TASK-NAME.md         # One file per task, YAML frontmatter
├── Meetings/
│   └── YYYY-MM-DD Meeting.md
├── Daily Notes/
│   └── YYYY-MM-DD.md
└── People/                  # Only created if track_contacts: true
    └── <Name>/
        ├── Meeting History/
        │   └── YYYY-MM-DD.md
        └── log.md
```

---

## Usage examples

**Morning routine**
```
/start
```
> Lists your in-progress and open tasks, suggests 2-3 things to focus on, and reminds you if Scratch Pad has content.

**Dump notes, let Claude file them**
```
/sync
```
> Processes everything in `Scratch Pad.md`: routes action items to tasks, talking points to `Talking Points.md`, meeting notes to `Meetings/` (or a contact's folder if `track_contacts: true`), and writes today's daily note. Confirms before clearing the Scratch Pad.

**Preview what `/sync` will do — no writes**
```
/sync --preview
```
> Read-only plan mode. Parses the Scratch Pad and any new meeting notes, then prints a numbered plan of the creates/updates/appends it would perform — **no files are written, Scratch Pad is left intact**. Edit the Scratch Pad and re-preview until the plan looks right, then run `/sync` (no flag) to apply. `/sync --dry-run` is an alias.
```
Plan: 3 creates, 1 append, 1 clear. No files written. Run /sync to apply.

Would create
  1. CREATE Tasks/fix-login-bug.md — from "fix login bug" note
  2. CREATE Meetings/2026-04-20 Standup.md — summary of 4-bullet meeting
  3. CREATE Daily Notes/2026-04-20.md — 4 items processed

Would append
  4. APPEND Talking Points.md → ## Sarah — "Ask about Q2 plan"

Would clear
  5. CLEAR Scratch Pad.md — replace with blank line
```

**Prep for a meeting**
```
/prep Sarah
```
> Shows: pending talking points for Sarah, open items from her last meeting note, recent contact log entries, and any tasks that mention her.

**Quick task**
```
/task create
/task "fix login bug"     # first arg isn't a verb → treated as a title
```
> Walks you through naming the task, setting status/priority/due date, and saves it to `Tasks/`. `/task list`, `/task update`, and `/task archive` share the same entry point — see the skill for the full dispatch.

**Check for urgent tasks**
```
/reminders
```
> Scans all tasks and surfaces overdue, due today, due soon, scheduled today, and stale in-progress items in a prioritized list. Offers to snooze or close items inline. If `macos_notifications: true` is set in your profile, also fires native macOS notifications for overdue and due-today tasks — plus up to 3 **action-button dialogs** for overdue items (Mark done / Snooze 1h / Dismiss) so you can resolve them without typing.

**End of day**
```
/wrap-up
```
> Reviews what got done, asks for wins and blockers, closes out the daily note.

**Archive old tasks**
```
/task archive
/task archive 14
```
> Scans `Tasks/` for completed tasks older than 7 days (or N days if specified). Shows a list and asks before moving anything to `Tasks/Archive/`.

---

## Daily workflow

```
Morning
  /start           — see what's on your plate
                     (auto-includes live Jira + GCal agenda when those
                      MCPs are available — no separate command needed)
  /reminders       — check for anything urgent or overdue

During the day
  /task create     — capture new work
  /task update     — move tasks forward
  /talking-points  — review or add agenda items before meetings
  /prep <name>     — quick context before a 1:1

After meetings
  /sync            — file loose notes from Scratch Pad

End of day
  /wrap-up         — close out tasks, finalize daily note
  /task archive    — clean up done tasks (weekly or as needed)
```

---

## Role-specific workflows

Set `role:` in your Daily Notes Plugin Profile to one of `ic`, `manager`, `po`, `other`. Unrecognized strings are normalized to `ic`.

**Manager** (`role: manager` + `track_contacts: true`)
```
/one-on-one-prep Sarah         # structured 1:1 prep
/team-recap last week          # per-direct-report summary
```
> Mark each direct report by adding `report: true` to their `{contacts_folder}/<Name>/log.md` frontmatter. `/team-recap` iterates only over those entries.

**PO / Product** (`role: po`)
```
/release-notes v2.4            # from notes-integrations — local-first, optional Jira enrichment
```
> Tag tasks with `release: v2.4` in their frontmatter. `/release-notes <label>` aggregates into Shipped / In progress / Carryover buckets. If the Atlassian MCP is registered, Jira titles and URLs are fetched; otherwise the skill runs on local task files only.

**IC** (`role: ic` or unset) — the default palette. `/start`, `/sync`, `/task`, `/wrap-up`.

All skills above work regardless of `role` — the field only controls which ones get surfaced as nudges in `/start`.

---

## Smart defaults — session hooks

Two hooks ship with the plugin and run automatically in every Claude Code session. Both are silent unless the cwd is a daily-notes vault (has `Scratch Pad.md` + `Tasks/`) — they never affect unrelated projects.

- **Start-of-session nudge** — when you open Claude Code in a vault, a short reminder is injected suggesting `/start` (or `/sync` if the Scratch Pad already has content), along with an open-task count. Silence with `auto_start_suggestion: false` in your profile.
- **End-of-session nudge** — once per session, if you've been working for 30+ minutes and have edits in `Scratch Pad.md` or `Tasks/`, the model is prompted to remind you to run `/wrap-up` before the session ends. Fires at most one time per session.

Neither hook makes network calls, modifies your notes, or runs any slash command on your behalf. The only files they write are `.claude/session-start.epoch` (session timestamp) and `.claude/wrap-up-hinted` (one-shot flag) inside your vault.

---

## Configuration

The plugin works without any configuration. To enable per-person meeting routing and contact logs, add a profile block to your global `~/.claude/CLAUDE.md`:

```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
```

See [`CLAUDE.md`](CLAUDE.md) for the full field reference and example profiles for different roles (IC engineer, consultant, PhD student, etc.).

### Optional: macOS notifications

Add `macos_notifications: true` to your profile to enable native macOS notifications when running `/reminders`:

```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- macos_notifications: true
```

Notifications are off by default. When enabled, overdue and due-today tasks each get their own notification; due-soon and stale items are grouped.

**Approve `osascript` automatically** (recommended): by default Claude Code prompts for permission each time a notification fires. To allow it silently, add this to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(osascript:*)"
    ]
  }
}
```

### What `track_contacts: true` unlocks

- `/sync` routes meetings matching `recurring_meetings_label` to `{contacts_folder}/<Name>/Meeting History/` instead of `Meetings/`
- `/sync` writes notable feedback/events to `{contacts_folder}/<Name>/log.md`
- `/prep <name>` surfaces that person's meeting history and log entries

---

## macOS integrations

The plugin assumes macOS and leans into it. None of the features below are required — they're sugar on top of the plain-Markdown core.

| Integration | What it adds | How to enable |
|---|---|---|
| **Native notifications** | `/reminders` fires one notification per overdue / due-today task, groups due-soon and stale items, and (for overdues) pops up **action-button dialogs** (Mark done / Snooze 1h / Dismiss) that write straight back to the task file. | `macos_notifications: true` in your profile. |
| **Ambient statusline** | A persistent signal in the Claude Code status bar: `📓` in a clean vault, `📓 🔴3` when you have overdue tasks, `📓 📝` when Scratch Pad has content to sync. Opt-in "focus mode" (aka ADHD mode) keeps core counts visible even at zero for users who benefit from persistent visibility. Fully local — no network, no MCP. | `/init` offers to wire it during setup. Or add manually — see [`statusline/README.md`](statusline/README.md). |
| **Shortcuts.app recipes** | One-tap Morning Standup (reads `/start` aloud), Quick Note (opens Scratch Pad + previews sync), After Meeting (triggers `/meeting-reminder`). Menu-bar, keyboard-shortcut, or calendar-event triggered. | Follow [`shortcuts/README.md`](shortcuts/README.md). No `.shortcut` import needed — build each in 2 minutes. |
| **Spotlight** | Your notes folder is already indexed, so `⌘ Space` + typing a task name surfaces the right `.md` file instantly. | Works out of the box. For faster results, keep your vault out of excluded folders in **System Settings → Siri & Spotlight → Spotlight Privacy**. |
| **Quick Look** | Select any `.md` file in Finder and press **Space** to preview rendered Markdown without opening an editor. | Works out of the box on macOS Sonoma+. For richer rendering (callouts, code blocks), install [QLMarkdown](https://github.com/sbarex/QLMarkdown). |

> **Menu-bar task list / Dock badge counts**: out of scope for this plugin — those need a standalone macOS app. If you build one on top of the task file format, open an issue and we'll link it.

### Dialog permission

The first overdue dialog from `/reminders` triggers a macOS permission prompt — grant **Terminal → Control Other Apps** under **System Settings → Privacy & Security → Automation**. If you skip or deny, `/reminders` falls back to the chat summary only; no data is lost.

---

## Using with Obsidian

Open your notes folder as an Obsidian vault and add these two fields to your profile for a fully integrated experience:

```markdown
## Daily Notes Plugin Profile
- role: Software Engineer
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- obsidian: true
- obsidian_tasks: true
```

Then run `/obsidian-setup` once to scaffold your vault.

### What Obsidian mode adds

```mermaid
flowchart LR
    subgraph plain["Without Obsidian mode"]
        p1["Plain markdown sections\n## Summary"]
        p2["Plain text references\nTalked to Sarah about..."]
        p3["Basic frontmatter\nstatus, priority, due"]
    end

    subgraph obs["With obsidian: true"]
        o1["> [!abstract] Summary\nCallout sections"]
        o2["[[Sarah]] wikilinks\nGraph view connections"]
        o3["created, type: meeting\nDataview-queryable fields"]
    end

    plain -->|enable| obs
```

| Feature | Without | With `obsidian: true` |
|---|---|---|
| Note sections | Plain `## headers` | Callouts (`> [!abstract]`, `> [!warning]`) |
| People references | Plain text | `[[Name]]` wikilinks → graph edges |
| Frontmatter | `status`, `priority`, `due` | + `created`, `type` for Dataview |
| Task files | YAML frontmatter only | + Tasks emoji (`📅 ⏫`) if `obsidian_tasks: true` |
| `/start` + `/reminders` output | Bullet lists | Callouts per urgency level |
| Vault infrastructure | Manual | `/obsidian-setup` generates Dashboard + templates |

### What `/obsidian-setup` creates

```mermaid
flowchart TD
    setup["/obsidian-setup"]

    setup --> dash["Dashboard.md\nDataview queries for:\n• Open tasks by priority\n• Due today\n• Recent meetings\n• This week's daily notes"]

    setup --> dn["Templates/Daily Note.md\nCompatible with Obsidian\nDaily Notes + Periodic Notes plugins"]

    setup --> mn["Templates/Meeting Note.md\nCallout sections pre-filled"]

    setup --> guide["Plugin install guidance\nin chat:\n• Dataview (required)\n• Periodic Notes\n• Calendar\n• Tasks (if obsidian_tasks: true)"]
```

### Obsidian graph view

When `obsidian: true` is set, `/sync` writes `[[Name]]` wikilinks in every meeting note and contact log. Over time this builds a rich graph connecting your meetings, people, and daily notes.

### Recommended Obsidian plugins

| Plugin | Required? | What it enables |
|---|---|---|
| **Dataview** | Yes (for Dashboard.md) | Live queries across your vault |
| **Periodic Notes** | Recommended | Weekly, monthly, quarterly notes |
| **Calendar** | Recommended | Sidebar calendar linked to daily notes |
| **Tasks** | Only if `obsidian_tasks: true` | Emoji task syntax across vault |

---

## Installation & setup

### 1. Install the plugin

```bash
claude plugin marketplace add ghaidaatoum/plugin-playground
```
Then install **daily-notes** from the **Discover** tab in `/plugin`.

### 2. Run `/init`

Open Claude Code and run:

```
/init
```

`/init` walks you through a short interactive setup: picks a notes folder (default `~/Documents/notes`), creates the folder tree (`Tasks/`, `Meetings/`, `Daily Notes/`, optional `People/`), seeds `Scratch Pad.md` + `Talking Points.md` + `.claude/memory.md`, and writes your Daily Notes Plugin Profile into `~/.claude/CLAUDE.md`. No shell commands, no manual file editing.

It's idempotent — rerunning against an existing vault offers reuse instead of overwriting.

### 3. Check the install with `/doctor`

```
/doctor
```

`/doctor` reports: folder structure ✓, profile fields ✓, which optional MCPs are detected, and exact fix steps for anything missing. Absent MCPs (Atlassian, Unblocked, Google Calendar) are fine — they're optional upgrades. Run `/doctor` any time something feels off.

### 4. Start your day

```
cd <your-notes-folder> && claude
/start
```

### 5. (Optional) Open in Obsidian

Point Obsidian at your notes folder as a vault. Everything is plain Markdown — no Obsidian-specific setup needed. The [Dataview plugin](https://github.com/blacksmithgu/obsidian-dataview) lets you build filtered task views by status, priority, or due date.
