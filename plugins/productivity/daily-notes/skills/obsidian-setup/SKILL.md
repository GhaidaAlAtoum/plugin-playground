---
description: One-time Obsidian vault setup — generates Dashboard.md, note templates, and recommended plugin list
---

Scaffold the Obsidian infrastructure files that activate Dataview queries, graph connections, and the daily note template system.

**Run this once** after setting `obsidian: true` in your Daily Notes Plugin Profile.

## Steps

1. **Profile check**: Read the "Daily Notes Plugin Profile" from your CLAUDE.md context. If `obsidian` is not set or is `false`, stop:
   > "Set `obsidian: true` in your Daily Notes Plugin Profile first, then re-run /obsidian-setup."

2. **Check existing files**: Before writing anything, check which of these files already exist:
   - `Dashboard.md`
   - `Templates/Daily Note.md`
   - `Templates/Meeting Note.md`
   
   Report what exists and what will be created. Never overwrite an existing file — skip it and note the skip.

3. **Create `Dashboard.md`** (if it doesn't exist). Confirm before writing:

   ````markdown
   ---
   type: dashboard
   tags: [dashboard]
   ---

   # Dashboard

   ## ⚠️ Overdue Tasks
   ```dataview
   TABLE due, priority
   FROM "Tasks"
   WHERE status != "done" AND status != "cancelled" AND due < date(today)
   SORT due ASC
   ```

   ## 📅 Due Today
   ```dataview
   TABLE priority
   FROM "Tasks"
   WHERE status != "done" AND due = date(today)
   SORT priority ASC
   ```

   ## 🔼 Open — High Priority
   ```dataview
   TABLE due, status
   FROM "Tasks"
   WHERE status != "done" AND status != "cancelled" AND priority = "high"
   SORT due ASC
   ```

   ## 📋 In Progress
   ```dataview
   TABLE priority, due
   FROM "Tasks"
   WHERE status = "in-progress" OR status = "in-review"
   SORT file.mtime DESC
   ```

   ## 🗓️ Recent Meetings
   ```dataview
   TABLE people
   FROM "Meetings"
   WHERE type = "meeting"
   SORT created DESC
   LIMIT 7
   ```

   ## 📓 This Week's Daily Notes
   ```dataview
   LIST
   FROM "Daily Notes"
   WHERE created >= date(today) - dur(7 days)
   SORT created DESC
   ```
   ````

4. **Create `Templates/Daily Note.md`** (if it doesn't exist). Create the `Templates/` folder if needed. Confirm before writing:

   ````markdown
   ---
   created: {{date:YYYY-MM-DD}}
   type: daily-note
   tags: [daily]
   ---

   # {{date:dddd, MMMM DD, YYYY}}

   > [!abstract] Summary
   > 

   > [!note] Notes Processed
   > 

   > [!check] Tasks Completed
   > 

   > [!success] End of Day
   > 

   > [!attention] Carry Forward
   > 
   ````

5. **Create `Templates/Meeting Note.md`** (if it doesn't exist). Confirm before writing:

   ````markdown
   ---
   created: {{date:YYYY-MM-DD}}
   type: meeting
   people: []
   tags: [meeting]
   ---

   # Meeting — {{date:YYYY-MM-DD}}

   > [!abstract] Summary
   > 

   > [!warning] Action Items
   > 

   > [!note] Decisions
   > 

   > [!question] Open Questions
   > 
   ````

6. **Report results**: List what was created and what was skipped.

7. **Plugin install guidance**: Print the following in chat (do not write to a file):

   ```
   ## Recommended Obsidian Community Plugins

   Install these from Settings → Community plugins → Browse:

   Essential (for Dashboard.md to work):
   - Dataview — query your vault like a database

   Recommended:
   - Periodic Notes — weekly, monthly, quarterly notes alongside daily
   - Calendar — sidebar calendar linked to daily notes

   Optional (only if you set obsidian_tasks: true in your profile):
   - Tasks — emoji-based task tracking across your vault

   After installing Dataview, open Dashboard.md in Obsidian — the query
   blocks will render as live tables.

   Tip: In Obsidian Settings → Daily Notes (core plugin), point the Template file to
   "Templates/Daily Note" to auto-apply the template each morning.

   If you installed Periodic Notes instead, configure it in Settings → Periodic Notes:
   - Daily Notes → Note Folder: Daily Notes
   - Daily Notes → Template: Templates/Daily Note
   ```

## Rules

- Never overwrite existing files — skip and report.
- Always confirm before writing each file.
- Create `Templates/` folder if needed, but do not create any other folders.
- If Dataview queries look broken after opening in Obsidian, the Dataview plugin is likely not installed — remind the user.
