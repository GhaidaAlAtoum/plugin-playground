#!/usr/bin/env bash
# Guided setup for the v2 statusline (ccstatusline + claude-tracker renderer).
#
# This script is advisory: it doesn't touch ~/.claude/settings.json or
# ~/.config/ccstatusline/settings.json directly. It checks prerequisites
# and prints the exact commands and widget config to paste into the
# ccstatusline TUI.

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

# --- 3. setup instructions ----------------------------------------------

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
say "   Line 2: Model · SessionClock · ${BOLD}CustomCommand${RESET} (ctx segment)"
say "   Line 3: ${BOLD}CustomCommand${RESET} (block segment) · ${BOLD}CustomCommand${RESET} (month segment)"
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
say "   ${DIM}month segment${RESET}"
say "     $PYTHON_BIN $RENDERER --segment month"
echo
say "5. ${DIM}(Optional, Team plan)${RESET} add SessionUsage / WeeklyUsage widgets."
echo
say "Your config is saved to ${DIM}~/.config/ccstatusline/settings.json${RESET}."
say "Restart Claude Code to see the new statusline."
