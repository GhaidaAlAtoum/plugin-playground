---
description: List tasks from the Tasks folder, filtered and sorted by priority and due date
---

List tasks from the `Tasks/` folder.

## Steps

1. Glob all `Tasks/*.md` files and read their frontmatter.
2. Filter by due date, scheduled date, and priority to surface relevant items (default: exclude `done`).
3. Sort: high priority first, then by due date ascending.
4. Present as a numbered list for easy reference in follow-up instructions.

## Format

```
1. <Task Name>
   Priority: <high/medium/low>
   Due: <YYYY-MM-DD or "not set">
   <Brief description>
```
