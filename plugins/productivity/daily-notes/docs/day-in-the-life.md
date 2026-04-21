# A day in the life — daily-notes + notes-integrations

One weekday, start to finish, showing every skill in context. Timestamps are illustrative — the order and frequency are what matter, not the clock.

The flow assumes:
- `daily-notes` installed and `/init` done.
- Profile set to `role: ic`, `track_contacts: true`, `macos_notifications: true`, `obsidian: true` (so you see how the Obsidian-mode output differs).
- `notes-integrations` installed, with the Atlassian and Unblocked MCPs registered in the session. Where a step specifically needs one, it's called out as *+ with MCP*.

If you're on the plain-markdown path or don't have those MCPs, skip the lines marked *+ with …*. Everything else works identically.

---

## 08:30 — Open laptop, `cd ~/Documents/notes && claude`

The `SessionStart` hook fires silently. It detects you're in a vault, counts open tasks, and injects a one-line nudge:

> **daily-notes**: 3 open tasks · Scratch Pad has 5 lines · run `/start`

You didn't type anything — the hook just made sure you won't forget.

---

## 08:32 — `/start`

Morning standup. Reads your open tasks, surfaces anything overdue or due today, checks the Scratch Pad, reads `.claude/memory.md` for carry-forward context, and suggests 2–3 focus items.

With `obsidian: true` the sections come back as callouts:

```
> [!warning] Due Today
> - Migrate auth tokens [high]

> [!note] In Progress
> - Refactor rate limiter

> [!info] Talking Points Pending
> Sarah (2), Dave (1)

> [!tip] Suggested Focus
> 1. Unblock rate limiter (blocked on infra)
> 2. Finish auth migration — due today
> 3. Prep for 1:1 with Sarah
```

*+ with Atlassian MCP*: tasks with a `jira:` key get live Jira status annotated inline, and drift is flagged without touching your files:

```
> [!note] In Progress
> - [POE-1234] Migrate auth tokens  (Jira: In Review — local says in-progress ⚠️)
```

You know to consider `/jira-push` at end of day to resolve the drift.

---

## 08:45 — `/reminders`

Scans all tasks for urgency categories: overdue, due today, due soon (next 3 days), scheduled today, stale in-progress. With `macos_notifications: true`:

- **Overdue** — one notification per task (3 beeps each). Plus, for up to 3 overdue tasks, a three-button dialog pops: **Mark done** / **Snooze 1h** / **Dismiss**. Click *Mark done* and the task file is updated with `status: done` and `completedDate: <today>` — no typing.
- **Due today** — one notification per task (2 beeps).
- **Due soon** & **Stale** — one grouped notification each (1 beep).

The in-chat summary still prints even if you closed every dialog — notifications are additive.

---

## 09:00 — Standup meeting

Open `Scratch Pad.md` in your editor (or Obsidian). Jot during the meeting:

```
- standup: we're pushing auth migration to staging today
- Dave mentioned he's blocked on infra for rate limiter — escalate?
- met w/ design — decided to drop dark-mode toggle from v2.5
- POE-4567 needs a security review before ship
- follow up w/ Sarah re: Q2 plan
```

---

## 09:45 — `/enrich-tickets` → `/sync`

*+ with Atlassian MCP*: run `/enrich-tickets` **before** `/sync` so bare ticket keys get fleshed out:

```
- POE-4567 [Refactor rate limiter, in-progress, assigned to Dave] needs a security review before ship
```

Then:

```
/sync
```

Claude reads the Scratch Pad and proposes a filing plan. You confirm each bucket:

- **Tasks** — new task file for the security review (auto-inherits `jira: POE-4567`, `jira_url: …`, `created`, `type: task` since Obsidian is on).
- **Talking Points** — "Q2 plan" routed under `## Sarah` in `Talking Points.md`.
- **Meetings** — the standup and design meeting notes get summary files in `Meetings/` (with callouts and `[[Dave]]`, `[[Sarah]]` wikilinks).
- **Daily Notes** — today's `Daily Notes/2026-04-21.md` gets a Summary / Notes Processed / New Tasks section.
- **Scratch Pad** — cleared, with confirmation. Never silently.

> **Tip:** if you're unsure about the plan, run `/sync --preview` first. Identical plan output, zero writes. Edit the Scratch Pad and re-preview until it looks right.

---

## 10:00 — `/prep Sarah` (before the 1:1)

Quick context sheet: pending talking points for Sarah, last meeting note, recent log entries, any tasks that mention her. Two-minute read.

*+ with Unblocked MCP*: before `/prep`, you could run `/enrich-meeting Sarah` — it queries Unblocked for her recent PRs, Slack threads, and decisions, and appends an *Unblocked Context* block to her most recent meeting note. Then `/prep` picks it up automatically.

---

## 10:15 — 1:1 with Sarah

Dump takeaways into the Scratch Pad during / after:

```
- 1:1 with Sarah:
- she's thinking about rotating onto payments team in Q3, wants to talk career
- blocked on design review for search improvements — can I help unstick?
- action: I'll intro her to the payments TL
```

---

## 11:30 — `/sync` again

Because `track_contacts: true` and the meeting matches `recurring_meetings_label: 1:1`, Claude files this one under `People/Sarah/Meeting History/2026-04-21.md` instead of `Meetings/`. The career thread gets logged to `People/Sarah/log.md` with a dated entry — future `/prep Sarah` runs will surface it.

