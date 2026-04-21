# First-time guide — daily-notes (plain markdown)

This is the fastest path from zero to a working daily-notes vault. No Obsidian, no extra apps — just Claude Code and a folder of `.md` files you can open in any editor.

**Time needed:** ~5 minutes.

If you *do* want Obsidian's backlinks, graph view, and Dataview dashboards, follow [`first-time-guide-obsidian.md`](first-time-guide-obsidian.md) instead.

---

## Before you start

You need:

- **Claude Code** installed and logged in — [install docs](https://docs.anthropic.com/en/docs/claude-code)
- **A folder** where your notes will live. Default is `~/Documents/notes`. Pick anywhere you like — `/init` will create it for you.

That's it. No database, no cloud sync, no account to create.

---

## Step 1 — Install the plugin

In any Claude Code session, run:

```
claude plugin marketplace add ghaidaatoum/plugin-playground
```

Then open the marketplace UI:

```
/plugin
```

Go to the **Discover** tab and install **daily-notes**.

---

## Step 2 — Run `/init`

```
/init
```

`/init` walks you through 6–8 short questions. Hit enter to accept defaults on anything you're unsure about — you can change it later by editing `~/.claude/CLAUDE.md`.

When it asks:

| Question | Answer |
|---|---|
| Where should I put your notes? | `~/Documents/notes` (default) or your own path |
| Display name | Your first name |
| Role | `ic`, `manager`, `po`, or free text — affects nudges only |
| Track per-person contacts? | **y** if you have recurring 1:1s with teammates, **n** otherwise |
| macOS notifications? | **y** if you want `/reminders` to pop native alerts |
| Obsidian vault? | **n** ← this guide |
| Enable statusline? | **y** (shows overdue + scratch-pad signals in Claude Code's bar) |
| Statusline mode | `quiet` (default) or `focus` (always-on counters) |

When it finishes, it will print a one-line "next step" and `cd` instructions.

---

## Step 3 — Verify with `/doctor`

```
cd ~/Documents/notes    # or wherever you put your notes
claude
/doctor
```

`/doctor` prints:

- folder structure ✓
- profile fields ✓
- which optional MCPs are detected (none needed for this guide — Atlassian / Unblocked are optional upgrades)

If anything is flagged, it also gives you exact fix steps. Re-run `/doctor` any time something feels off.

---

## Step 4 — Your first morning

```
/start
```

On a fresh vault this will mostly say "no tasks yet, Scratch Pad is empty, have a good one." That's expected.

---

## Step 5 — The core habit: dump → sync

This is the only workflow you need to memorize.

**Throughout the day**, open `Scratch Pad.md` in your editor (VS Code, TextEdit, `vim`, whatever) and jot down anything:

```
- fix login bug on staging
- follow up w/ Sarah about Q2 plan
- met w/ design team — decided to drop the dark-mode toggle for now
- idea: retry logic should cap at 3 attempts, not 5
```

**After meetings (or end of day)**, run:

```
/sync
```

Claude reads the Scratch Pad and files everything:

- action items → `Tasks/<name>.md`
- agenda items for specific people → `Talking Points.md`
- meeting notes → `Meetings/YYYY-MM-DD Meeting.md`
- today's summary → `Daily Notes/YYYY-MM-DD.md`

It will ask before clearing the Scratch Pad, so nothing gets lost.

> **Tip:** if you want to see what `/sync` *would* do without writing anything, run `/sync --preview` first. It prints the plan and leaves every file untouched.

---

## Step 6 — Capture a task directly

Anytime you want a task without going through the Scratch Pad:

```
/task create
/task "fix login bug"          # first arg isn't a verb → title
/task list high                 # list open high-priority tasks
/task update                    # move one forward
/task archive 14                # archive done tasks older than 14 days
```

---

## Step 7 — Before a meeting

```
/prep Sarah
```

Pulls: pending talking points for Sarah, open items from her last meeting, recent contact log entries, and any tasks that mention her.

---

## Step 8 — End of day

```
/wrap-up
```

Reviews what got done, asks for wins and blockers, and finalizes today's daily note.

Once a week:

```
/task archive        # sweep completed tasks older than 7 days
```

---

## Your file layout

After a week of use your notes folder will look like:

```
~/Documents/notes/
├── Scratch Pad.md              # inbox — always comes back to empty after /sync
├── Talking Points.md           # grouped by person
├── Tasks/
│   ├── fix-login-bug.md
│   └── review-q2-plan.md
├── Meetings/
│   └── 2026-04-20 Standup.md
├── Daily Notes/
│   ├── 2026-04-20.md
│   └── 2026-04-21.md
└── People/                     # only if track_contacts: true
    └── Sarah/
        ├── Meeting History/
        │   └── 2026-04-18.md
        └── log.md
```

Every file is plain Markdown. Open in any editor. Back up with git, iCloud, Dropbox — whatever you already use.

---

## Daily rhythm at a glance

```
Morning       /start             → what's on my plate
              /reminders         → anything overdue

During day    edit Scratch Pad.md (inbox)
              /task create       → capture a discrete task
              /prep <name>       → 2 min before a 1:1
              /talking-points    → agenda check

After meeting /sync              → file everything

End of day    /wrap-up           → close out, log the day

Weekly        /task archive      → sweep done tasks
```

---

## Common pitfalls (read once, save yourself a week)

- **Don't manually sort the Scratch Pad.** That's `/sync`'s job. The whole point is that you dump and it sorts.
- **Don't edit `Daily Notes/` by hand.** They're the output of `/sync` and `/wrap-up`. If you want to add context, put it in the Scratch Pad first.
- **Don't skip `/sync`.** If the Scratch Pad grows past a screen, `/sync` has more to sift through and the plan gets harder to eyeball. Aim for once a day.
- **If `/start` feels noisy**, adjust `statusline_mode` or turn off `auto_start_suggestion` in your profile (`~/.claude/CLAUDE.md`).

---

## What's next

- **Role-specific skills** — if you're a manager, set `role: manager` + `track_contacts: true` to unlock `/one-on-one-prep` and `/team-recap`. See [`README.md`](../README.md#role-specific-workflows).
- **Shortcuts.app recipes** — one-tap "morning standup" and "quick note" triggers from the menu bar. See [`shortcuts/README.md`](../shortcuts/README.md).
- **Try Obsidian later** — your notes are already compatible. When you're ready, set `obsidian: true` in your profile and run `/obsidian-setup`. Guide: [`first-time-guide-obsidian.md`](first-time-guide-obsidian.md).

For the full reference, see [`README.md`](../README.md) and [`CLAUDE.md`](../CLAUDE.md).
