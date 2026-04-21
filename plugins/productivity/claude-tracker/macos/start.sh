#!/bin/bash
# Wrapper that launchd calls — finds uv and runs the menu bar app.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="menu_bar.py"
LOG_FILE="$HOME/claude_tracker_debug.log"

if [ -f "$HOME/.local/bin/uv" ]; then
    UV_BIN="$HOME/.local/bin/uv"
elif command -v uv >/dev/null 2>&1; then
    UV_BIN="$(command -v uv)"
else
    echo "Error: 'uv' not found. Install via https://docs.astral.sh/uv/" > "$LOG_FILE"
    exit 1
fi

cd "$SCRIPT_DIR" || exit 1
"$UV_BIN" run --python=3.12 "$SCRIPT_NAME" > "$LOG_FILE" 2>&1
