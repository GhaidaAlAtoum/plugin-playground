# macOS Shortcuts recipes

Two Shortcuts.app recipes that turn `daily-notes` slash commands into one-tap actions from your menu bar, Dock, Touch Bar, Apple Watch, or a keyboard shortcut. All recipes run the `claude` CLI in your notes folder — no network calls, no extra permissions beyond what `claude` already has.

> **Why recipes, not `.shortcut` files?** Shortcuts binaries are unstable across macOS releases and bind to your user's file paths. The build instructions below let you paste the recipe once and adjust paths to your vault. Takes 2 minutes per recipe.

---

## Prerequisites

1. **macOS Monterey (12.0) or later** — Shortcuts.app is bundled.
2. **`claude` CLI on your `$PATH`** — verify with `which claude` in Terminal. If the Shortcut can't find it, give it the absolute path (usually `/usr/local/bin/claude` or `~/.claude/local/claude`).
3. **Your notes folder path** — e.g. `~/Documents/notes`. All recipes below assume you replace `<NOTES_FOLDER>` with your actual path.
4. **Terminal automation permission** — first run triggers a macOS permission prompt; allow it.

---

## Recipe 1 — Morning standup (with speech)

Runs `/start` in your notes folder and reads the result aloud. Useful on the walk to the desk or while making coffee.

### Build

1. Open **Shortcuts.app** → **+** (new shortcut) → name it **Morning Standup**.
2. Add action: **Run Shell Script** (search "shell").
   - Shell: `/bin/zsh`
   - Pass input: *(leave empty)*
   - Script:
     ```bash
     cd <NOTES_FOLDER> && claude -p "/start" 2>/dev/null
     ```
3. Add action: **Speak Text**. Set the input to **Shell Script Result**.
   - Rate: ~0.45 (slightly slower than default)
   - Voice: your preference
4. Click **Details** (top right) → enable **Pin in Menu Bar**.
5. (Optional) Set a keyboard shortcut: **Details → Add Keyboard Shortcut → ⌃⌥M**.

### Use

Click the Shortcuts menu-bar icon → **Morning Standup**. Your open tasks and focus suggestions are spoken aloud while you settle in.

> **Tip**: pair with `auto_start_suggestion: false` in your profile — the Shortcut becomes your morning ritual and the session-start nudge no longer interrupts mid-session.

---

## Recipe 2 — Quick note (open Scratch Pad, sync on close)

Opens `Scratch Pad.md` in your default Markdown editor. When you close the editor, offers to run `/sync --preview` so you can see the plan before committing.

### Build

1. New Shortcut → name it **Quick Note**.
2. Add action: **Open File**.
   - File: navigate to `<NOTES_FOLDER>/Scratch Pad.md`.
   - Open With: your Markdown editor (Obsidian, iA Writer, VS Code, or default).
3. Add action: **Wait**. Duration: 0.5 seconds. *(Gives the editor focus.)*
4. Add action: **Show Alert** *(only if you want the sync prompt; skip for pure "open")*.
   - Title: `Sync now?`
   - Message: `Run /sync --preview to see what will be filed.`
   - Show Cancel Button: yes
5. Add action: **Run Shell Script** *(only runs if user clicks OK)*.
   - Shell: `/bin/zsh`
   - Script:
     ```bash
     cd <NOTES_FOLDER> && claude -p "/sync --preview"
     ```
6. Add action: **Show Result** (input: Shell Script Result).
7. Pin to menu bar + optional keyboard shortcut **⌃⌥N**.

### Use

Hit **⌃⌥N** → Scratch Pad opens. Jot your thought. Close the editor. Click OK on the alert if you want to preview the sync plan immediately, or Cancel to defer.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "command not found: claude" | Replace `claude` with the absolute path. Find it with `which claude`. |
| Shortcut hangs | `claude -p` is non-interactive; if a skill needs confirmation, run it from the terminal instead. Morning Standup is safe — it's read-only. Quick Note's preview step is also read-only. |
| "Operation not permitted" | First run triggers **System Settings → Privacy & Security → Automation** — grant Shortcuts permission to control Terminal. |
| Voice in Morning Standup cuts off | Increase the **Wait** between actions, or split long output with `\| head -40` in the shell script. |

---

## Out of scope

- **Menubar task list / sparkline** — a separate menubar app would need AppleScript or SwiftBar integration. Not part of this plugin.
- **Dock badge for open task count** — same reason; Shortcuts.app can't write Dock badges.
- **iPhone / Watch companion shortcuts** — these require the `claude` CLI on-device, which isn't supported.

If you build something polished on top of these, open a PR and we'll link it from this README.
