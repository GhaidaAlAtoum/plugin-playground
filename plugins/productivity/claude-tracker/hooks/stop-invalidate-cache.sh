#!/usr/bin/env bash
# Stop hook — invalidate the statusline cost cache after each assistant response.
# Effect: the next statusline render sees stale cache, spawns a background refresh,
# and the bar updates with fresh cost numbers within ~5s.
# Never blocks the session. Exits silently even on error.

set -u

# Discard stdin — the Stop hook passes session JSON but we don't need it.
cat > /dev/null 2>&1 || true

CACHE_DIR="${TMPDIR:-/tmp}"

# Best-effort: delete both v1 (legacy) and v2 caches. Ignore errors.
rm -f \
  "$CACHE_DIR/claude-tracker-status.line" \
  "$CACHE_DIR/claude-tracker-status.v2.json" \
  2>/dev/null || true

exit 0
