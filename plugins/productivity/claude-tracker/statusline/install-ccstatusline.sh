#!/usr/bin/env bash
# Guided setup for the v2 statusline (ccstatusline + claude-tracker renderer).
#
# Behavior:
#   - First-time users: advisory. Checks prerequisites, prints the three
#     commandPath strings to paste into the ccstatusline TUI.
#   - Upgrade/refresh: if ~/.config/ccstatusline/settings.json already has
#     claude-tracker custom-command widgets, rewrites their commandPath
#     in-place (backing up to .bak first) so users don't have to re-paste
#     after a plugin version bump. Leaves ~/.claude/settings.json alone.

set -u

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RENDERER="$SCRIPT_DIR/render_segments.py"

say() { printf '%b\n' "$*"; }

say "${BOLD}claude-tracker statusline v2 — setup${RESET}"
echo

# --- 1. prerequisites ----------------------------------------------------

missing=0
# Resolve the fastest python3: bypass pyenv shims (they add ~1s per invocation
# because they rehash on every call). Prefer direct interpreter paths.
resolve_python() {
  if command -v pyenv >/dev/null 2>&1; then
    local p
    p=$(pyenv which python3 2>/dev/null) && { echo "$p"; return; }
  fi
  for cand in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    [[ -x "$cand" ]] && { echo "$cand"; return; }
  done
  command -v python3 2>/dev/null || echo ""
}

# Ask the interpreter itself for its canonical path. sys.executable always
# points to the real binary, even if we invoked it through a pyenv shim —
# so this dereferences any shim in one step. We do this because shims add
# ~1s per invocation and will exceed ccstatusline's 1000ms timeout.
dereference_shim() {
  local candidate="$1"
  [[ -z "$candidate" ]] && return
  local real
  real=$("$candidate" -c 'import sys; print(sys.executable)' 2>/dev/null)
  if [[ -n "$real" && -x "$real" ]]; then
    echo "$real"
  else
    echo "$candidate"
  fi
}

PYTHON_BIN="$(resolve_python)"
if [[ -z "$PYTHON_BIN" ]]; then
  say "${RED}✗${RESET} python3 not found"
  missing=1
else
  if [[ "$PYTHON_BIN" == */shims/* ]]; then
    original="$PYTHON_BIN"
    PYTHON_BIN="$(dereference_shim "$original")"
    if [[ "$PYTHON_BIN" == */shims/* || -z "$PYTHON_BIN" ]]; then
      say "${RED}✗${RESET} python3 resolved to a pyenv shim ($original) and dereference failed"
      say "  Fix: run ${BOLD}pyenv which python3${RESET} yourself, confirm the result is not under /shims/, and pass that path manually"
      missing=1
    else
      say "${GREEN}✓${RESET} python3: $PYTHON_BIN ${DIM}(dereferenced from shim $original)${RESET}"
    fi
  else
    say "${GREEN}✓${RESET} python3: $PYTHON_BIN"
  fi
fi

if ! command -v npx >/dev/null 2>&1; then
  say "${RED}✗${RESET} npx not on PATH — install Node.js to continue"
  missing=1
else
  say "${GREEN}✓${RESET} npx: $(command -v npx)"
fi

if [[ ! -f "$RENDERER" ]]; then
  say "${RED}✗${RESET} renderer script missing: $RENDERER"
  missing=1
else
  say "${GREEN}✓${RESET} renderer: $RENDERER"
fi

if [[ $missing -ne 0 ]]; then
  echo
  say "${RED}Fix the missing prerequisites above, then rerun.${RESET}"
  exit 1
fi

# --- 2. smoke test renderer ---------------------------------------------

echo
say "${BOLD}Rendering a live sample${RESET} ${DIM}(Ctx segment)${RESET}"
sample_transcript=$(ls -t "$HOME/.claude/projects"/*/*.jsonl 2>/dev/null | head -1)
if [[ -n "$sample_transcript" ]]; then
  stdin_json=$(printf '{"model":"claude-opus-4-7","transcript_path":"%s"}' "$sample_transcript")
  echo "$stdin_json" | "$PYTHON_BIN" "$RENDERER" --segment ctx
  echo
else
  say "${YELLOW}!${RESET} no transcripts under ~/.claude/projects/*/*.jsonl — skipping live sample"
fi

# --- 3. auto-patch existing ccstatusline widgets ------------------------
#
# If the user already built the 3-line layout in a previous session, their
# Custom Command widgets have stale commandPaths after a plugin upgrade
# (marketplace installs include the version segment) or a Python upgrade.
# Rewrite just those widgets' commandPath — preserve every other field and
# every other widget. Back up to .bak before writing.

CCSTATUS_CONFIG="$HOME/.config/ccstatusline/settings.json"
widgets_patched=0
widgets_found=0
if [[ -f "$CCSTATUS_CONFIG" ]]; then
  echo
  say "${BOLD}Checking existing ccstatusline config${RESET} ${DIM}($CCSTATUS_CONFIG)${RESET}"
  patch_output=$("$PYTHON_BIN" - "$CCSTATUS_CONFIG" "$PYTHON_BIN" "$RENDERER" <<'PY'
import json, os, re, shutil, sys

config_path, python_bin, renderer = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(config_path) as f:
        data = json.load(f)
except Exception as e:
    print(f"ERR: could not parse {config_path}: {e}", file=sys.stderr)
    sys.exit(2)

found = 0
updated = 0
for line in data.get("lines", []):
    if not isinstance(line, list):
        continue
    for widget in line:
        if not isinstance(widget, dict):
            continue
        if widget.get("type") != "custom-command":
            continue
        cmd = widget.get("commandPath", "")
        if "render_segments.py" not in cmd:
            continue
        found += 1
        # Preserve everything after render_segments.py (--segment X and any extras).
        m = re.search(r"render_segments\.py(\s+.*)?$", cmd)
        trailing = (m.group(1) or "") if m else ""
        new_cmd = f"{python_bin} {renderer}{trailing}"
        if cmd != new_cmd:
            updated += 1
            widget["commandPath"] = new_cmd

if updated:
    shutil.copy2(config_path, config_path + ".bak")
    tmp = config_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, config_path)

# Output: "<found> <updated>"
print(f"{found} {updated}")
PY
)
  patch_rc=$?
  if [[ $patch_rc -ne 0 ]]; then
    say "${YELLOW}!${RESET} could not auto-patch config — falling back to manual instructions below"
  else
    widgets_found="${patch_output% *}"
    widgets_patched="${patch_output#* }"
    widgets_found="${widgets_found:-0}"
    widgets_patched="${widgets_patched:-0}"
    if [[ "$widgets_patched" -gt 0 ]]; then
      say "${GREEN}✓${RESET} Refreshed ${BOLD}${widgets_patched}${RESET} claude-tracker widget(s) in place."
      say "  ${DIM}Backup: ${CCSTATUS_CONFIG}.bak${RESET}"
    elif [[ "$widgets_found" -gt 0 ]]; then
      say "${GREEN}✓${RESET} Found ${widgets_found} claude-tracker widget(s), all already up-to-date."
    else
      say "${DIM}No claude-tracker widgets found — showing first-time setup steps.${RESET}"
    fi
  fi
