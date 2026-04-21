---
description: Show Claude Code token usage and (API-equivalent) cost — current 5-hour window, today, this month, by model, by project. Use when the user asks "how much", "what did I spend", "usage", "tokens", or "cost" in a Claude Code context.
---

Run the claude-tracker core CLI and report the output to the user. The CLI does the log scanning, parsing, and math — you are just the presenter.

## Steps

1. Resolve the tracker_core path: `${CLAUDE_PLUGIN_ROOT}/tracker_core.py`. If `$CLAUDE_PLUGIN_ROOT` is unset (running outside the plugin context), fall back to `plugins/productivity/claude-tracker/tracker_core.py` relative to the marketplace root.

2. Choose scope based on user arguments:

   | User said | Flags to pass |
   |---|---|
   | *(no args, or "now", "current")* | `--window --json` (last 5h only) |
   | "today" | `--json` and filter entries by today's date |
   | "month" / "this month" / *(default detailed ask)* | `--json` (current month) |
   | "detail" / "by model" / "by project" / "breakdown" | add `--detail` |
   | "raw" / "all fields" | use `--json` and show the whole object |

   Run with `python3 <tracker_core.py> <flags>` via Bash.

3. Parse the JSON output. Present a compact answer first, then offer to drill in:

   - First line: cost + token totals, and the auth-mode label.
   - If auth_mode is `subscription`, append " (API equiv — your actual bill is the flat subscription fee)" the **first** time you mention the dollar figure in the conversation.
   - If auth_mode is `api_key`, present the figure as actual spend.
   - If auth_mode is `unknown`, note that briefly and suggest the user set `ANTHROPIC_API_KEY` or log in with `claude auth` if they want mode-aware labeling.

4. If the user asked for breakdown, show top 5 models and top 5 projects by cost. Sort descending. Format projects by trimming the leading `-Users-<name>-` prefix for readability if present.

5. If `pricing_last_verified` in the JSON is older than 90 days, mention it once ("pricing table last verified YYYY-MM-DD — verify against anthropic.com/pricing if precision matters").

6. Never print raw JSON unless the user asked for "raw" / "all fields".

## Sample output

**Short (default):**
> **Last 5h** — $22.31 equiv across 52 calls
> Tokens: 107 in · 108k out · 277k cache write · 2.6M cache read
> Top model: claude-opus-4-6

**With `--detail`:**
> **This month (2026-04)** — $719.33 equiv across 3,063 calls
>
> By model:
> - claude-opus-4-6      $397.81
> - claude-opus-4-7      $305.07
> - claude-haiku-4-5     $8.99
>
> By project (top 5):
> - CS7344               $261.00
> - plugin-playground    $228.24
> - Budgeting2026        $220.58
> - daily-notes-fresh    $4.43
> - temp                 $0.41

## Notes

- The number is **API-equivalent cost**, not your actual bill, unless you're on an API key. Claude Pro / Max / Team are flat-fee — the tracker is showing what this usage would cost on metered API pricing.
- Cache tokens (`cache_read`, `cache_write`) dominate Claude Code usage and are priced differently (cache read ≈ 0.1× input; cache write ≈ 1.25× input). The totals already account for these.
- Window = rolling 5 hours from now. This mirrors the Pro/Max/Team usage-window reset.
- If `python3` isn't found or the core script errors out, report the error verbatim and suggest running the core manually: `python3 <path> --json`.
