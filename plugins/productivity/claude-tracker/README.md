# claude-tracker

Track Claude Code usage — tokens, cost (API-equivalent), cache-token accounting, and rolling-window progress. Works for API-key, Pro, Max, and Team plans with **plan-aware labeling** so subscription users aren't misled by a dollar figure that isn't their actual bill.

Three surfaces, one shared core:

| Component | What it does | Where it lives |
|---|---|---|
| **`/cost` slash command** | On-demand breakdown — by model, by project, window / today / month | `skills/cost/SKILL.md` |
| **Statusline v2** *(recommended)* | 3-line ambient display with colored context + 5h-block bars via `ccstatusline` | `statusline/render_segments.py` |
| **Statusline v1** *(legacy)* | Compact one-line cost + 5h window | `statusline/claude-cost.sh` |
| **Stop hook** *(auto)* | Refreshes the statusline after each assistant response | `hooks/stop-invalidate-cache.sh` |
| **macOS menu bar** *(optional)* | Rolling cost in your menu bar, always on | `macos/menu_bar.py` |

All four share `tracker_core.py` — pure stdlib Python, reads `~/.claude/projects/**/*.jsonl` (and OpenCode logs if present).

---

## Install

1. Install the marketplace if you haven't already:
   ```bash
   claude plugin marketplace add ghaidaatoum/plugin-playground
   ```
2. `/plugin install claude-tracker@plugin-playground`
3. Restart Claude Code.

The `/cost` skill and Stop hook are active immediately. The statusline requires one more step (below). The macOS menu bar app is optional.

### Wire the statusline v2 (recommended)

The v2 statusline uses [`ccstatusline`](https://www.npmjs.com/package/ccstatusline) as the layout engine and plugs in our threshold-colored context + 5h-block bars via its Custom Command widget.

**From inside Claude Code:** just ask — e.g. "set up the statusline" — and the `/statusline-setup` skill will run the guided setup, read your current `~/.claude/settings.json`, and offer to update it for you.

**Or run the script directly:**

```bash
<path-to-plugin>/statusline/install-ccstatusline.sh
```

Then follow **[`statusline/SETUP-GUIDE.md`](statusline/SETUP-GUIDE.md)** for the step-by-step TUI walkthrough (what to click, what to paste, expected preview at each step).

It verifies prerequisites (`python3`, `npx`), renders a live sample, and prints the exact TUI steps and the three `--segment` commands to paste into `ccstatusline`.

Summary of what you'll do:
1. Set `~/.claude/settings.json` → `statusLine.command` to `"npx -y ccstatusline@latest"` with `padding: 0`.
2. Run `npx -y ccstatusline@latest` to launch the TUI.
3. Build a 3-line layout with built-in widgets + three `CustomCommand` widgets invoking `render_segments.py --segment ctx|block|month`.

### Legacy statusline (v0.1.x)

If you're still on the one-line `claude-cost.sh`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<path-to-plugin>/statusline/claude-cost.sh",
    "padding": 1
  }
}
```

This path is preserved through v0.2.x for migration safety. Scheduled removal in v0.3.0.

### Install the macOS menu bar (optional)

```bash
cd <path-to-plugin>/macos
./install.sh
```

Uninstall: `./uninstall.sh` from the same directory.

Requires [`uv`](https://docs.astral.sh/uv/) and Python 3.11+. The app installs as a user LaunchAgent (`~/Library/LaunchAgents/com.user.claudetracker.plist`) and starts at login.

---

## Plan compatibility

This is the thing most cost trackers get wrong. Your plan determines what the dollar number **means**.

| Plan | How you're billed | What the tracker shows |
|---|---|---|
| **API key** (`ANTHROPIC_API_KEY` set) | Per-token | Actual cost. Match against Anthropic Console. |
| **Pro / Max (personal)** | Flat monthly fee | API-equivalent cost labeled `eq` — what this usage *would* cost on metered API. Your actual bill is the subscription. |
| **Team** | Flat per-seat fee | Same as Pro/Max. Logs are per-user per-machine, so the tracker shows **your** usage only. Admin-level team aggregation still lives in Anthropic Console. |

Detection is heuristic:
- `ANTHROPIC_API_KEY` in env → `api_key`
- `~/.claude/.credentials.json` exists (non-empty) → `subscription`
- otherwise → `unknown`

We **do not read credential file contents.** The plugin never touches your API key or OAuth token — only checks whether the file exists.

---

## Cache tokens — why the number is higher than you expected

Claude Code caches heavily. On a typical month, cache tokens dominate:

```
input: 275k   output: 2.1M   cache_write: 22.9M   cache_read: 174M
```

The tracker prices these correctly:
- `cache_creation_input_tokens` → input price × **1.25** (cache write cost)
- `cache_read_input_tokens` → input price × **0.1** (cache read is cheap but not free)

If you're comparing to an older tracker that ignored cache tokens, expect this number to be **meaningfully higher** — and more accurate.

---

## `/cost` usage

```
/cost                # last 5 hours
/cost month          # current month
/cost detail         # current month, broken down by model + project
/cost raw            # full JSON dump
```

---

## Statusline output

### v2 (ccstatusline-based)

```
~/plugin-playground  ⎇ main (+2,-1)
Opus 4.7  ·  Session 12m  ·  Ctx ▓▓▓▓▓░░░░░ 52% (104K/1M)
5h ▓▓▓░░░░░░░ 2h14m left · $71.98  ·  💰 $769.45 mo
```

- **Context bar** fills per-model (Opus/Sonnet: 1M, Haiku: 200K, or `CLAUDE_CTX_LIMIT` env override). Green < 70%, yellow 70-89%, red ≥ 90%.
- **5h bar** tracks time elapsed in the current Anthropic 5h billing block. Block cost shown next to remaining time.
- **💰 month** is current-month-to-date. Subscription users see `$X.XX eq` suffix — a reminder this is API-equivalent, not your actual bill.

### v1 (legacy)

```
💬 $719.33 │ 5h $22.31
```

Month cost on the left, last-5-hours cost on the right. Same `eq` suffix rule applies.

---

## Verifying pricing

`pricing.json` has a `last_verified` date. The tracker warns when that date is more than 90 days old. To re-verify: check [anthropic.com/pricing](https://www.anthropic.com/pricing), update the JSON, bump `last_verified`.

---

## Limitations

- **Tier (Pro / Max / Team) is not auto-detected.** Anthropic doesn't expose it locally. v2 statusline works on any plan; team-plan quota widgets (SessionUsage / WeeklyUsage) are opt-in via the ccstatusline TUI.
- **v1 window is wall-clock "last 5 hours."** v2 detects Anthropic's actual 5h billing block by walking transcript timestamps.
- **Per-user attribution on Team is not supported** — logs are per-machine. The tracker shows *your* usage only.
- **OpenCode logs** are parsed if present at `~/.local/share/opencode/log/`, but model detection on OpenCode's format is approximate.

---

## Privacy

Everything is local. No network calls. No data leaves your machine. The plugin reads:
- `~/.claude/projects/**/*.jsonl` (usage logs, no message content needed for counting)
- Cache files at `$TMPDIR/claude-tracker-status.v2.json` (v2) and `$TMPDIR/claude-tracker-status.line` (v1 legacy)
- Optional `~/.local/share/opencode/log/*.log`

It does **not** read `~/.claude/.credentials.json` contents (only checks existence).

---

## License

MIT — see repo root `LICENSE`.
