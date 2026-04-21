# Statusline v2 — TUI setup guide

Step-by-step for configuring `ccstatusline` to render the claude-tracker v2 statusline (3 lines, colored context + 5h-block bars, month cost).

> 📸 **About the screenshots:** the images below are from `ccstatusline` v2.2.8 on macOS. Your TUI may differ slightly per version, but the flow is the same.

You should already have:
- Edited `~/.claude/settings.json` → `statusLine.command` set to `"npx -y ccstatusline@latest"` with `"padding": 0`
- Run `bash <plugin-dir>/statusline/install-ccstatusline.sh` once — **save its output**; it contains the three `commandPath` strings you'll paste in step 7. Those strings are resolved for *your* machine — do not copy the example paths from this guide.

---

## Where does `<plugin-dir>` live on my machine?

The install script prints the right absolute path regardless of how you installed the plugin. But if you ever need to find it yourself:

| Install method | Typical plugin path |
|---|---|
| **Marketplace** (`/plugin install claude-tracker@<marketplace>`) | `~/.claude/plugins/cache/<marketplace-name>/claude-tracker/<version>/` |
| **Local git clone** | `<wherever-you-cloned>/plugins/productivity/claude-tracker/` |

> ⚠️ **Marketplace paths include the plugin version** (e.g. `.../claude-tracker/0.2.0/...`). That means every time you upgrade the plugin, the absolute path changes — the old `<version>` directory is swapped for the new one, and the `commandPath` strings in your ccstatusline config silently break. **After any upgrade, rerun `install-ccstatusline.sh` and paste the fresh strings into each Custom Command widget.** (Local clones don't have this problem — the path stays put.)

Everywhere this guide shows `<PYTHON>` or `<PLUGIN_DIR>`, substitute the strings the install script printed for you.

---

## 1. Launch the TUI

In a terminal (not inside Claude Code):

```bash
npx -y ccstatusline@latest
```

You'll land on the **CCStatusline Configuration** main menu:

```
Main Menu
▶  Edit Lines
   Edit Colors
   Powerline Setup
   Terminal Options
   Global Overrides
   Uninstall from Claude Code
   Exit
```

At the top is a live **Preview** of the current configuration. On a fresh install it typically shows one line, e.g. `Model: Claude | Ctx: 18.6k | ⌘ main (+42,-10)`.

> 💾 **At any point you can press `Ctrl+S` to save** without leaving the TUI. The config is written to `~/.config/ccstatusline/settings.json`.

---

## 2. Open the Line editor

From the main menu: select **Edit Lines** (Enter).

You'll see the list of lines currently configured. Probably just **Line 1** with a few default widgets (Model, Context, Git).

---

## 3. Target layout — 3 lines

Aim for **3 lines**:

| Line | Widgets |
|---|---|
| **1** | Current Working Directory · Git Branch · Git Changes |
| **2** | Model · Session Clock · **Custom Command** (ctx bar) |
| **3** | **Custom Command** (5h block bar) · **Custom Command** (month cost) |

When you're done, the Lines overview should look like this:

![Lines overview — 3 lines configured](./screenshots/step3-lines-overview.png)

You'll likely need to:
- Edit Line 1 to match (add CWD if missing, add Git widgets if missing)
- Add two new lines (Line 2, Line 3)
- Add three Custom Command widgets total (one on line 2, two on line 3)

---

## 4. Edit Line 1 — path + git

On Line 1, the widgets you want (in order):

1. **Current Working Directory** (some versions call it "CWD" or "Working Dir")
2. **Separator** (`|`)
3. **Git Branch**
4. **Separator** (`|`)
5. **Git Changes** (or separately: Git Insertions + Git Deletions)

![Line 1 — CWD, Git Branch, Git Changes](./screenshots/step4-line1-path-git.png)

To add a widget: usually there's an "Add Widget" option within the line editor (or an `(a)` keybind). Pick it, then scroll through the widget catalog and select the one you want.

To reorder: most TUI versions let you move widgets up/down with arrow keys or dedicated keybinds shown at the bottom of the screen.

To delete an unwanted default widget: select it, look for a "Remove" option or a `(d)`/Delete keybind.

> **Tip:** keep an eye on the Preview at the top — it updates live as you add/remove widgets. That's your ground truth.

---

## 5. Add Line 2 — model + session + ctx bar

Back out to the Lines list. Pick "Add Line" (or similar). On the new Line 2, add (in order):

1. **Model**
2. **Separator** (`|`)
3. **Session Clock** (or "Session Duration")
4. **Separator** (`|`)
5. **Custom Command** ← this one renders our colored Ctx bar

![Line 2 — Model, Session Clock, Custom Command (ctx)](./screenshots/step5-line2-model-session-ctx.png)

Keep reading for how to configure the Custom Command in step 7.

---

## 6. Add Line 3 — 5h block + month cost

Add another line (Line 3). Add (in order):

1. **Custom Command** ← 5h block bar
2. **Separator** (`|`)
3. **Custom Command** ← month cost

![Line 3 — two Custom Commands (block, month)](./screenshots/step6-line3-block-month.png)

---

## 7. Configure each Custom Command

For every Custom Command widget you added in steps 5 and 6, open its widget options and set:

| Option | Value |
|---|---|
| `commandPath` | one of the three strings from the install script output |
| `preserveColors` | **true** (critical — without this, the ANSI colors get stripped) |
| `timeout` | `1000` (milliseconds; default) |
| `maxWidth` | optional; `40` for ctx, `60` for block, `20` for month is a good start |

**commandPath values** — these look like:

**Ctx segment** (line 2):
```
<PYTHON> <PLUGIN_DIR>/statusline/render_segments.py --segment ctx
```

**Block segment** (line 3, first):
```
<PYTHON> <PLUGIN_DIR>/statusline/render_segments.py --segment block
```

**Month segment** (line 3, second):
```
<PYTHON> <PLUGIN_DIR>/statusline/render_segments.py --segment month
```

**Don't retype these.** Copy the three fully-resolved strings printed by `install-ccstatusline.sh` — it already figured out your Python interpreter and your plugin install path. They will look like one of:

- `~/.claude/plugins/cache/<marketplace>/claude-tracker/<version>/statusline/render_segments.py …` (marketplace install — note the version segment)
- `/path/to/your/clone/plugins/productivity/claude-tracker/statusline/render_segments.py …` (local clone)

> ⚠️ **Don't use plain `python3 …`** — on a machine with pyenv, the shim adds ~1s per invocation and will exceed the timeout. Always use the absolute interpreter path, which the install script printed for you.

---

## 8. Preview check

The Preview at the top of the TUI should now look something like this (colors in your terminal):

```
~/plugin-playground  ⎇ main (+2,-1)
Opus 4.7  ·  Session 12m  ·  Ctx ▓▓▓▓▓░░░░░ 52% (104K/1M)
5h ▓▓▓░░░░░░░ 2h14m left · $71.98  ·  💰 $769.45 mo
```

- **Ctx bar** should be green if < 70%, yellow 70–89%, red ≥ 90%.
- **5h bar** fills as your Anthropic 5h block elapses; same color thresholds (red = nearly out of time).
- **Numbers visible at all** = your `commandPath` and `preserveColors` are configured correctly.
- If a Custom Command shows dim dashes (`░░░░ ??%`) — that's the cold-cache fallback. Wait ~2 seconds and it populates.

---

## 9. Save & exit

Press **Ctrl+S** to save. The TUI writes to `~/.config/ccstatusline/settings.json`.

Select **Exit** from the main menu.

---

## 10. Restart Claude Code

Close and re-open Claude Code. The new 3-line statusline should render at the bottom of the window.

If it doesn't, sanity-check in order:

1. `~/.claude/settings.json` has `"command": "npx -y ccstatusline@latest"` with `"padding": 0`
2. `~/.config/ccstatusline/settings.json` exists and has 3 lines (`cat ~/.config/ccstatusline/settings.json | head -40`)
3. Run one of the commandPath strings manually — substitute the `<PYTHON>` and `<PLUGIN_DIR>` the install script printed:
   ```bash
   echo '{}' | <PYTHON> <PLUGIN_DIR>/statusline/render_segments.py --segment month
   ```
   Should print `💰 $xx.xx mo` (or a dim fallback on a truly cold cache).

---

## Optional additions

- **Team plan quota**: add `SessionUsage` and `WeeklyUsage` widgets (only work on Team plan).
- **Custom context limit**: set the env var `CLAUDE_CTX_LIMIT=200000` (or any integer) in your shell profile to override the per-model default.

---

## Reconfiguring later

Just re-run `npx -y ccstatusline@latest`. Your saved config is picked up automatically; you can tweak and re-save without starting over.

### After upgrading the plugin (marketplace users)

Marketplace installs live at a versioned path (`…/claude-tracker/<version>/…`), so **every plugin upgrade breaks the old `commandPath` strings** saved in `~/.config/ccstatusline/settings.json`. The statusline will fall back to dim dashes until you refresh.

To recover:

```bash
bash ~/.claude/plugins/cache/<marketplace-name>/claude-tracker/<new-version>/statusline/install-ccstatusline.sh
```

Copy the three printed commands, then in the ccstatusline TUI (`npx -y ccstatusline@latest` → Edit Lines → each Custom Command widget → edit cmd) paste the new `commandPath` for each of the ctx / block / month widgets. Save with Ctrl+S and restart Claude Code.

Local-clone installs don't have this problem — the path stays put across `git pull`s.
