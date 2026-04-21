#!/usr/bin/env bash
# Stop hook — invalidate the statusline cost cache after each assistant response.
# Effect: the next statusline render sees stale cache, spawns a background refresh,
# and the bar updates with fresh cost numbers within ~5s.
# Never blocks the session. Exits silently even on error.

set -u

# Discard stdin — the Stop hook passes session JSON but we don't need it.
cat > /dev/null 2>&1 || true

CACHE_FILE="${TMPDIR:-/tmp}/claude-tracker-status.line"

# Best-effort: delete, ignore errors (cache may not exist yet, or may be locked).
rm -f "$CACHE_FILE" 2>/dev/null || true

exit 0
