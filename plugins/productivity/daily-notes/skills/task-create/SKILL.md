---
description: Create a new task file in the Tasks folder with YAML frontmatter
---

Create a new task in the `Tasks/` folder.

## Task format

Tasks are individual `.md` files with YAML frontmatter:

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

**Obsidian profile check:** If `obsidian: true` is set in the Daily Notes Plugin Profile, add these fields to the frontmatter: `created: YYYY-MM-DD` and `type: task`. If `obsidian_tasks: true` is also set, append a Tasks-plugin checkbox line at the end of the task body after the description:
```
- [ ] Task title 🔼 📅 YYYY-MM-DD
```
Priority emoji: `high` → `🔼`, `medium` → (omit), `low` → `🔽`. Only include `📅 date` if a due date is set. If neither flag is set, skip these additions.

**Status values:** `open`, `in-progress`, `in-review`, `blocked`, `done`
**Priority values:** `high` (urgent + important), `medium` (important, not urgent), `low` (everything else)
**Optional fields:** `due`, `scheduled`, `completedDate` (only for done tasks)

## Steps

1. Generate a natural-language filename (max 10 words, e.g. `Review deployment checklist for staging.md`).
2. Derive frontmatter values from the provided information.
3. Check `Tasks/*.md` — do not duplicate an existing task.
4. Propose the task for approval in this format:
   ```
   Title:     <title>
   Priority:  <high/medium/low>
   Due:       <date or "not set">
   Scheduled: <date or "not set">
   ```
5. If a due date cannot be inferred, ask for it — never skip this step even in bulk workflows.
6. Wait for: **accept**, **reject**, or **adjust** before writing the file.
7. On acceptance, write the file to `Tasks/`.
