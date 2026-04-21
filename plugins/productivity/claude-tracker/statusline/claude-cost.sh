#!/usr/bin/env bash
# claude-tracker statusline — compact cost + window progress.
#
# Reads session JSON from stdin (ignored), writes one line to stdout, exits 0.
# Empty stdout = blank bar (never crash the UI).
#
# Design: log scans take ~1–2s so we NEVER block the statusline on them.
#   - Cache in ~/.claude/.cache/claude-tracker-status.line (plain text, one line).
#   - If cache is stale (> TTL seconds), spawn tracker_core.py in background
#     to refresh for the next render.
#   - Always print whatever's in the cache right now — even if slightly stale.

set -u

# Discard stdin without forking (prevents broken pipe from upstream).
cat > /dev/null 2>&1 || true

TTL_SECONDS=30

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE="$SCRIPT_DIR/../tracker_core.py"
CACHE_DIR="$HOME/.claude/.cache"
CACHE_FILE="$CACHE_DIR/claude-tracker-status.line"
LOCK_FILE="$CACHE_DIR/claude-tracker-status.lock"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

now=$(date +%s 2>/dev/null || echo 0)
cache_mtime=0
if [[ -f "$CACHE_FILE" ]]; then
  cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
fi
age=$(( now - cache_mtime ))

# If cache is stale AND no refresh lock, spawn a background refresh.
if [[ $age -ge $TTL_SECONDS && ! -f "$LOCK_FILE" ]]; then
  (
    touch "$LOCK_FILE" 2>/dev/null
    month_json=$(python3 "$CORE" --json 2>/dev/null) || month_json=""
    window_json=$(python3 "$CORE" --window --json 2>/dev/null) || window_json=""
    python3 - "$CACHE_FILE" "$month_json" "$window_json" <<'PY' 2>/dev/null
import json, os, sys, tempfile
cache_path, month_raw, window_raw = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    m = json.loads(month_raw) if month_raw else {}
    w = json.loads(window_raw) if window_raw else {}
except json.JSONDecodeError:
    sys.exit(1)
suffix = "" if m.get("auth_mode") == "api_key" else " eq"
line = f"💬 ${m.get('cost', 0):,.2f}{suffix} │ 5h ${w.get('cost', 0):,.2f}"
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(cache_path) or ".", prefix=".tracker-status.")
with os.fdopen(fd, "w") as f:
    f.write(line)
os.replace(tmp, cache_path)
PY
    rm -f "$LOCK_FILE" 2>/dev/null
  ) &
  disown 2>/dev/null || true
fi

# Print whatever's cached. If nothing cached yet, print a placeholder.
if [[ -f "$CACHE_FILE" ]]; then
  printf '%s' "$(< "$CACHE_FILE")"
else
  printf '💬 …'
fi
exit 0
