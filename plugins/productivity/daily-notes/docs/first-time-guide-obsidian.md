# First-time guide — daily-notes with Obsidian

This is the fastest path from zero to a daily-notes vault with Obsidian's graph view, backlinks, and Dataview dashboards wired in.

**Time needed:** ~10 minutes (5 for daily-notes, 5 for Obsidian).

If you don't use Obsidian (or don't want to install it), follow [`first-time-guide.md`](first-time-guide.md) instead — you can always enable Obsidian later.

---

## Before you start

You need:

- **Claude Code** installed and logged in — [install docs](https://docs.anthropic.com/en/docs/claude-code)
- **Obsidian** installed — [obsidian.md](https://obsidian.md). Free for personal use.
- **A folder** where your notes will live. Default is `~/Documents/notes`.

Nothing in this plugin is Obsidian-specific — the files are plain Markdown. Obsidian just adds a powerful viewer on top.

---

## Step 1 — Install the plugin

```
claude plugin marketplace add ghaidaatoum/plugin-playground
```

Then:

```
/plugin
```

Install **daily-notes** from the **Discover** tab.

---

## Step 2 — Run `/init` (say YES to Obsidian)

```
/init
```

Hit enter to accept defaults where you're unsure. Key answers for the Obsidian path:

| Question | Answer |
|---|---|
| Where should I put your notes? | `~/Documents/notes` (or your path) |
| Display name | Your first name |
| Role | `ic`, `manager`, `po`, or free text |
| Track per-person contacts? | **y** (Obsidian's graph view shines with wikilinks) |
| Contacts folder | `People` (default) |
| Recurring meeting label | `1:1` (default) |
| macOS notifications? | **y** if on a Mac |
| **Obsidian vault?** | **y** ← this guide |
| **Obsidian Tasks plugin installed?** | **n** for now — we'll install it in Step 4. Re-run `/init` or edit your profile after. |

Your profile in `~/.claude/CLAUDE.md` will end up with:

```markdown
## Daily Notes Plugin Profile
- display_name: Alex
- role: ic
- track_contacts: true
- contacts_folder: People
- recurring_meetings_label: 1:1
- macos_notifications: true
- obsidian: true
```

---

## Step 3 — Open the folder as an Obsidian vault

1. Launch **Obsidian**.
2. On the welcome screen: **Open folder as vault**.
3. Pick the folder `/init` created (e.g. `~/Documents/notes`).
4. Trust the vault when prompted.

Obsidian will index the folder in a second or two. You'll see `Scratch Pad.md`, `Talking Points.md`, and the subfolders in the left sidebar.

---

## Step 4 — Install the required / recommended plugins

In Obsidian: **Settings → Community plugins → Browse**.

| Plugin | Required? | Why |
|---|---|---|
| **Dataview** | Yes | Powers the `Dashboard.md` this plugin generates (open tasks, due today, recent meetings). |
| **Periodic Notes** | Recommended | Weekly/monthly/quarterly note templates. |
| **Calendar** | Recommended | Sidebar calendar that links to daily notes. |
| **Tasks** | Optional | Needed only if you want `📅 ⏫ 🔼` emoji syntax inside task files. |

Install, then **enable** each one under Community plugins.

If you installed **Tasks**, update your profile in `~/.claude/CLAUDE.md` to add:

```markdown
- obsidian_tasks: true
```

---

## Step 5 — Run `/obsidian-setup`

Back in Claude Code:

```
cd ~/Documents/notes        # or wherever your vault is
claude
/obsidian-setup
```

This one-time scaffold creates:

- **`Dashboard.md`** — Dataview queries for open tasks by priority, due today, recent meetings, this week's daily notes.
- **`Templates/Daily Note.md`** — compatible with Obsidian's built-in Daily Notes / Periodic Notes plugins.
- **`Templates/Meeting Note.md`** — callout sections pre-filled.
- **In-chat guidance** for any recommended plugins you haven't enabled yet.

Open `Dashboard.md` in Obsidian after this runs — you'll see your live task/meeting views.

---

## Step 6 — Verify with `/doctor`

```
/doctor
```

Confirms: folder structure ✓, profile fields ✓ (including `obsidian: true`), which MCPs are detected. Re-run any time something feels off.

---

## Step 7 — Your first morning

```
/start
```

With `obsidian: true`, the output uses callouts (`> [!warning]`, `> [!tip]`) instead of plain bullet lists — you'll see them render nicely in Obsidian if you open today's daily note after.

---

## Step 8 — The core habit: dump → sync

In Obsidian (or any editor), open **`Scratch Pad.md`** and jot down anything throughout the day:

```
- fix login bug on staging
- follow up w/ Sarah about Q2 plan
- met w/ design team — decided to drop dark-mode toggle for now
- idea: retry logic should cap at 3 attempts
```

After a meeting or at end of day:

```
/sync
```

With `obsidian: true` enabled, `/sync` writes:

- **`[[Sarah]]` wikilinks** instead of plain-text names → graph-view edges appear
- **Callouts** (`> [!abstract] Summary`, `> [!warning] Blockers`) in meeting and daily notes
- **`created: YYYY-MM-DD`** and **`type: meeting`** frontmatter → Dataview can query these fields
- If `obsidian_tasks: true`: emoji task lines (`- [ ] fix login bug 📅 2026-04-25 ⏫`) appended in task files

> **Tip:** run `/sync --preview` first to see the plan without writing anything.

---

## Step 9 — Watch the graph build

Open **Graph view** in Obsidian (left sidebar → graph icon, or `⌘+G`). After a few syncs with people mentions, you'll see a live graph:

- daily notes linked to meetings
- meetings linked to people
- people linked to tasks that mention them

This is the payoff of Obsidian mode over plain markdown — a navigable web that grows itself as you work.

---

## Step 10 — End of day

```
/wrap-up
```

Reviews the day, prompts for wins and blockers, finalizes the daily note (with callouts if `obsidian: true`).

Once a week:

```
/task archive        # sweep done tasks older than 7 days
```

---

## Your file layout

```
~/Documents/notes/              ← opened as Obsidian vault
├── Dashboard.md                # Dataview queries (live)
├── Scratch Pad.md              # inbox
├── Talking Points.md           # grouped by person, [[wikilinks]]
├── Templates/
│   ├── Daily Note.md
│   └── Meeting Note.md
├── Tasks/
│   └── fix-login-bug.md        # with created, type, optional emoji
├── Meetings/
│   └── 2026-04-20 Standup.md   # with callouts + [[wikilinks]]
├── Daily Notes/
│   └── 2026-04-20.md
└── People/
    └── Sarah/
        ├── Meeting History/
        │   └── 2026-04-18.md
        └── log.md
```

---

## Daily rhythm at a glance

```
Morning       /start             → callouts: focus, overdue, nudges
              /reminders         → native macOS alerts if enabled

During day    edit Scratch Pad.md (in Obsidian or any editor)
              /task create       → gains created/type frontmatter
              /prep <name>       → pulls [[Name]] log + meeting history
              /talking-points    → agenda check

After meeting /sync              → writes wikilinks, callouts

End of day    /wrap-up           → closes out with callouts

Weekly        /task archive
```

---

## Common pitfalls (Obsidian edition)

- **Don't edit `Dashboard.md` manually.** It's Dataview queries — rewrite them only if you know Dataview syntax. Regenerate via `/obsidian-setup`.
- **If `[[wikilinks]]` don't resolve**, check that the target file name matches exactly (e.g. `[[Sarah]]` needs `People/Sarah/` folder or `People/Sarah.md`). Obsidian is case-sensitive by default.
- **If the Tasks plugin emojis look wrong**, make sure both `obsidian: true` and `obsidian_tasks: true` are in your profile *and* the Tasks community plugin is enabled in Obsidian.
- **Don't manually sort the Scratch Pad.** That's `/sync`'s job.
- **If Dataview queries return nothing**, Dataview needs to reindex — **Settings → Community plugins → Dataview → Force refresh**, or restart Obsidian once.

---

## What's next

- **See the full rhythm** — [`day-in-the-life.md`](day-in-the-life.md) walks through one weekday end-to-end, showing every skill in context (with Obsidian callouts highlighted).
- **Pull from Jira / enrich meetings** — install the companion `notes-integrations` plugin for live Jira status, `/jira-pull`, `/enrich-meeting`, and recap reports. Works the same in Obsidian or plain markdown vaults. Setup: [`../../notes-integrations/docs/setup-guide.md`](../../notes-integrations/docs/setup-guide.md).
- **Role-specific skills** — manager? Set `role: manager` to unlock `/one-on-one-prep` and `/team-recap`. See [`README.md`](../README.md#role-specific-workflows).
- **Shortcuts.app recipes** — one-tap standup / quick-note from the menu bar. See [`shortcuts/README.md`](../shortcuts/README.md).
- **Periodic Notes** — set up weekly and monthly notes in the Obsidian plugin settings, pointing at `Templates/Daily Note.md` as a base.

For the full reference, see [`README.md`](../README.md), [`CLAUDE.md`](../CLAUDE.md), and the [role profile reference](role-profile-reference.md).
