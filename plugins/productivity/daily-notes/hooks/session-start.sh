#!/usr/bin/env bash
# SessionStart hook — if cwd looks like a daily-notes vault, nudge /start.
#
# Silent unless all gates pass:
#   1. cwd has both `Scratch Pad.md` and `Tasks/` (vault signature)
#   2. profile does not explicitly set `auto_start_suggestion: false`
#
# Also seeds `.claude/session-start.epoch` so the Stop hook can measure session
# length, and clears the one-shot wrap-up flag from any prior session.
#
# On success: emits a SessionStart JSON block that injects a short reminder as
# additional context. On any failure: exits 0 silently — hooks must never fail
# a session.
set -eu

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

# Vault signature gate.
[ -f "$cwd/Scratch Pad.md" ] || exit 0
[ -d "$cwd/Tasks" ] || exit 0

# Profile opt-out gate. Default is on — only skip on explicit `false`.
profile="${HOME}/.claude/CLAUDE.md"
if [ -f "$profile" ] && grep -qE '^[[:space:]]*-[[:space:]]*auto_start_suggestion:[[:space:]]*false' "$profile" 2>/dev/null; then
  exit 0
fi

# Seed session marker + clear wrap-up flag.
mkdir -p "$cwd/.claude"
date +%s > "$cwd/.claude/session-start.epoch" 2>/dev/null || true
rm -f "$cwd/.claude/wrap-up-hinted" 2>/dev/null || true

# Light vault stats for the hint.
scratch_bytes=0
if [ -f "$cwd/Scratch Pad.md" ]; then
  scratch_bytes=$(wc -c < "$cwd/Scratch Pad.md" 2>/dev/null | tr -d ' ' || echo 0)
fi

open_tasks=0
for f in "$cwd/Tasks/"*.md; do
  [ -f "$f" ] || continue
  if grep -qE '^status:[[:space:]]*(open|in-progress)' "$f" 2>/dev/null; then
    open_tasks=$((open_tasks + 1))
  fi
done

scratch_hint="empty"
if [ "$scratch_bytes" -gt 2 ]; then
  scratch_hint="has notes"
fi

msg="daily-notes vault detected in $cwd. ${open_tasks} open task(s), Scratch Pad ${scratch_hint}. Consider running /start for the morning standup, or /sync if the Scratch Pad already has content. To silence this nudge, set \`auto_start_suggestion: false\` in the Daily Notes Plugin Profile."

# Emit JSON on stdout. Escape double quotes and backslashes for JSON safety.
escaped=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