fi

# --- 4. setup instructions ----------------------------------------------

if [[ "$widgets_patched" -gt 0 || "$widgets_found" -gt 0 ]]; then
  echo
  if [[ "$widgets_patched" -gt 0 ]]; then
    say "${BOLD}You're done.${RESET} Restart Claude Code to pick up the refreshed statusline."
  else
    say "${BOLD}Nothing to do.${RESET} Your ccstatusline config already points at the current install."
  fi
  say "  ${DIM}(No TUI re-paste needed. If the statusline still shows dim dashes after restart,${RESET}"
  say "  ${DIM} run ${BOLD}npx -y ccstatusline@latest${RESET}${DIM} and verify each Custom Command widget.)${RESET}"
  exit 0
fi

echo
say "${BOLD}Next steps${RESET}"
echo
say "1. ${BOLD}Update ~/.claude/settings.json${RESET} — set statusLine.command to:"
say "   ${DIM}-----${RESET}"
cat <<'EOF'
   "statusLine": {
     "type": "command",
     "command": "npx -y ccstatusline@latest",
     "padding": 0
   }
EOF
say "   ${DIM}-----${RESET}"
echo
say "2. ${BOLD}Launch the ccstatusline TUI${RESET}:"
say "   ${DIM}$ npx -y ccstatusline@latest${RESET}"
echo
say "3. ${BOLD}Build a 3-line layout${RESET}:"
say "   Line 1: CurrentWorkingDir · GitBranch · GitChanges"
say "   Line 2: Model · ThinkingEffort · SessionClock · ${BOLD}CustomCommand${RESET} (ctx segment)"
say "   Line 3: ${BOLD}CustomCommand${RESET} (block segment) · ${BOLD}CustomCommand${RESET} (session segment)"
echo
say "   ${DIM}ThinkingEffort is a ccstatusline built-in (Category: Core) — shows the${RESET}"
say "   ${DIM}current thinking level (low/medium/high/max). No Custom Command needed.${RESET}"
echo
say "4. ${BOLD}For each CustomCommand widget${RESET}, set:"
say "   - ${BOLD}preserveColors${RESET}: true"
say "   - ${BOLD}timeout${RESET}: 1000"
say "   - ${BOLD}commandPath${RESET}: one of the three commands below"
echo
say "   ${DIM}ctx segment${RESET}"
say "     $PYTHON_BIN $RENDERER --segment ctx"
echo
say "   ${DIM}block segment${RESET}"
say "     $PYTHON_BIN $RENDERER --segment block"
echo
say "   ${DIM}session segment${RESET}"
say "     $PYTHON_BIN $RENDERER --segment session"
echo
say "5. ${DIM}(Optional, Team plan)${RESET} add SessionUsage / WeeklyUsage widgets."
echo
say "Your config is saved to ${DIM}~/.config/ccstatusline/settings.json${RESET}."
say "Restart Claude Code to see the new statusline."
