# Obsidian vault templates

Shared reference for `/obsidian-setup`. Contains the literal file contents that the skill scaffolds. Never read more than one of these sections in a single invocation — the skill picks based on what's missing in the vault.

Only the `obsidian` profile flag determines whether this file is relevant. `/obsidian-setup` refuses to run if `obsidian: false` or unset.

---

## `Dashboard.md`

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

---

## `Templates/Daily Note.md`

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

---

## `Templates/Meeting Note.md`

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

---

## Post-scaffold chat guidance (print, don't write to file)

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
