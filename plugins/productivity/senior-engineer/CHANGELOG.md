# Changelog

All notable changes to **senior-engineer** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-04-21

### Added
- Initial release.
- `junior-engineer` subagent (`agents/junior-engineer.md`) — implements one ticket per invocation inside a pre-prepared git worktree, returns a structured report (status, commit SHA, files changed, tests, risks, open questions). Model: `sonnet`. Tools: Read/Write/Edit/Glob/Grep/Bash. No `Agent` tool, no `isolation: worktree` (worktrees are hand-rolled by the dispatch skill for deterministic branch naming).
- `/senior-engineer:dispatch` skill — takes Jira IDs and/or free-form task descriptions, resolves Jira via the Atlassian MCP (soft reference, mirrors `notes-integrations` style), creates one worktree per ticket under `<repo_root>/.worktrees/`, dispatches all juniors in parallel from a single assistant turn, collects their reports, runs a senior review pass, and presents a consolidated summary for user approval. Never runs `gh pr create`.
- `/senior-engineer:review` skill — read-only deeper review of one worktree; updates `senior_verdict` + `senior_notes` in the dispatch state file. No git side effects.
- `/senior-engineer:open-pr` skill — the only skill that runs `gh pr create`. Gated by (a) explicit user invocation and (b) `senior_verdict == "approved_by_senior"`. Pushes the branch, writes a body file, creates the PR via `gh`, captures the URL. Optional macOS notification via `osascript` when `macos_notifications: true` in the daily-notes profile.
- `/senior-engineer:abort` skill — removes worktrees and (when no PR exists) deletes branches. Always confirms before destructive ops. Preserves branches with open PRs.
- `.worktrees/.senior-state.json` as the single cross-invocation source of truth.
- `.worktrees/` auto-added to `.git/info/exclude` on first dispatch.

### Compatibility

- Claude Code 1.x — uses standard subagent frontmatter and skill YAML format.
- Optional: Atlassian MCP for Jira ticket resolution. Without it, only free-form task descriptions are accepted.
- Optional: `gh` CLI (authed) for PR creation. Required only for `/senior-engineer:open-pr`.
- Optional: macOS for the `osascript` notification (quietly skipped elsewhere).
