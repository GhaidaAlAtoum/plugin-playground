---
description: One-time Obsidian vault setup — generates Dashboard.md, note templates, and recommended plugin list
---

Scaffold the Obsidian infrastructure files that activate Dataview queries, graph connections, and the daily note template system.

**Run this once** after setting `obsidian: true` in your Daily Notes Plugin Profile.

## Templates source

The literal file contents for `Dashboard.md`, `Templates/Daily Note.md`, and `Templates/Meeting Note.md` — plus the post-scaffold chat guidance — all live in `${CLAUDE_PLUGIN_ROOT}/references/obsidian-templates.md`. Read that file when you need the body of a template; never reinvent the templates inline.

## Steps

1. **Profile check**: If `obsidian` is not set or is `false` in the Daily Notes Plugin Profile, stop with:
   > "Set `obsidian: true` in your Daily Notes Plugin Profile first, then re-run /obsidian-setup."

2. **Check existing files**: Before writing anything, check which of these already exist:
   - `Dashboard.md`
   - `Templates/Daily Note.md`
   - `Templates/Meeting Note.md`

   Report what exists and what will be created. Never overwrite an existing file — skip it and note the skip.

3. **Create `Dashboard.md`** (if missing). Read the `## Dashboard.md` section from `references/obsidian-templates.md` and write it verbatim. Confirm before writing.

4. **Create `Templates/Daily Note.md`** (if missing). Create the `Templates/` folder if needed. Read the `## Templates/Daily Note.md` section from the reference file and write it verbatim. Confirm before writing.

5. **Create `Templates/Meeting Note.md`** (if missing). Read the `## Templates/Meeting Note.md` section from the reference file and write it verbatim. Confirm before writing.

6. **Report results**: List what was created and what was skipped.

7. **Plugin install guidance**: Print the *Post-scaffold chat guidance* block from the reference file in chat (do not write to a file).

## Rules

- Never overwrite existing files — skip and report.
- Always confirm before writing each file.
- Create `Templates/` folder if needed, but do not create any other folders.
- If Dataview queries look broken after opening in Obsidian, the Dataview plugin is likely not installed — remind the user.
