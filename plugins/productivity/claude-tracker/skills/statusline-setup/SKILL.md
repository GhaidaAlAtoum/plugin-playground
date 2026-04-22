---
description: Set up the claude-tracker v2 statusline (ccstatusline + colored context/5h bars). Use when the user says "set up statusline", "install statusline", "configure tracker bar", "new statusline", "statusline setup", or asks how to start using the tracker's statusline after installing/updating the plugin.
---

Walk the user through enabling the v2 statusline. The heavy lifting is done by `install-ccstatusline.sh`, which detects prerequisites, resolves a fast Python path (bypassing pyenv shims), renders a live sample, and — if ccstatusline already has claude-tracker widgets — refreshes their `commandPath` strings in place. Two flows:

- **First-time setup**: no existing config → script prints the commands and TUI steps; user builds the 3-line layout once.
- **Refresh after plugin/Python upgrade**: existing widgets are auto-patched in `~/.config/ccstatusline/settings.json` (backup written to `.bak`); no TUI re-paste needed, just restart Claude Code.

## Steps

1. Run the guided setup script. Use Bash:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/statusline/install-ccstatusline.sh"
   ```
   Show the full output to the user. If it ends with "You're done" they're on the refresh path — skip to step 6. Otherwise it printed first-time setup instructions (the commands to paste into the TUI); continue with steps 2–5.

2. Check the user's current `~/.claude/settings.json` to see whether `statusLine.command` still points at the v1 `claude-cost.sh` or is already updated. Read the file and report which state they're in.

3. If still on v1, offer to update it to:
   ```json
   "statusLine": {
     "type": "command",
     "command": "npx -y ccstatusline@latest",
     "padding": 0
   }
   ```
   Ask first — `~/.claude/settings.json` is user-owned and may contain other settings. Use the `update-config` skill if it's available in the session; otherwise edit carefully with the Edit tool.

4. Remind the user of the remaining manual step: launch `npx -y ccstatusline@latest` in their terminal to run the TUI and build the 3-line layout. Point them at `${CLAUDE_PLUGIN_ROOT}/statusline/SETUP-GUIDE.md` for the step-by-step walkthrough — it has text mockups of each TUI screen, the exact widget names to add per line, and the configuration values for each Custom Command widget (`preserveColors: true`, `timeout: 1000`, and the resolved absolute-Python `commandPath` that the install script already printed).

5. Point out the optional bits:
   - On a Team-plan laptop, they can add `SessionUsage` / `WeeklyUsage` widgets in the TUI to get quota-aware percentage displays.
   - `CLAUDE_CTX_LIMIT=<int>` env var overrides the per-model context limit if they want to track against a smaller budget.

6. After they restart Claude Code, suggest they run `/cost` to verify the aggregate numbers match what the new statusline shows.

## Notes

- The script only rewrites the `commandPath` of Custom Command widgets whose path already contains `render_segments.py`. Every other widget, every other field, and the rest of `~/.config/ccstatusline/settings.json` are left untouched. A `.bak` is written before any change.
- Don't make ad-hoc manual edits to `~/.config/ccstatusline/settings.json` — re-opening the TUI will overwrite them. If the auto-patch doesn't cover something, change it in the TUI.
- If the setup script fails a prerequisite check (missing `npx` or `python3`), help the user install Node/Python rather than trying to work around it.
- The old v1 `claude-cost.sh` script stays in place through v0.4.x for migration safety — no rush to remove it from the other machine.
