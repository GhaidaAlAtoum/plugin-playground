#!/usr/bin/env bash
# Stop hook — once per session, if the user has been working for 30+ minutes
# and touched `Scratch Pad.md` or any `Tasks/*.md`, remind them to /wrap-up
# before the conversation ends.
#
# Fires at most once per session via the `.claude/wrap-up-hinted` flag (cleared
# by the SessionStart hook). Uses `decision: "block"` with a short reason so
# Claude surfaces the nudge to the user; the flag guarantees the nudge is
# not spammed on every subsequent turn.
#
# Silent unless all gates pass:
#   1. cwd has both `Scratch Pad.md` and `Tasks/` (vault signature)
#   2. `.claude/session-start.epoch` exists and elapsed >= 30 min
#   3. one-shot flag `.claude/wrap-up-hinted` not yet set
#   4. Scratch Pad.md OR any Tasks/*.md modified since session start
set -eu

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

[ -f "$cwd/Scratch Pad.md" ] || exit 0
[ -d "$cwd/Tasks" ] || exit 0

flag="$cwd/.claude/wrap-up-hinted"
ts_file="$cwd/.claude/session-start.epoch"

[ -f "$flag" ] && exit 0
[ -f "$ts_file" ] || exit 0

start=$(cat "$ts_file" 2>/dev/null || echo 0)
[ "$start" -gt 0 ] 2>/dev/null || exit 0

now=$(date +%s)
elapsed=$((now - start))

# 30 minutes.
[ "$elapsed" -ge 1800 ] || exit 0

# mtime helper — macOS `stat -f %m`, fall back to GNU `stat -c %Y`.
mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

touched=""
if [ "$(mtime "$cwd/Scratch Pad.md")" -gt "$start" ] 2>/dev/null; then
  touched="Scratch Pad"
fi

for f in "$cwd/Tasks/"*.md; do
  [ -f "$f" ] || continue
  if [ "$(mtime "$f")" -gt "$start" ] 2>/dev/null; then
    touched="${touched:+$touched, }Tasks"
    break
  fi
done

[ -n "$touched" ] || exit 0

# One-shot: fire and lock.
touch "$flag" 2>/dev/null || true

mins=$((elapsed / 60))
reason="You've been in this session for ${mins} min and have edits in ${touched}. Before ending, suggest the user run /wrap-up to close out the daily note and review open tasks. Mention this once and then let the session end normally if the user declines."

escaped=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"decision":"block","reason":"%s"}\n' "$escaped"
exit 0
