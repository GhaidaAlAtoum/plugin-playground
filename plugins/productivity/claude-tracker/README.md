# claude-tracker

Track Claude Code usage — tokens, cost (API-equivalent), cache-token accounting, and rolling-window progress. Works for API-key, Pro, Max, and Team plans with **plan-aware labeling** so subscription users aren't misled by a dollar figure that isn't their actual bill.

Three surfaces, one shared core:

| Component | What it does | Where it lives |
|---|---|---|
| **`/cost` slash command** | On-demand breakdown — by model, by project, window / today / month | `skills/cost/SKILL.md` |
| **Statusline** | Compact ambient cost + 5-hour window in the Claude Code status bar | `statusline/claude-cost.sh` |
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

### Wire the statusline (optional, recommended)

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<path-to-plugin>/statusline/claude-cost.sh",
    "padding": 1
  }
}
```

Replace `<path-to-plugin>` with the absolute path — e.g. `~/.claude/plugins/claude-tracker` if installed from the marketplace. The script is self-caching: the bar reads an on-disk snapshot instantly and refreshes in the background every 30 seconds.

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

```
💬 $719.33 │ 5h $22.31
```

Month cost on the left, current-5h-window cost on the right. Subscription users see `$719.33 eq` (the `eq` suffix is your reminder that this is API-equivalent, not your bill).

---

## Verifying pricing

`pricing.json` has a `last_verified` date. The tracker warns when that date is more than 90 days old. To re-verify: check [anthropic.com/pricing](https://www.anthropic.com/pricing), update the JSON, bump `last_verified`.

---

## Limitations

- **Tier (Pro / Max / Team) is not auto-detected.** Anthropic doesn't expose it locally. Future work: a config option for manual tier declaration + a cap-progress bar.
- **Window reset time is wall-clock "last 5 hours"**, not the exact Anthropic reset moment. Close enough for most purposes; can be refined if Anthropic exposes reset state via API.
- **Per-user attribution on Team is not supported** — logs are per-machine. The tracker shows *your* usage only.
- **OpenCode logs** are parsed if present at `~/.local/share/opencode/log/`, but model detection on OpenCode's format is approximate.

---

## Privacy

Everything is local. No network calls. No data leaves your machine. The plugin reads:
- `~/.claude/projects/**/*.jsonl` (usage logs, no message content needed for counting)
- Cache file at `$TMPDIR/claude-tracker-status.line`
- Optional `~/.local/share/opencode/log/*.log`

It does **not** read `~/.claude/.credentials.json` contents (only checks existence).

---

## License

MIT — see repo root `LICENSE`.