If you're a manager (you're not in this scenario), `/one-on-one-prep Sarah` would generate a structured prep sheet (Since last 1:1 / Open threads / Suggested topics / Growth prompts) pre-computed from her log, meeting history, tasks, and talking points.

---

## 14:00 — Ad-hoc task capture: `/task create`

Mid-afternoon Slack ping: "hey can you look at the retry-logic bug?"

```
/task "fix retry logic exceeding 5 attempts"
```

`/task` treats the non-verb first arg as a title. You confirm priority/due in the prompt, and a new task file lands in `Tasks/` with `status: open`, Obsidian frontmatter, and a Tasks-plugin checkbox line if `obsidian_tasks: true`.

---

## 15:45 — `/enrich-meeting "Design Review"`

*+ with Unblocked MCP*: pulls related PRs and decisions for the upcoming Design Review meeting, appends to its meeting note. The note has context before the meeting even starts.

---

## 16:00 — Design review meeting

Dump into Scratch Pad as usual.

---

## 17:15 — `/wrap-up`

The `Stop` hook has been watching the session. You've been at it 30+ min and edited files, so when you type `/wrap-up` (or the model nudges you), it:

1. **Catches stragglers** — anything still in the Scratch Pad from the design review gets processed.
2. **Task updates** — for every task you touched today, asks whether it moved forward (`open → in-progress`), got done (`status: done`, `completedDate: today`), or got blocked.
3. **Talking Points cleanup** — cross-references today's meetings; asks if Sarah's Q2-plan talking point can be cleared (it came up in the 1:1).
4. **Daily Note finalization** — appends *End of Day* and *Carry Forward* callouts to today's `Daily Notes/` file.
5. **Memory update** — writes a tight snapshot to `.claude/memory.md` so tomorrow's `/start` can scan it in 10 seconds. Replaces yesterday's carry-forward, not appends.

---

## 17:25 — optional `/jira-push`

*+ with Atlassian MCP*: remember the drift flag from `/start` this morning? Time to resolve it.

```
/jira-push
```

For every task with a `jira:` key, Claude compares local `status` against live Jira. You pick per task:

- **Push local → Jira** (update Jira to match your local task), or
- **Pull Jira → local** (update your task file to match Jira), or
- **Skip** (leave drift for later).

Never auto-pushes. Never auto-pulls.

---

## Close laptop

Everything is filed. Scratch Pad is empty. Memory is updated for tomorrow. The only UI state that matters is your todo list, and that lives in `Tasks/`.

---

## Cadences beyond the daily loop

### Weekly (Friday or Monday morning)

- **`/task archive`** — sweep `status: done` tasks older than 7 days into `Tasks/Archive/`. Keeps the live directory tight.
- **`/recap last week`** — manager 1:1 prep, status updates, or just your own reflection. Runs off local files; no MCP needed. Picks up Jira resolved-in-window tickets if Atlassian MCP is registered.

### Weekly (managers)

- **`/team-recap last week`** — per-direct-report summary: activity, blockers, 1:1 cadence health, anything stale. Runs only on contacts with `report: true` in their `log.md`.

### Monthly / per release (POs)

- **`/release-notes v2.5`** — bucket every task tagged `release: v2.5` into Shipped / In progress / Carryover. Always prints the source line (`local-only` vs. `local + Atlassian MCP`) so you know whether Jira enrichment ran.

---

## What the hooks are doing behind the scenes

You never invoke these — they run automatically in every Claude Code session.

- **`SessionStart`** — on startup/resume/clear, if cwd is a vault, injects the one-line reminder you saw at 08:30. Silent on non-vault dirs. Gated by `auto_start_suggestion: true` (default on).
- **`Stop`** — once per session, if you've been working 30+ min and edited `Scratch Pad.md` or any `Tasks/*.md`, nudges the model to suggest `/wrap-up` before you quit. One-shot per session.

Both write only `.claude/session-start.epoch` and `.claude/wrap-up-hinted` inside the current vault. No network, no MCP calls, no side effects anywhere else.

---

## Where Obsidian mode changes what you see

With `obsidian: true` set in your profile, the changes happen at write time:

- **Meeting notes** get `created` / `type: meeting` / `people: ["[[Name]]"]` frontmatter plus `> [!abstract]` callout sections.
- **Daily notes** get `type: daily-note` and urgency-matched callouts (`> [!abstract]`, `> [!check]`, `> [!success]`, `> [!attention]`).
- **Task files** get `created` / `type: task`. If `obsidian_tasks: true`, they also grow a Tasks-plugin checkbox line with priority emoji and due-date badge.
- **`/start` and `/reminders`** output uses callouts in chat that render nicely when you open today's daily note in Obsidian.
- **Graph view** — every `[[Name]]` wikilink builds edges between meetings, people, and tasks. Open the graph after a week and you'll see your network of conversations visualized.

Without `obsidian: true`, everything still works — just plain markdown sections, plain-text names, minimal frontmatter.

---

## Where MCPs change what you see

- **Atlassian MCP**: live Jira status in `/start` · `/jira-pull` · `/jira-push` · `/enrich-tickets` · optional enrichment in `/recap` and `/release-notes`.
- **Unblocked MCP**: `/enrich-meeting` — the only skill that requires it.
- **No MCPs at all**: every non-enrichment skill still works. Just no live Jira, no Unblocked context. You can add MCPs later — they start working on the next session; no reinstall.

Absent MCPs are never errors. Every MCP-gated skill surfaces a one-line warning pointing to `/doctor` and exits cleanly.
