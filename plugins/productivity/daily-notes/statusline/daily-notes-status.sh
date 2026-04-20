#!/usr/bin/env bash
# daily-notes statusline — ambient vault signals for Claude Code.
# Reads session JSON from stdin, writes one line to stdout, exits 0.
# Empty stdout = blank bar (our clean failure mode — never crash the UI).
#
# Design: this script runs on every assistant message (Claude Code debounces at
# 300ms), so we avoid forking where possible. Almost everything below uses bash
# builtins: [[ =~ ]], parameter expansion, read loops, $(< file). External forks
# are limited to stat (for mtimes) and date (today's ISO date), and even those
# are skipped on cache hit.

set -u
shopt -s nullglob

# ---- read stdin (no fork) ----
stdin=""
while IFS= read -r _line; do
  stdin+="$_line"
done

# ---- extract session_id (bash regex, no fork) ----
session_id="nosid"
if [[ "$stdin" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  session_id="${BASH_REMATCH[1]}"
fi

# ---- vault detection ----
[[ -f "Scratch Pad.md" ]] || exit 0
[[ -d "Tasks" ]] || exit 0

# ---- profile: read once, extract mode (no fork) ----
profile="$HOME/.claude/CLAUDE.md"
mode="quiet"
if [[ -f "$profile" ]]; then
  in_block=0
  while IFS= read -r _line; do
    if [[ "$_line" == "## Daily Notes Plugin Profile" ]]; then
      in_block=1
      continue
    fi
    if [[ $in_block -eq 1 && "$_line" == "## "* ]]; then
      break
    fi
    if [[ $in_block -eq 1 && "$_line" =~ ^[[:space:]]*-[[:space:]]*statusline_mode:[[:space:]]*([a-zA-Z]+) ]]; then
      mode="${BASH_REMATCH[1]}"
    fi
  done < "$profile"
fi
case "$mode" in
  quiet|focus|off) ;;
  *) mode="quiet" ;;
esac
[[ "$mode" == "off" ]] && exit 0

# ---- mtimes (2 forks — required for cache check) ----
scratch_mtime=$(stat -f %m "Scratch Pad.md" 2>/dev/null || stat -c %Y "Scratch Pad.md" 2>/dev/null || echo 0)
tasks_mtime=$(stat -f %m "Tasks" 2>/dev/null || stat -c %Y "Tasks" 2>/dev/null || echo 0)

# ---- cache check (no fork — uses $(< ) which bash handles inline) ----
cache_dir=".claude"
cache_file="$cache_dir/statusline-cache.$session_id.json"

if [[ -f "$cache_file" ]]; then
  cache_content=$(< "$cache_file")
  cached_scratch=""
  cached_tasks=""
  cached_ts=""
  cached_mode=""
  cached_line=""
  [[ "$cache_content" =~ \"scratch_mtime\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_scratch="${BASH_REMATCH[1]}"
  [[ "$cache_content" =~ \"tasks_mtime\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_tasks="${BASH_REMATCH[1]}"
  [[ "$cache_content" =~ \"computed_at\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_ts="${BASH_REMATCH[1]}"
  [[ "$cache_content" =~ \"mode\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cached_mode="${BASH_REMATCH[1]}"
  [[ "$cache_content" =~ \"line\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cached_line="${BASH_REMATCH[1]}"
  if [[ "$cached_scratch" == "$scratch_mtime" \
     && "$cached_tasks" == "$tasks_mtime" \
     && "$cached_mode" == "$mode" \
     && -n "$cached_ts" ]]; then
    # Need current epoch to enforce 10s safety TTL — one fork only on this path
    now=$(date +%s 2>/dev/null || echo 0)
    if [[ $((now - cached_ts)) -lt 10 && -n "$cached_line" ]]; then
      printf '%s' "$cached_line"
      exit 0
    fi
  fi
fi

# ---- cache miss: recompute ----
now=${now:-$(date +%s 2>/dev/null || echo 0)}
today=$(date +%Y-%m-%d 2>/dev/null || echo "0000-00-00")
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir" 2>/dev/null

# Task scan: single awk pass over all task files (one fork for any N).
# Bash read-loops over 150 files took ~1.2s; awk does the same in ~30ms.
task_files=( Tasks/*.md )
if [[ ${#task_files[@]} -eq 0 ]]; then
  overdue=0
  due_today=0
  stale=0
else
  _scan=$(awk -v today="$today" -v now="$now" '
    FNR==1 { in_fm=0; fm_count=0; status=""; due=""; fname=FILENAME }
    /^---[[:space:]]*$/ {
      fm_count++
      if (fm_count==1) { in_fm=1; next }
      if (fm_count==2) {
        if (status=="done" || status=="cancelled") { nextfile }
        if (due!="") {
          if (due < today) { overdue++; nextfile }
          if (due == today) { due_today++; nextfile }
        }
        if (status=="in-progress" || status=="in-review") {
          cmd = "stat -f %m \"" fname "\" 2>/dev/null || stat -c %Y \"" fname "\" 2>/dev/null || echo 0"
          cmd | getline mt
          close(cmd)
          if (now - mt > 432000) stale++
        }
        nextfile
      }
    }
    in_fm==1 && /^status:[[:space:]]*/ {
      s=$0
      sub(/^status:[[:space:]]*/, "", s)
      sub(/[[:space:]].*$/, "", s)
      status=s
    }
    in_fm==1 && /^due:[[:space:]]*/ {
      d=$0
      sub(/^due:[[:space:]]*/, "", d)
      sub(/[[:space:]].*$/, "", d)
      due=d
    }
    END { printf "%d %d %d", overdue+0, due_today+0, stale+0 }
  ' "${task_files[@]}" 2>/dev/null)
  read -r overdue due_today stale <<< "${_scan:-0 0 0}"
fi

# ---- scratch-pad content beyond the seeded "# " header (no fork) ----
scratch_dirty=0
_line_num=0
while IFS= read -r _line; do
  _line_num=$((_line_num + 1))
  if [[ $_line_num -eq 1 && "$_line" == "# "* ]]; then
    continue
  fi
  if [[ "$_line" =~ [^[:space:]] ]]; then
    scratch_dirty=1
    break
  fi
done < "Scratch Pad.md"

# ---- compose line ----
if [[ "$mode" == "focus" ]]; then
  line="📓 🔴${overdue} 🟠${due_today}"
  [[ $stale -gt 0 ]] && line+=" ⏸${stale}"
  [[ $scratch_dirty -eq 1 ]] && line+=" 📝"
else
  line="📓"
  [[ $overdue -gt 0 ]] && line+=" 🔴${overdue}"
  [[ $scratch_dirty -eq 1 ]] && line+=" 📝"
fi

# ---- write cache (best-effort; printf is a bash builtin so no fork) ----
printf '{"session_id":"%s","mode":"%s","scratch_mtime":%s,"tasks_mtime":%s,"computed_at":%s,"line":"%s"}\n' \
  "$session_id" "$mode" "$scratch_mtime" "$tasks_mtime" "$now" "$line" \
  > "$cache_file" 2>/dev/null || true

printf '%s' "$line"
exit 0
