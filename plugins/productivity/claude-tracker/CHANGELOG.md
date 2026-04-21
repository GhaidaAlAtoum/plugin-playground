# Changelog

All notable changes to **claude-tracker** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `transcript_summary()` helper in `tracker_core.py` — sums cost/usage for a single Claude Code session from its transcript file.
- New `💬 Session` statusline segment showing current CLI session cost, driven by `transcript_path` from the statusline stdin payload.
- README "Three 5h windows" terminology table clarifying Claude Code session vs Anthropic 5h pricing block vs subscription rate-limit window.
- Default layout now recommends ccstatusline's built-in **`ThinkingEffort`** widget on line 2, showing the current thinking level (`low` / `medium` / `high` / `max`). Requires ccstatusline v2.3+.

### Changed
- Statusline 5h segment now displays `X to reset` aligned to the clock hour (approximates `/usage` subscription reset) instead of `X left` from the exact first-message timestamp. Entry filtering for the cost calculation still uses the exact block start, so the displayed cost is unchanged.
- Default `install-ccstatusline.sh` layout: bottom row is now `block · session` instead of `block · month`.

### Compatibility
- `--segment month` is still a valid CLI flag for existing ccstatusline configs. Only the default install layout has changed; users who explicitly configured the month segment keep seeing it.

## [0.2.0] — 2026-04-21

### Added
- ccstatusline-based v2 statusline: 3-line layout with threshold-colored context and 5h-block bars via `CustomCommand` widgets.
- `statusline/SETUP-GUIDE.md` — step-by-step TUI walkthrough with screenshots.
- `install-ccstatusline.sh` guided setup script: prereq checks, live sample render, copy-paste TUI instructions.
- Versioned marketplace path documented; upgrade-refresh step added to setup guide.

### Fixed
- `install-ccstatusline.sh` now dereferences pyenv shims via `sys.executable` to avoid the ~1s shim-rehash penalty that would exceed ccstatusline's 1000 ms timeout.

## [0.1.0] — 2026-04-21

### Added
- Initial release.
- `/cost` skill for on-demand usage breakdowns (by model, by project, window / today / month).
- Stop hook that refreshes the statusline cache after each assistant response.
- Legacy v1 statusline (`claude-cost.sh`) — compact one-line cost + 5h window.
- Optional macOS menu bar app (`macos/menu_bar.py`) with LaunchAgent install.
- Plan-aware labeling: subscription users see `eq` suffix on API-equivalent costs.
- Heuristic auth-mode detection without reading `~/.claude/.credentials.json` contents.
