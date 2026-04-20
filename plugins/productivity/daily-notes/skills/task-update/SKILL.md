---
description: Update a task's status or frontmatter fields
---

Update a task in the `Tasks/` folder.

## Valid statuses

- `open` — not yet started
- `in-progress` — actively being worked on
- `in-review` — work done, waiting for review or approval
- `blocked` — cannot proceed; add a note explaining what's blocking it
- `done` — completed

## Steps

1. If no task is specified, use /task-list to show current tasks and ask which to update.
2. Read the task file to confirm current state.
3. Apply the requested change to the frontmatter field(s).
4. When setting `status: done`, also add `completedDate: YYYY-MM-DD` (today's date).
5. Confirm the update before writing — show old value → new value.
6. Write the updated file.

## Rules

- Never mark a task `done` without explicit confirmation.
- Only update fields the user specifies — leave all other frontmatter untouched.
