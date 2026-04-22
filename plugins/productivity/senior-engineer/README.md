# senior-engineer

Orchestrate a batch of tickets as parallel git worktrees, each worked by a junior-engineer subagent — with a mandatory human review gate before any GitHub PR opens.

Give the senior a list of Jira IDs or free-form task descriptions. It plans the work, creates one git worktree per ticket, dispatches junior-engineer subagents in parallel, reviews what each produced, and hands you a consolidated summary. Nothing gets pushed, nothing becomes a PR, until you explicitly say so.

---

## Skills

| Skill | Invoke | What it does |
|-------|--------|--------------|
| Dispatch | `/senior-engineer:dispatch <ids-or-tasks>` | Plan, create worktrees, dispatch juniors in parallel, review, present for approval |
| Review | `/senior-engineer:review <ticket-id>` | Deeper read-only review of one worktree; updates the senior's verdict |
| Open PR | `/senior-engineer:open-pr <ids-or-"all">` | The only skill that runs `gh pr create`. Gated by senior approval + explicit user invocation |
| Abort | `/senior-engineer:abort <ids-or-"all">` | Remove worktrees and (if no PR exists) delete branches |

---

## Setup guide

### 1. Prerequisites

| Requirement | Why | How to check |
|---|---|---|
| Claude Code CLI | Host for the plugin, skills, and subagent | `claude --version` |
| `git` ≥ 2.15 | `git worktree` support | `git --version` |
| `gh` CLI (authenticated) | PR creation in `/senior-engineer:open-pr` only. Not required for dispatch/review/abort. | `gh auth status` |
| Atlassian MCP (optional) | Resolving Jira IDs like `POE-1234`. Without it, only free-form tasks work. | `/daily-notes:doctor` lists detected integrations — or try `/senior-engineer:dispatch POE-1` in a throwaway repo and watch for the "Atlassian MCP not available" warning. |
| macOS (optional) | `osascript` notifications on PR open. Silently skipped elsewhere. | `uname` → `Darwin` |

### 2. Install the plugin

```bash
# Add the marketplace (skip if already added)
claude plugin marketplace add ghaidaatoum/plugin-playground
```

Then from inside Claude Code:
```
/plugin install senior-engineer@plugin-playground
```

Restart Claude Code once after install so the new subagent and skills are registered.

### 3. Verify both agent levels

**Junior subagent** — run `/agents` and confirm you see:
```
senior-engineer:junior-engineer
```
If it's missing: the plugin didn't install correctly. Run `/plugin list` to check status; reinstall if needed.

**Senior skills** — type `/senior-engineer:` and your Claude Code completer should show four commands:
- `/senior-engineer:dispatch`
- `/senior-engineer:review`
- `/senior-engineer:open-pr`
- `/senior-engineer:abort`

If the completions don't appear, restart Claude Code (skills are read at startup).

### 4. One-time repo prep (per target repo)

The first time you run `/senior-engineer:dispatch` inside a repo, the dispatch skill automatically:
- Creates `<repo_root>/.worktrees/`
- Appends `.worktrees/` to `.git/info/exclude` so it never shows up in `git status`
- Detects the base branch from `origin/HEAD` (falls back to `main`, then `master`)

