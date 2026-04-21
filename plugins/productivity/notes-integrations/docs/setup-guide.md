# Setup guide — notes-integrations

The fastest path from zero to using `notes-integrations` end-to-end. This guide works the same whether your vault is plain markdown or an Obsidian vault — the plugin itself is Obsidian-agnostic.

**Time needed:** ~5 minutes (plus any MCP setup, which is separate).

---

## Before you start

- **`daily-notes` must be installed and initialized first.** `notes-integrations` reads and writes the same `Tasks/`, `Meetings/`, and `Scratch Pad.md` files. If you haven't run `daily-notes`' `/init` yet, do that first — see [`daily-notes/docs/first-time-guide.md`](../../daily-notes/docs/first-time-guide.md) (plain) or [`daily-notes/docs/first-time-guide-obsidian.md`](../../daily-notes/docs/first-time-guide-obsidian.md) (Obsidian). Come back here after.
- **Claude Code** installed and logged in.
- **Optional but recommended:** at least one MCP from the list below. Two of the six skills work with zero MCPs.

---

## Step 1 — Install the plugin

```
claude plugin marketplace add ghaidaatoum/plugin-playground
```

Then:

```
/plugin
```

Install **notes-integrations** from the **Discover** tab. (If `daily-notes` isn't installed yet, install it first — the marketplace entry enforces the dependency.)

---

## Step 2 — Connect the MCPs (optional but recommended)

The plugin **does not bundle any MCP server** — it only detects which ones you already have configured in your Claude Code session. Each MCP is independent; enable only the ones you want.

| MCP | Unlocks | Without it |
|---|---|---|
| **Atlassian** | `/jira-pull`, `/jira-push`, `/enrich-tickets`, live Jira status in `/start` | These skills surface a one-line warning and exit |
| **Unblocked** | `/enrich-meeting` | `/enrich-meeting` surfaces a one-line warning and exits |
| *(none)* | `/recap`, `/release-notes` still work fully local-only | — |

Add MCPs via your Claude Code settings. Anthropic's MCP docs: <https://docs.anthropic.com/en/docs/claude-code/mcp>. When they're registered in your session, the skills below pick them up automatically — no reinstall needed.

---

## Step 3 — Verify with `/doctor`

```
cd <your-vault>
claude
/doctor
```

`/doctor` is in `daily-notes` — it reports which MCPs `notes-integrations` sees in the current session:

```
Integrations
  Atlassian       ✓ available
  Unblocked       ✗ not configured
```

Absent MCPs are never errors — the matching skills simply stay unavailable. Re-run `/doctor` any time something feels off.

---

## Step 4 — First pull: `/jira-pull`

*(Skip this step if you don't have the Atlassian MCP.)*

```
/jira-pull
```

Fetches your assigned open/in-progress Jira issues and proposes one task file per ticket. Confirms each before writing. Skips any ticket that already has a file in `Tasks/`.

```
Tasks/POE-1234 — migrate-auth-tokens.md   ← created
Tasks/POE-1235 — update-api-docs.md       ← created
Tasks/POE-1200 — fix-login-bug.md         ← skipped (already exists)
```

Each new task file includes `jira:` and `jira_url:` frontmatter fields so `/start`, `/jira-push`, and `/release-notes` can link back.

---

## Step 5 — The enrichment flow

Two patterns that slot into your `daily-notes` rhythm. Both are opt-in — run them when you want the extra context.

### `/enrich-tickets` → `/sync`

Run this **before `/sync`** when your Scratch Pad has bare ticket keys in it:

```
Scratch Pad.md:
- POE-4567 needs a security review
- follow up w/ Sarah re: rollback plan
```

```
/enrich-tickets
```

Finds bare keys like `POE-4567` in `Scratch Pad.md`, fetches title/status/description from Jira, and enriches each reference in place after you confirm:

```
Scratch Pad.md:
- POE-4567 [Refactor rate limiter, in-progress] needs a security review
- follow up w/ Sarah re: rollback plan
```

Then `/sync` routes the enriched notes normally. The ticket context flows through to your Tasks and Daily Notes.

### `/enrich-meeting` before `/prep <name>`

Run this **before a 1:1 or meeting** when you want Unblocked's context (recent PRs, Slack threads, decisions) pulled into the meeting note:

```
/enrich-meeting Sarah
```

Queries Unblocked for Sarah — PRs from the last 7 days, Slack threads from the last 3 days, any decisions tagged to her. Appends a block to her most recent meeting note:

```markdown
## Unblocked Context — Sarah (2026-04-21)

**Related PRs** *(last 7 days)*
- PR #892: Refactor session storage — merged last week

**Decisions / Background**
- Auth token storage must use encrypted store per legal review (2026-03-15)
```

Pass a window to go deeper — useful for quarterly reviews or first 1:1s:

```
/enrich-meeting Sarah 30d
```

Then run `/prep Sarah` as usual — the enriched meeting note gets included automatically.

---

## Step 6 — Reports (no MCP required)

These two skills always run off local files. An Atlassian MCP just adds canonical titles and URLs when available; without it, the reports use whatever's in your local task frontmatter.

### `/recap`

```
/recap last week
/recap last month
/recap 2026-01-01 to 2026-03-31
```

Aggregates your Daily Notes, Meetings, and Tasks across the window. Useful for status emails, manager 1:1s, and quarterly reviews.

### `/release-notes`

```
/release-notes v2.4              # label mode — all tasks with `release: v2.4`
/release-notes last month         # window mode — any task done/active in the range
```

Buckets tasks into **Shipped / In progress / Carryover**. Always prints which source ran (`local-only` vs. `local + Atlassian MCP`) so you know whether enrichment happened.

Tag tasks by adding `release: v2.4` to their frontmatter — `/task create` accepts a label when you mention one ("add this for v2.4").

---

## Step 7 — Keeping Jira in sync: `/jira-push`

When your local task statuses have drifted from Jira (you closed something locally but forgot to push; Jira moved a ticket you still have as in-progress):

```
/jira-push
```

Scans every task with a `jira:` key, fetches live Jira status, and shows drift per task:

```
[POE-123] Fix login bug
Local: done | Jira: In Progress

Which is correct?
1. Push local → Jira  (update Jira to "Done")
2. Pull Jira → local  (update local task to "in-progress")
3. Skip this task
```

Never auto-updates either side — you pick.

---

## Works with Obsidian?

Yes. This plugin doesn't touch Obsidian config — it only reads and writes plain markdown. When your vault has `obsidian: true` set in the Daily Notes Plugin Profile, enriched meeting notes and updated tasks inherit callouts and `[[wikilinks]]` from the `daily-notes` writer skills automatically. No extra setup for Obsidian users.

---

## Common pitfalls

- **MCP not configured → skill exits cleanly, not silently.** Every MCP-gated skill surfaces the standard warning: *"⚠️  Atlassian MCP not available — /jira-pull needs live Jira access. Run /doctor to diagnose."* Follow the pointer; no data is lost.
- **Ticket keys must be ALL-CAPS.** `/enrich-tickets` looks for `[A-Z]+-[0-9]+` patterns. Lowercase keys like `poe-1234` won't be detected.
- **Label matching on `/release-notes` is case-sensitive and exact.** `v2.4` ≠ `V2.4`. If your report comes back empty, check your frontmatter casing.
- **`/jira-push` never auto-pushes.** Every drift is shown one at a time and requires a choice. You can abort at any prompt.
- **`/recap` and `/release-notes` always work.** If you're ever unsure whether an MCP is flaky, use these — they degrade cleanly to local-only mode.

---

## What's next

- **See the full rhythm end-to-end** — [`daily-notes/docs/day-in-the-life.md`](../../daily-notes/docs/day-in-the-life.md) shows one weekday with every skill in context, including where `notes-integrations` adds value.
- **Architecture & MCP wiring** — [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the flowcharts and Jira status mapping.
- **daily-notes reference** — [`../../daily-notes/README.md`](../../daily-notes/README.md) for the core skill palette.
