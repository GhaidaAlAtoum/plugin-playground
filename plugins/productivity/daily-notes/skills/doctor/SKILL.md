---
description: Health check — verifies folder structure, profile fields, and reports which optional MCPs are currently available. Detects only; never installs or modifies MCP config
---

Run a diagnostic check against the user's notes vault and global profile. Report what's working, what's missing, and how to fix each issue.

## Hard constraint

This skill **detects** MCP availability — it never registers, installs, or modifies any MCP config. Absent MCPs are reported as "unavailable, feature X will not work" — never as an error.

## Checks

Run each check, collect results, and emit a single report at the end. Do not ask questions mid-check.

### 1. Folder structure (required)
Current working directory should be a notes vault. Verify:
- `Scratch Pad.md` exists and is readable/writable
- `Talking Points.md` exists
- `Tasks/`, `Meetings/`, `Daily Notes/` directories exist

For each missing item, record a fix: `Run /init to scaffold.` or `Create manually: touch <path>`.

### 2. Profile block (required)
Read `~/.claude/CLAUDE.md`. Verify:
- A `## Daily Notes Plugin Profile` section exists.
- The section parses as bullet-list key/value pairs (e.g. `- display_name: Alice`).
- If `track_contacts: true`: `contacts_folder` and `recurring_meetings_label` are set.
- If `obsidian_tasks: true`: `obsidian: true` is also set (obsidian_tasks is a sub-flag).
- If `macos_notifications: true`: platform is macOS (check via `uname -s` == `Darwin`).

For each problem, record the specific field + fix.

### 3. Memory file (optional)
Check `.claude/memory.md`:
- Exists? If not, note it's optional but `/wrap-up` will create it.
- Parses? (Can be any markdown — just confirm it's not empty or binary.)

### 4. MCP availability (informational — never a hard error)

Detect which MCPs are registered in the current Claude Code session. Use whichever method works:
- Check the session's tool list for names matching `*atlassian*`, `*jira*`, `*unblocked*`.
- If the session exposes an MCP list (e.g. via a meta tool or env var), use it.

Report one line per integration with status `✓ available` or `✗ not configured`:
```
Atlassian MCP     ✓ available          → /jira-pull, /jira-push, /enrich-tickets, /start Jira block
Unblocked MCP     ✗ not configured     → /enrich-meeting (unavailable)
```

### 5. osascript permission (if `macos_notifications: true`)
Attempt a benign `osascript -e 'return "ok"'` call. If it errors (permission denied, not on macOS), record: "macOS Events permission needed — open System Settings → Privacy & Security → Automation → grant Claude Code access to System Events." If `macos_notifications: false` or unset, skip this check entirely.

### 6. Plugin pairing
Check whether `notes-integrations` is also installed in the current Claude Code session (look for its skill names in the tool list: `recap`, `jira-pull`, etc.). Report: installed / not installed. This is informational — `daily-notes` works alone.

### 7. Statusline wiring (informational — absent wiring is not an error)
The daily-notes statusline is opt-in. Check three things:

1. **`~/.claude/settings.json`** — does it contain a top-level `statusLine.command` field, and does that command path end with `daily-notes-status.sh` inside a `statusline/` directory? If no → report `✗ statusline not wired` with the fix: `Run /init to opt in, or manually add a "statusLine" block to ~/.claude/settings.json (see statusline/README.md).`
2. **Script exists and is executable** — if `settings.json` points to a path but the file does not exist or is not executable, report `⚠ statusline script path in settings.json points to <path> which is missing or not executable`. Fix: reinstall the plugin, or run `chmod +x <path>`.
3. **Profile mode** — read the Daily Notes Plugin Profile. Is `statusline_mode` set to one of `quiet`, `focus`, `off`? If missing but wiring is present, report: `Advisory: statusline wired but statusline_mode not set — defaulting to quiet. Add "- statusline_mode: quiet" (or "focus"/"off") to your profile to make this explicit.`
4. **Dry-run smoke test** — pipe a minimal fake session JSON to the script inside the current vault:
   ```bash
   echo '{"session_id":"doctor-dryrun"}' | <script-path>
   ```
   Check exit code 0 and that stdout is under 120 chars. Report one of:
     - `✓ statusline wired (<mode> mode) — dry-run produced: <line>`
     - `⚠ statusline dry-run exited non-zero` — include stderr (first 3 lines). Fix: `Re-run with "bash -x <script-path> < /dev/null" to trace, or open an issue.`

Dry-run must not modify any file outside `.claude/statusline-cache.*.json`. The cache write is acceptable — it's scoped to the vault's housekeeping directory.

## Report format

Emit one of these shapes:

**All green:**
```
## Doctor — all clear ✅

Vault:        /Users/.../notes
Profile:      ok (display_name: Alice, role: manager, track_contacts: true, …)
Memory:       present
macOS events: ok
Statusline:   ✓ wired (quiet mode) — dry-run: 📓

Integrations
  Atlassian       ✓ available
  Unblocked       ✗ not configured

Plugins
  daily-notes        ✓
  notes-integrations ✓

Notes: You're fully set up. Absent integrations are optional — see /init output for how to add them.
```

**Has issues:**
```
## Doctor — 3 issues ⚠️

Critical
  1. Tasks/ directory missing at /Users/.../notes
     Fix: `mkdir -p "/Users/.../notes/Tasks"` or re-run /init

  2. Profile block missing `recurring_meetings_label` (track_contacts is true)
     Fix: Add `- recurring_meetings_label: 1:1` under ## Daily Notes Plugin Profile in ~/.claude/CLAUDE.md

Integrations detected
  Atlassian       ✗ not configured   → Jira skills unavailable
  Unblocked       ✓ available
```

## Rules

- Read-only. Never write, modify, or delete any file during `/doctor`.
- Do not prompt the user during checks — run them all, report once.
- Absent MCPs are **never** errors.
- If `uname -s` is not `Darwin`, skip check 5 entirely and note: "Non-macOS detected — skipping osascript check. The `macos_notifications` feature is macOS-only."
