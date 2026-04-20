---
description: Prepare a quick-reference sheet before a meeting with a specific person
---

Prepare for a meeting with a specific person.

## Steps

1. **Identify person**: If not specified in the command arguments, ask who the meeting is with. If the name could match multiple people, ask for clarification before proceeding.

2. **Talking Points**: Read `Talking Points.md`. Find the section for this person and list pending topics.

3. **Recent meeting history**: **Profile check:** Read the "Daily Notes Plugin Profile" section from your CLAUDE.md context. If `track_contacts: true` is set, check `{contacts_folder}/<Name>/Meeting History/` (default `contacts_folder`: `People`). If the folder exists, read the last 1-2 note files and summarize open items, commitments made, and anything unresolved. If `track_contacts` is not set or is `false`, skip this step.

4. **Contact log**: **Profile check:** If `track_contacts: true` is set, check `{contacts_folder}/<Name>/log.md`. If it exists, read the last 3-5 entries and surface anything relevant for the conversation. If `track_contacts` is not set or is `false`, skip this step.

5. **Related tasks**: Glob `Tasks/*.md` and check for any that mention this person (in filename or body). List open and in-progress ones.

6. **Present prep summary**:
   ```
   ## Prep: Meeting with <Name>

   ### Talking Points
   - item 1
   - item 2

   ### Open Items from Last Meeting
   - ...

   ### Recent Log Entries
   - ...

   ### Related Tasks
   - ...
   ```

## Rules

- Skip sections that have no content — don't show empty headers.
- Be concise — this is a quick-reference before walking into a meeting.
- Read-only — do not modify any files.
