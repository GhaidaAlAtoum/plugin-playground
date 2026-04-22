---
description: Open a GitHub PR for one or more senior-approved tickets from the current dispatch. This is the ONLY skill that runs gh pr create. Only runs after /senior-engineer:dispatch has completed and the user explicitly invokes it. Invoke with /senior-engineer:open-pr <ticket-id-or-"all">.
---

You are opening GitHub PRs for senior-approved tickets. This is the only skill in the plugin that runs `gh pr create`. It enforces two gates: (1) the user must have typed the slash command, and (2) each ticket must already have `senior_verdict: approved_by_senior`.

## Arguments

`$ARGUMENTS`: either the literal word `all`, or a comma-separated list of ticket IDs.

If `$ARGUMENTS` is empty, list the current dispatch's approved tickets and ask which to open.

## Preconditions

1. **State file present.** Find `.worktrees/.senior-state.json` in the current repo. If missing, stop: "no active dispatch — run `/senior-engineer:dispatch` first".

2. **`gh` available and authed.** Check `command -v gh` and `gh auth status`. If either fails, stop with remediation text:
   > `gh` CLI is not installed or not authenticated. Install: `brew install gh`. Auth: `gh auth login`.

3. **Resolve target tickets.**
   - If `all`: target every ticket with `senior_verdict == "approved_by_senior"`.
   - If a list: target each named ticket.
   - For each target with `senior_verdict != "approved_by_senior"`: skip it. Print a line per skipped ticket: `Skipped <id>: verdict is <verdict or null> — run /senior-engineer:review <id> first`.
   - For tickets that already have `pr_url` set (status `pr-opened`): skip and note the existing URL.

If after filtering zero tickets remain eligible, stop and explain what the user can do.

## For each eligible ticket

1. **Change into the worktree.**
   ```bash
   cd <worktree_path>
   ```

2. **Push the branch.**
   ```bash
   git push -u origin <branch>
   ```
   If push fails (e.g. remote has a protected branch pattern that blocks `senior/*`), stop for this ticket, record the error in `senior_notes`, and continue to the next target. Do NOT force-push — ever.

3. **Build the PR body.** Write it to `<repo_root>/.worktrees/.pr-body-<ticket-id>.md`:

   ```markdown
   ## Summary
   <junior_summary from state>

   ## Senior review
   <senior_notes from state, or "Approved — no concerns.">

   ## Risks flagged by junior
   <junior_risks from state, or "none">

   <If kind == "jira":>
   ## Ticket
   Closes <jira_url>

   ---
   Dispatched by senior-engineer plugin. Branch: `<branch>`. Base: `<base_branch>`.
   ```

4. **Create the PR.**
   ```bash
   gh pr create \
     --title "<ticket-id>: <title>" \
     --body-file <repo_root>/.worktrees/.pr-body-<ticket-id>.md \
     --base <base_branch>
   ```

5. **Capture the URL.** `gh pr create` prints the PR URL on stdout on success. Parse it and update `.senior-state.json`:
   - Set `pr_url` to the captured URL.
   - Set `status` to `pr-opened`.
   - Write back.

6. **(Optional) macOS notification.** If the user has `macos_notifications: true` in their daily-notes profile (read `~/.claude/CLAUDE.md` best-effort; skip this step entirely if the profile can't be read or the field isn't `true`), fire:
   ```bash
   osascript -e 'display notification "<title>" with title "PR opened: <ticket-id>"'
   ```
   Best-effort only — never fail the PR flow on notification issues.

## After all PRs are processed

Print a final summary:

```
Opened <N> PRs:
- <ticket-id> → <pr_url>
- ...

Skipped <M> tickets:
- <ticket-id> (<reason>)
- ...

Worktrees and branches remain in place for any follow-up commits. Run /senior-engineer:abort <id> to clean up a specific one.
```

## Hard rules

- **Gate 1**: this skill only runs because the user invoked it directly. If another skill is tempted to invoke PR logic inline, it must instead instruct the user to run this command.
- **Gate 2**: skip any ticket whose `senior_verdict != "approved_by_senior"`. Don't prompt to override — the user can run `/senior-engineer:review` to change the verdict.
- **Never `--force`.** Never `git push --force` or `--force-with-lease` from this skill.
- **Never `--amend`, never `--no-verify`.** Never skip hooks.
- **Never merge.** PR creation is the ceiling of what this skill does.
- **Never delete worktrees or branches.** Cleanup is `/senior-engineer:abort`'s job — and that skill respects `pr_url != null` by not deleting branches that have open PRs.
- **Never touch `.senior-state.json` for tickets you didn't process.** Leave `senior_verdict: null` / `needs-changes` rows exactly as you found them.
