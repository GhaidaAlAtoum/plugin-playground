# Canonical note formats

Shared reference for every skill that writes a task, meeting note, daily note, or contact log. When `obsidian: true` is set in the Daily Notes Plugin Profile, use the Obsidian variant; otherwise use plain markdown.

Skills that consume this file: `/sync`, `/wrap-up`, `/task`, `/one-on-one-prep`, `/obsidian-setup`.

---

## Task file — `Tasks/<name>.md`

### Plain markdown (default)

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

**Allowed `status`**: `open`, `in-progress`, `in-review`, `blocked`, `done`.
**Allowed `priority`**: `high`, `medium`, `low`.
**Optional fields**: `due`, `scheduled`, `completedDate` (required when `status: done`), `jira:`, `jira_url:`, `release:` (free-text label bucketed by `/release-notes`).

### With `obsidian: true`

Append to frontmatter:

```yaml
created: YYYY-MM-DD
type: task
```

### With `obsidian_tasks: true` (requires `obsidian: true`)

Append a Tasks-plugin checkbox to the task body:

```
- [ ] Task title 🔼 📅 YYYY-MM-DD
```

Priority emoji: `high` → `🔼`, `medium` → omit, `low` → `🔽`. `📅 YYYY-MM-DD` only if `due` is set.

---

## Meeting note — `Meetings/YYYY-MM-DD Meeting.md` (or routed to `{contacts_folder}/<Name>/Meeting History/YYYY-MM-DD.md` when `track_contacts: true` and the meeting matches `recurring_meetings_label`)

### Plain markdown

```markdown
# Meeting — YYYY-MM-DD

## Summary
- 3-5 bullet summary

## Action Items
- <Owner> — task description

## Decisions
- Decision made

## Open Questions
- Anything unresolved
```

### With `obsidian: true`

```markdown
---
created: YYYY-MM-DD
type: meeting
people: ["[[Name]]"]
tags: [meeting]
---

# Meeting — YYYY-MM-DD

> [!abstract] Summary
> - 3-5 bullet summary

> [!warning] Action Items
> - [[Owner]] — task description

> [!note] Decisions
> - Decision made

> [!question] Open Questions
> - Anything unresolved
```

Use `[[Name]]` wikilinks for every person reference so Obsidian builds graph edges.

---

## Daily note — `Daily Notes/YYYY-MM-DD.md`

### Plain markdown

```markdown
# YYYY-MM-DD

## Summary
(brief narrative of what happened today — 2-3 sentences max)

## Notes Processed
(items pulled from Scratch Pad)

## Meetings
(summaries from step 2, or skip if none)

## New Tasks Added
(list of tasks created)

## End of Day
(2-3 sentence summary of what got done, what didn't, what shifted — written by /wrap-up)

## Carry Forward
(anything unfinished that needs attention tomorrow — written by /wrap-up)
```

### With `obsidian: true`

```markdown
---
created: YYYY-MM-DD
type: daily-note
tags: [daily]
---

# YYYY-MM-DD

> [!abstract] Summary
> Brief narrative — 2-3 sentences max

> [!note] Notes Processed
> Items pulled from Scratch Pad

> [!check] New Tasks Added
> - Task name

> [!success] End of Day
> 2-3 sentence summary of what got done, what didn't, what shifted

> [!attention] Carry Forward
> Anything unfinished that needs attention tomorrow
```

Merge with existing sections — never overwrite earlier content written by `/sync` or `/wrap-up`.

---

## Contact log — `{contacts_folder}/<Name>/log.md`

Only written when `track_contacts: true`. Free-form `## <heading>` + date + body entries, optionally gated by frontmatter for direct reports:

```markdown
---
report: true
---

## <Quick title summarizing the event or feedback>
- Date: YYYY-MM-DD
- Source: <meeting or context if available>
<Brief summary. Include business impact if relevant.>
```

Only `report: true` is read by any skill (gates `/team-recap` iteration). `/one-on-one-prep` works on any contact regardless of the field.

---

## 1:1 prep block (written by `/one-on-one-prep` when appended to the next 1:1 note)

### Plain markdown

```markdown
## 1:1 Prep — <Name> (YYYY-MM-DD)

### Since last 1:1 (YYYY-MM-DD)
- Decisions: ...
- Open commitments: ...

### Open threads
- [log 2026-04-15] Pending decision on rollback plan
- [meeting 2026-04-10] Follow up on Q2 scoping

### Related tasks
- POE-1234 Migrate auth (in-progress, owns)

### Talking points
- Ask about Q2 plan

### Suggested topics
1. Rollback plan — [log 2026-04-15]
2. Q2 scoping — [carryover from last 1:1]

### Growth / feedback prompts
- "What went well with the auth migration?"
```

### With `obsidian: true`

Wrap sections in callouts and the person's name in `[[wikilinks]]`:

- `> [!abstract] Since last 1:1`
- `> [!note] Open threads`
- `> [!check] Related tasks`
- `> [!question] Suggested topics`
- `> [!tip] Growth / feedback prompts`

Skip any section with no content — never show headers with no body.
