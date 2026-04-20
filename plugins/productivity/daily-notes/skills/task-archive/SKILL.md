---
description: Move completed tasks older than N days to Tasks/Archive/ to keep the active task list clean
---

Archive completed tasks from `Tasks/` that have been done for a specified number of days.

## Steps

1. **Determine age threshold**: Default is 7 days. If the user specifies a number (e.g., `/task-archive 14`), use that instead.

2. **Scan tasks**: Glob `Tasks/*.md` (not `Tasks/Archive/*.md`). For each file:
   - Read frontmatter `status` and `completedDate`.
   - Skip tasks without `status: done`.
   - Skip tasks without a `completedDate` field.
   - Calculate age: today − `completedDate`.
   - Collect tasks where age ≥ threshold.

3. **If no tasks qualify**: Report "No completed tasks older than N days. Nothing to archive." and stop.

4. **Present archive proposal**:
   ```
   ## Archive Proposal — N tasks completed 7+ days ago

   - Fix login bug (done 2026-03-20, 13 days ago) [high]
   - Update API docs (done 2026-03-22, 11 days ago) [medium]
   - Research rate limiting (done 2026-03-24, 9 days ago) [low]

   Move these to Tasks/Archive/? [y/n/select]
   ```
   - **y**: Archive all listed tasks.
   - **n**: Cancel, no changes.
   - **select**: User names specific tasks to archive; re-confirm before writing.

5. **Archive**: For each confirmed task, move the file from `Tasks/<name>.md` to `Tasks/Archive/<name>.md`. Create `Tasks/Archive/` if it doesn't exist.

6. **Report result**:
   ```
   Archived 3 tasks to Tasks/Archive/.
   Active task count: 4 remaining.
   ```

## Rules

- Never archive tasks without explicit confirmation.
- Only archive tasks with `status: done` — never archive open, in-progress, in-review, or blocked tasks.
- Tasks without a `completedDate` field are skipped (even if status is done) — note them separately: "N tasks marked done but missing completedDate — skipped."
- Do not modify any frontmatter — only move the file.
- `Tasks/Archive/` files are not scanned by other skills (they use `Tasks/*.md` glob, not recursive).
