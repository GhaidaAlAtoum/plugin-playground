# Changelog

All notable changes to **claude-tracker** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] — 2026-04-21

### Added
- `transcript_summary()` helper in `tracker_core.py` — sums cost/usage for a single Claude Code session from its transcript file.
- New `💬 Session` statusline segment showing current CLI session cost, driven by `transcript_path` from the statusline stdin payload.
- README "Three 5h windows" terminology table clarifying Claude Code session vs Anthropic 5h pricing block vs subscription rate-limit window.
- Default layout now recommends ccstatusline's built-in **`ThinkingEffort`** widget on line 2, showing the current thinking level (`low` / `medium` / `high` / `max`). Requires ccstatusline v2.3+.
- 5h segment now shows the local clock time of the next reset alongside remaining duration (e.g. `1h28m → 6pm`), matching the reset hour `/usage` displays for the subscription.
- `install-ccstatusline.sh` auto-refreshes Custom Command `commandPath` strings in `~/.config/ccstatusline/settings.json` on upgrade, so users don't have to re-paste into the TUI after a plugin version bump. Backup written to `.bak`.
- `detect_auth_mode()` now checks the macOS Keychain (`security find-generic-password -s "Claude Code-credentials"`) for OAuth credentials. Claude Code on recent macOS builds stores creds in Keychain instead of `~/.claude/.credentials.json`, which was causing subscription users to fall through to `unknown`. Metadata-only lookup — does not unlock or read the credential.

### Changed
- Statusline 5h segment displays `Xh Ym → 6pm` aligned to the clock hour (approximates `/usage` subscription reset) instead of `X left` from the exact first-message timestamp. Entry filtering for the cost calculation still uses the exact block start, so the displayed cost is unchanged.
- Default `install-ccstatusline.sh` layout: bottom row is now `block · session` instead of `block · month`.
- Statusline `eq` suffix now appears for every auth mode *except* `api_key` (previously: only `subscription`). Subscription users whose auth_mode couldn't be detected (Keychain miss on older code, non-mac OAuth flows) were seeing a bare `$1,004.94 mo` that read like an actual bill. Now they get `$1,004.94 mo eq`, making it clear the figure is API-equivalent. Applies to `render_segments.py`, legacy `claude-cost.sh`, and the macOS menu bar app.
- Statusline cache moved from `$TMPDIR/claude-tracker-status.*` to `~/.claude/.cache/claude-tracker-status.*`. macOS periodically purges per-user temp dirs, which was causing intermittent `$—.—— mo` dashes during active use until the background refresher rebuilt the cache. The new location survives across reboots and temp-dir cleanup. `stop-invalidate-cache.sh` also clears the old TMPDIR paths so upgrades don't leave orphaned cache files behind.

### Fixed
- Fixed stuck `resetting now` on the 5h segment when the first-message minute wasn't `:00`. `block_window` now hour-anchors `block_start` before rolling, so the `now < end` invariant is preserved through the full 5h window instead of being broken by a display-time floor that moved `end` backward by up to 59 min.
- `block_window` rolls `block_start` forward in fixed 5h increments during continuous use — and against `now` itself — so the bar doesn't get stuck on an old window when activity spans a rollover.

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
