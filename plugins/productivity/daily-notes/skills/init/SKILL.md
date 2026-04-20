---
description: Interactive first-run setup — scaffolds the notes folder, writes the profile block, and gets you from zero to running /start without touching the shell
---

Interactive onboarding. Scaffolds the notes folder tree, creates the starter files, and writes the Daily Notes Plugin Profile block into the user's `~/.claude/CLAUDE.md`. Idempotent — detects existing vault and offers reuse.

## Hard constraint

Do **not** prompt for, install, or configure any MCP server (Atlassian, Unblocked, Google Calendar). These are user-owned Claude Code configs. This skill only mentions them as optional future add-ons with a link to the relevant docs.

## Steps

1. **Detect existing vault**: Check the current working directory and `~/Documents/notes` for these signals:
   - `Scratch Pad.md` at the root
   - `.claude/memory.md`
   - `Tasks/`, `Meetings/`, `Daily Notes/` folders
   - `## Daily Notes Plugin Profile` block in `~/.claude/CLAUDE.md`

   If 2+ signals match, say: "Found an existing vault at `<path>`. Reuse it, or scaffold a fresh one at a different location?" and branch accordingly. Default answer: **reuse**.

2. **Choose location**: If scaffolding fresh, ask: "Where should I put your notes?" Default: `~/Documents/notes`. Accept any absolute or tilde-expanded path. Confirm the expanded absolute path back to the user before writing.

3. **Collect profile fields** (ask one at a time, offer defaults so a user can hit enter through most):
   - **Display name** (free text) — used in standup output only.
   - **Role** (one of `ic` / `manager` / `po`, or free text) — used by role-gated skills in Phase 4+. Default: `ic`.
   - **Track per-person contacts?** (y/n) — enables `People/` routing. Default: **y**.
     - If y: **Contacts folder name** (default `People`).
     - If y: **Recurring meeting label** (default `1:1`).
   - **macOS notifications for /reminders?** (y/n) — uses `osascript`. Default: **y**. Note: "macOS will prompt for Apple Events permission the first time — that's expected."
   - **Obsidian vault?** (y/n) — enables callout/wikilink output. Default: **n**.
     - If y: **Obsidian Tasks plugin installed?** (y/n) for emoji task syntax. Default: **n**.

   Do **not** ask about `gcal`, Atlassian, or Unblocked here. These require MCP configs the user owns separately.

4. **Scaffold the folder tree**: Create at the chosen location (skip any that already exist — never overwrite):
   ```
   <notes-root>/
     Scratch Pad.md          (seeded with a one-liner header if missing)
     Talking Points.md       (seeded with `# Talking Points`)
     Tasks/
     Meetings/
     Daily Notes/
     People/                 (only if track_contacts == y; use chosen name)
     .claude/
       memory.md             (see step 5)
   ```

   Show the tree to the user and ask for confirmation **before** running any `mkdir`/file writes.

5. **Seed `.claude/memory.md`**: Write a minimal starter:
   ```markdown
   # Working Memory

   _Your /start skill will scan this each morning. Keep it tight — this is for the next session, not a diary._

   ## Active threads
   - (none yet — your first /wrap-up will populate this)

   ## Carry forward
   - (none yet)
   ```

6. **Write the profile block to `~/.claude/CLAUDE.md`**:
   - Read existing `~/.claude/CLAUDE.md`. If a `## Daily Notes Plugin Profile` section already exists, show the user the existing block and the new one side-by-side, ask `overwrite / merge / keep existing`. Never silently overwrite.
   - If no file, create it. Append (or insert, if overwriting) the block:
     ```markdown
     ## Daily Notes Plugin Profile
     - display_name: <name>
     - role: <ic|manager|po|other>
     - track_contacts: <true|false>
     - contacts_folder: <name>                  # only if track_contacts
     - recurring_meetings_label: <label>        # only if track_contacts
     - macos_notifications: <true|false>
     - obsidian: <true|false>
     - obsidian_tasks: <true|false>             # only if obsidian
     ```
     Only include fields the user actually configured — omit the rest so defaults apply.

7. **Optional-MCP pointer (informational only)**: Print once, do not prompt:
   ```
   Optional integrations (configure separately, not required):
   • Atlassian MCP  → unlocks /jira-pull, /jira-push, /enrich-tickets, adaptive /start Jira block
   • Unblocked MCP  → unlocks /enrich-meeting
   • Google Calendar MCP + `gcal: true` in profile → unlocks /calendar, /meeting-reminder,
                                                     adaptive /start agenda block
   None are installed by this plugin. See your Claude Code settings to add MCPs.
   Run /doctor any time to see which integrations are currently available.
   ```

8. **Final next step**: Tell the user exactly one command to run next:
   ```
   ✅ Setup complete. Open Claude Code in this folder and run:

     cd <notes-root>
     claude
     /start
   ```
   If they're already `cd`'d into the notes-root, just show `/start` as the next step.

## Rules

- Ask before every file-write and every directory create. Show the plan, then execute on confirmation. Never overwrite existing files.
- Idempotent: running `/init` a second time must not destroy content. Detect existing files → offer reuse or a suffix.
- Never prompt for MCP credentials, tokens, or URLs. Step 7 is read-only guidance.
- Keep the conversation short — this is a scaffold, not a wizard. 8 questions max.
