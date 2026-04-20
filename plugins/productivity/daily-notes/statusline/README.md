# daily-notes statusline

An ambient signal for the Claude Code status bar. Shows whether your notes vault has anything urgent, without you having to run a single skill.

The bar only does anything inside a vault (cwd has `Scratch Pad.md` + `Tasks/`). Outside a vault it prints nothing — your bar stays whatever it was.

---

## Install

The easiest path is `/init` — when you first set up daily-notes, it offers to wire the statusline for you and writes the profile field.

**If you already ran `/init`** and want to add the statusline after the fact, or prefer to do it by hand:

1. Add to `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "<absolute-path-to-repo>/plugins/productivity/daily-notes/statusline/daily-notes-status.sh",
       "padding": 1
     }
   }
   ```
   Replace `<absolute-path-to-repo>` with the actual path (find it with `pwd` from inside the plugin folder).

2. Add one line to your Daily Notes Plugin Profile in `~/.claude/CLAUDE.md`:
   ```markdown
   - statusline_mode: quiet
   ```
   (Or `focus` for ADHD mode — see below.)

3. Make sure the script is executable:
   ```bash
   chmod +x <absolute-path-to-repo>/plugins/productivity/daily-notes/statusline/daily-notes-status.sh
   ```

4. Restart Claude Code, or open a new session inside your notes vault.

Run `/doctor` to confirm everything is wired correctly.

---

## Modes

| Mode | Who it's for | Behavior |
|---|---|---|
| `quiet` *(default)* | At-a-glance reassurance. Most users. | Only surfaces when something needs attention. Clean vault = `📓`. |
| `focus` *(opt-in — "ADHD mode")* | Users who want persistent visibility of core counts, even when they're at zero. Helpful when "out of sight, out of mind" leads to missed work. | Always shows overdue + due-today counts, even `🔴0 🟠0`. Adds stale in-progress and scratch-dirty when present. |
| `off` | You've wired the script but want to disable it temporarily. | Script exits without printing. Bar is blank. |

Change modes by editing the `statusline_mode:` line in `~/.claude/CLAUDE.md`. No restart needed.

---

## What each icon means

Icons should be self-evident, but here's the canonical legend for reference:

| Icon | Meaning | When it appears |
|---|---|---|
| 📓 | daily-notes is alive in this vault | Always in both modes (while cwd is a vault). |
| 🔴N | Overdue tasks | `🔴N` where N > 0 in quiet; always in focus (including `🔴0`). |
| 🟠N | Due today | Focus mode only. Always shown. |
| ⏸N | Stale in-progress (>5 days since last edit) | Focus mode only. Shown only if N > 0. |
| 📝 | Scratch Pad has content beyond the seeded header | Both modes. Nudges you to run `/sync`. |

### Example states

**Quiet mode:**
```
📓                  (clean vault, nothing pending)
📓 🔴3              (3 overdue tasks)
📓 📝               (scratch pad has content to sync)
📓 🔴3 📝           (both)
                    (empty — cwd is not a vault)
```

**Focus / ADHD mode:**
```
📓 🔴0 🟠0          (steady state — persistent reassurance that counts are tracked)
📓 🔴0 🟠2          (two due today)
📓 🔴3 🟠5 ⏸2 📝    (a bad day — three flavors of urgency + dirty scratch)
                    (empty — cwd is not a vault)
```

---

## How it works

- Runs after each assistant message (Claude Code debounces at 300ms).
- Reads `Scratch Pad.md` and the `Tasks/` directory. Never calls a network service.
- Caches per-session in `.claude/statusline-cache.<session_id>.json` inside the vault. On cache hit it just prints the cached line — no file scan.
- Cache invalidates on `Tasks/` dir mtime change, `Scratch Pad.md` mtime change, or after 10 seconds (safety TTL for filesystems that don't bump directory mtimes on inner-file changes).

**Measured performance** (macOS, bash 3.2, M-series):
- Cache hit: ~85ms at any vault size (mostly bash startup — the script itself does almost no work on hit).
- Cache miss, 10 tasks: ~150ms.
- Cache miss, 150 tasks: ~125ms (single `awk` pass — scales sub-linearly with task count).

All well under Claude Code's 300ms debounce, so updates feel instant.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Bar is blank even inside a vault | Script not executable, or script path in `settings.json` is wrong | `chmod +x <path>`; run `/doctor` — it dry-runs the script and reports the exact problem. |
| Bar shows raw `{session_id:...}` or errors | Claude Code is printing stderr from the script | Run the script manually: `echo '{"session_id":"test"}' \| /absolute/path/to/daily-notes-status.sh`. Check exit code + stderr. |
| Bar flickers between states every second | `refreshInterval` set too low in `settings.json`, or cache is being invalidated every run | Remove `refreshInterval` (the default — update on assistant message — is correct). If mtimes are changing constantly, something is touching the vault files (a sync tool, an editor save loop). |
| Icons render at different widths in different terminals | Emoji width is terminal-dependent (iTerm2, Terminal.app, VS Code terminal, Warp all render differently) | The script keeps icon counts *within a mode* stable to minimize jitter. If one terminal is unusable, test with focus-mode → if `🔴0 🟠0` stays stable it's a font issue, try a different terminal font (e.g. MesloLGS NF, JetBrains Mono). |
| Bar updates but never clears when vault is clean | Cache file stuck with stale content | Delete `.claude/statusline-cache.*.json` in the vault. Script rebuilds the cache on the next update. |
| `/doctor` reports `statusline dry-run exited non-zero` | Shell error inside the script | Re-run with tracing: `bash -x ./daily-notes-status.sh < /dev/null`. First non-zero exit line is the bug. File an issue with the output. |

---

## Design principles

If you're extending this script (PRs welcome), keep these non-negotiable:

1. **Local only.** No network, no MCP calls, no shelling out to `gh` / `jira` / anything that hits an API. The bar runs on every assistant message — an API call here will get your account rate-limited.
2. **Stable icon count within a mode.** Emoji widths vary across terminals; adding and removing icons causes the bar to jitter visually. Quiet-mode icons are "show only when non-zero" *by design* — that's the quiet contract. Focus mode shows `🔴N` and `🟠N` always, for the same reason: stability over density.
3. **Empty stdout = blank bar.** Never print an error message, a stack trace, or "broken" text. If something is wrong, print nothing; `/doctor` is where errors surface.
4. **Cache-or-die.** Do not add a signal that can't be cached via mtime. Anything that changes mid-session without a file touching is probably a network call in disguise.
5. **Fail silent.** Any error path exits 0 with empty stdout. The Claude Code UI must never see a non-zero exit from this script.

---

## Out of scope

- Meeting-countdown signal (`⏰ 14:00 Sync w/ Sarah`) — requires a Google Calendar MCP plus 5-minute caching. Tracked for v2.
- "Focus task" display (`▶ <task name>`) — needs a writer skill to set the focus, not shipped yet.
- Role-specific signals (manager-only stale-report count, PO-only release-label count) — kept out of v1 so the bar has one shape for everyone. Revisit once there's usage data.