Nothing else to do. If the repo has an unusual base-branch setup (e.g. a trunk branch that isn't `main`/`master`), make sure `origin/HEAD` points at it:
```bash
git remote set-head origin <trunk-branch>
```

### 5. (Optional) Wire the Atlassian MCP for Jira

This plugin uses whatever Atlassian MCP is already configured in your Claude Code session — same pattern as the `notes-integrations` plugin in this marketplace. If you already use `/jira-pull` or `/enrich-tickets`, the MCP is wired and this plugin will use it automatically. If not, add an Atlassian MCP in your Claude Code settings. Without it, `/senior-engineer:dispatch` still works with free-form task descriptions — Jira IDs just fail cleanly.

### 6. First smoke test

In a throwaway git repo with a remote, run:
```
/senior-engineer:dispatch Add a brief comment to README.md explaining the project; Append "hello from junior 2" to README.md on its own line
```

Expected flow:
1. Plan table showing 2 free-form tickets, `[y/n/edit]` prompt.
2. On `y`: two worktrees appear under `.worktrees/` (check with `git worktree list`).
3. The transcript shows **one assistant turn containing two `Agent` tool calls** — that's the parallelism.
4. Both juniors return structured reports.
5. Consolidated summary ends with "None of these are PRs yet."
6. `gh pr list` shows nothing new.

Then approve:
```
/senior-engineer:open-pr all
```
Two PRs should appear on GitHub. Clean up after:
```
/senior-engineer:abort all
```

### 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `/senior-engineer:*` not in completer | Skills haven't loaded | Restart Claude Code |
| `/agents` doesn't list `senior-engineer:junior-engineer` | Plugin not fully installed | `/plugin list`, then reinstall |
| "not inside a git repository" | Dispatch run outside a repo | `cd` into the target repo first |
| "no default branch found" | `origin/HEAD` missing and neither `main` nor `master` exists | `git remote set-head origin <your-trunk>` |
| "⚠️ Atlassian MCP not available" | MCP not configured (or wrong session) | Add the Atlassian MCP, or use free-form task descriptions instead |
| `gh auth status` shows "not logged in" | `gh` not authed | `gh auth login` |
| Juniors ran serially (one turn per junior) | Dispatch skill split calls across turns | This breaks parallelism — report as a plugin bug; re-run dispatch |
| `git worktree add` fails with "already exists" | Prior dispatch didn't clean up | `/senior-engineer:abort all`, then `rm -rf .worktrees/` if needed |
| PR body looks empty | State file lost junior summary | Check `.worktrees/.senior-state.json` for the ticket; re-run `/senior-engineer:review <id>` before `/senior-engineer:open-pr` |

---

## Quick start

From inside any git repo:

```
/senior-engineer:dispatch POE-1234, POE-1240, Fix nav dropdown alignment
```

The senior will:
1. Fetch POE-1234 and POE-1240 from Jira (needs the Atlassian MCP).
2. Treat "Fix nav dropdown alignment" as a free-form task.
3. Show you the plan → you confirm `y`.
4. Create three git worktrees under `.worktrees/`.
5. Dispatch three juniors in parallel (a single assistant turn with three `Agent` calls).
6. Review each junior's work.
7. Present a consolidated summary and ask you what to do.

No PR is opened. When you're ready:

```
/senior-engineer:open-pr all
```

Only tickets with verdict `approved_by_senior` become PRs. The rest are listed as skipped with next-step instructions.

---

## Architecture: why the senior is a skill, not a subagent

Claude Code subagents **cannot spawn other subagents**. If the senior were itself a subagent, its `Agent(...)` tool calls would silently no-op. So the "senior engineer" is a set of skills that run in the main Claude Code thread — the main thread adopts the senior persona for the duration of a dispatch, and it is the only place the `Agent` tool actually works to spawn juniors.

The junior IS a real subagent (`agents/junior-engineer.md`). It's the only subagent in this plugin. Juniors run in parallel when the dispatch skill issues one `Agent` tool call per ticket in a single assistant turn.

Worktrees are **hand-rolled** by the dispatch skill rather than using the `isolation: worktree` frontmatter field. Three reasons:
- Auto-worktrees get opaque branch names (`worktree-agent-<hash>`) — not compatible with `senior/POE-1234-...` naming.
- Auto-worktrees are cleaned up when a blocked junior makes no changes — destroying the evidence you need to review.
- There are open Claude Code issues about `isolation: worktree` silently failing.

Hand-rolling is a handful of `git worktree add` commands with deterministic branch names and full persistence.

---

## Jira integration

Resolution of `[A-Z]+-\d+`-shaped arguments uses the Atlassian MCP — same soft-reference style as `notes-integrations` (no hard-coded tool names). If the MCP is not configured, Jira IDs fail cleanly and free-form descriptions still work. This plugin has no formal dependency on an MCP; it uses whatever is configured in your Claude Code session.

---

## State

Each dispatch writes `<repo_root>/.worktrees/.senior-state.json` — the source of truth across slash-command invocations (each invocation is a fresh skill run, no in-memory state carries over). See `skills/dispatch/SKILL.md` for the schema.

`.worktrees/` is added to `.git/info/exclude` automatically so it never appears in `git status`.

---

## Safety posture

- The dispatch skill NEVER runs `gh pr create` or `git push`.
- The open-pr skill is the only place PRs are created; it requires (a) explicit user invocation and (b) `senior_verdict == "approved_by_senior"`.
- Juniors never push, merge, force-push, amend, or skip hooks.
- Abort preserves branches that have open PRs; worktrees are removed but the remote-facing state is untouched.
