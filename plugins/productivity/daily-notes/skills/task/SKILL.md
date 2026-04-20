---
description: Manage tasks — dispatches to create/list/update/archive based on first argument (defaults to list)
---

Single entry point for task operations. Reads the first argument and dispatches to one of four sub-behaviours: `create`, `list`, `update`, `archive`. If no argument is given, defaults to `list`.

## Dispatch

| Invocation | Behaviour |
|---|---|
| `/task` | Same as `/task list`. |
| `/task create [title]` | Create a new task file. |
| `/task list [filter]` | List tasks (optionally filtered). |
| `/task update [key-or-title]` | Update status / priority / notes on an existing task. |
| `/task archive [N]` | Move completed tasks older than N days (default 7) to `Tasks/Archive/`. |

If the first argument is not one of these verbs, treat the whole argument as a title for `create` (makes the common case `/task "fix login bug"` work).

---

## Task format (shared schema)

Tasks are individual `.md` files in `Tasks/` with YAML frontmatter:

```markdown
---
status: open
priority: medium
due: YYYY-MM-DD
scheduled: YYYY-MM-DD
tags: [task]
---

# Task title

Brief description (1-2 sentences).
```

**Status values:** `open`, `in-progress`, `in-review`, `blocked`, `done`
**Priority values:** `high`, `medium`, `low`
**Optional fields:** `due`, `scheduled`, `completedDate` (only for `done` tasks), `jira:`, `jira_url:`

**Obsidian profile check:** If `obsidian: true` is set in the Daily Notes Plugin Profile, add `created: YYYY-MM-DD` and `type: task` to the frontmatter. If `obsidian_tasks: true` is also set, append a Tasks-plugin checkbox at the end of the task body:
```
- [ ] Task title 🔼 📅 YYYY-MM-DD
```
Priority emoji: `high` → `🔼`, `medium` → (omit), `low` → `🔽`. Only include `📅 date` if a due date is set.

---

## `create` — guided task creation

1. Generate a natural-language filename (max 10 words, e.g. `Review deployment checklist for staging.md`).
2. Derive frontmatter values from the provided information.
3. Check `Tasks/*.md` — do not duplicate an existing task.
4. Propose the task for approval:
   ```
   Title:     <title>
   Priority:  <high/medium/low>
   Due:       <date or "not set">
   Scheduled: <date or "not set">
   ```
5. If a due date cannot be inferred, ask for it — never skip this step even in bulk workflows.
6. Wait for **accept**, **reject**, or **adjust** before writing the file.
7. On acceptance, write the file to `Tasks/`.

---

## `list` — show current tasks

1. Glob all `Tasks/*.md` files and read their frontmatter.
2. Filter: by default exclude `done`. If the user passes a filter argument (`high`, `overdue`, `today`, `blocked`, `in-progress`, a tag name, or a person's name), apply it.
3. Sort: high priority first, then by due date ascending.
4. Present as a numbered list for easy reference in follow-up instructions:

```
1. <Task Name>
   Priority: <high/medium/low>
   Due: <YYYY-MM-DD or "not set">
   <Brief description>
```

---

## `update` — change status or frontmatter

1. If no task is specified, run `list` first and ask which to update.
2. Read the task file to confirm current state.
3. Apply the requested change to the frontmatter field(s).
4. When setting `status: done`, also set `completedDate: YYYY-MM-DD` (today's date).
5. Confirm before writing — show `old value → new value`.
6. Write the updated file.

**Rules for update:**
- Never mark a task `done` without explicit confirmation.
- Only update fields the user specifies — leave all other frontmatter untouched.

---

## `archive` — tidy completed work

1. **Age threshold**: Default is 7 days. If the user passes a number (e.g. `/task archive 14`), use that instead.

2. **Scan tasks**: Glob `Tasks/*.md` (not `Tasks/Archive/*.md`). For each:
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

   Move these to Tasks/Archive/? [y/n/select]
   ```
   - **y**: archive all.
   - **n**: cancel.
   - **select**: user names specific tasks; re-confirm before writing.

5. **Archive**: For each confirmed task, move the file from `Tasks/<name>.md` to `Tasks/Archive/<name>.md`. Create `Tasks/Archive/` if it doesn't exist.

6. **Report**:
   ```
   Archived 3 tasks to Tasks/Archive/.
   Active task count: 4 remaining.
   ```

**Rules for archive:**
- Never archive tasks without explicit confirmation.
- Only archive `status: done`.
- Tasks without a `completedDate` are skipped (even if done) — note separately: "N tasks marked done but missing completedDate — skipped."
- Do not modify any frontmatter — only move the file.
- `Tasks/Archive/` files are not scanned by other skills (they use `Tasks/*.md` glob, not recursive).
