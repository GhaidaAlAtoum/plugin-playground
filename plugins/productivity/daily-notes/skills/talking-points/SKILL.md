---
description: View and manage all talking points, grouped by person — add, remove, or clear items inline
---

View and manage `Talking Points.md` without opening the file directly.

## Steps

1. **Read `Talking Points.md`**: If the file does not exist or is empty, report "No talking points yet." and stop.

2. **Parse and display**: Group entries by person header (`## Name`). Display each group:
   ```
   ## Talking Points

   **Sarah**
   - Discuss Q2 roadmap priorities
   - Follow up on API deprecation timeline ⚠️ stale (12 days)

   **Dave**
   - Review PR #892 feedback
   ```
   Mark any item that has been sitting for 7 or more days (based on the date it was added, if present, or the meeting history gap) with `⚠️ stale`.

3. **Offer actions** after displaying:
   > "Actions: `add <name> <item>` | `remove <name> <item>` | `clear <name>` | `clear all` | done"

4. **Handle actions**:
   - **`add <name> <item>`**: Append item under `## <name>` header in `Talking Points.md`. Create the header if it doesn't exist.
   - **`remove <name> <item>`**: Remove the matching line under `## <name>`. Confirm before writing if ambiguous.
   - **`clear <name>`**: Remove all items under `## <name>` and the header itself. Confirm before writing.
   - **`clear all`**: Truncate `Talking Points.md` to empty. Requires explicit confirmation: "This will clear all talking points. Confirm? [y/n]"
   - **`done`**: Exit without further changes.

5. After each write, re-display the updated list for that person.

## Rules

- Never modify the file without explicit user action in step 4.
- Preserve all other sections when editing — only touch the targeted person's block.
- If a person name is ambiguous (e.g., "Sarah" matches "Sarah K." and "Sarah M."), list matches and ask to clarify.
- Stale detection is a hint only — never auto-remove stale items.
