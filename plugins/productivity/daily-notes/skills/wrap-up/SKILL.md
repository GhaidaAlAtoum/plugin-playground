---
description: End-of-day closeout — catch stragglers, update tasks, finalize daily note, and save context for tomorrow
---

End-of-day closeout. Make sure nothing falls through the cracks.

## Steps

1. **Catch stragglers**: Read `Scratch Pad.md` and check `Meetings/` for anything unprocessed. If there's content, run the same processing as /sync. If everything's clean, move on.

2. **Task updates**: Glob all `Tasks/*.md` and read frontmatter:
   - Anything worked on today still marked `status: open`? Ask if it should move to `in-progress`.
   - Anything finished? Ask before updating `status: done` and adding `completedDate: YYYY-MM-DD`.
   - Anything blocked? Flag it.

3. **Talking Points cleanup**: Read `Talking Points.md`. Cross-reference with any meetings processed today. If talking points for a person were likely addressed, ask if they should be cleared. Remove confirmed items; remove the person's entire section if no points remain.

4. **Daily Note finalization**: Open today's `Daily Notes/YYYY-MM-DD.md` (create if missing). Add or update:

   **Plain markdown** (default):
   ```
   ## End of Day
   (2-3 sentence summary of what got done, what didn't, what shifted)

   ## Carry Forward
   (anything unfinished that needs attention tomorrow)
   ```

   **Obsidian profile check:** If `obsidian: true` is set, use callouts instead:
   ```markdown
   > [!success] End of Day
   > 2-3 sentence summary of what got done, what didn't, what shifted

   > [!attention] Carry Forward
   > Anything unfinished that needs attention tomorrow
   ```

   Merge with existing content — do not overwrite earlier sections written by /sync.

5. **Memory update**: Write a concise context snapshot to `.claude/memory.md`. Include:
   - What I was actively working on and where I left off
   - Anything blocked and why
   - Follow-ups or reminders for tomorrow
   - Key decisions made today
   Keep it tight — this is for tomorrow's /start to scan in under 10 seconds. Replace yesterday's carry-forward notes rather than appending indefinitely.

6. **Clear Scratch Pad**: If anything was processed in step 1, clear `Scratch Pad.md` after confirming.

7. **EOD summary**: Give a brief closing summary:
   - What got done today
   - What's carrying forward
   - Anything time-sensitive for tomorrow
   Format: short bullets, no preamble.

## Rules

- Ask before moving any task to "done" — never assume.
- Create `Daily Notes/` if it doesn't exist.
- Keep memory notes tight — future context, not a diary.
