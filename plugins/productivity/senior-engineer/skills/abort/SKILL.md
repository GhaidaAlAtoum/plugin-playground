---
description: Discard one or more dispatched tickets and clean up their worktrees + branches. Use when a junior's work was wrong, a senior review said "reject", or you just want to tear down an in-flight dispatch. Invoke with /senior-engineer:abort <ticket-id-or-"all">.
---

You are tearing down worktrees and branches created by a senior-engineer dispatch. This is the cleanup counterpart to `/senior-engineer:dispatch`.

## Arguments

`$ARGUMENTS`: either the literal word `all`, or a comma-separated list of ticket IDs.

If `$ARGUMENTS` is empty, list the current dispatch's tickets and ask which to abort.

## Preconditions

1. **State file present.** Find `.worktrees/.senior-state.json` in the current repo. If missing, stop: "no active dispatch in this repo".

2. **Resolve targets.**
   - If `all`: every ticket in the state file.
   - If a list: each named ticket; print a line per unknown id and continue.

3. **Confirm destructive cleanup.** Before doing anything, list what will be removed:
   ```
   About to abort and clean up:
     - <ticket-id>  branch=<branch>  worktree=<path>  pr=<pr_url or "none">
     - ...

   Proceed? [y/n]
   ```
   Wait for `y`. On `n`: stop.

   **If any target has `pr_url != null`**, emphasize in the confirmation:
   > ⚠️  <ticket-id> has an open PR at <pr_url>. Abort will REMOVE the worktree but LEAVE the branch and the PR intact. Continue? [y/n]

## For each target

1. **Remove the worktree.**
   ```bash
   git worktree remove --force <worktree_path>
   ```
   `--force` is required because a `blocked` or `failed` junior may have left uncommitted debris. If the worktree no longer exists on disk, skip this step silently.

2. **Delete the branch — only if no PR was opened.**
   - If `pr_url == null`: `git branch -D <branch>`. If the branch doesn't exist, skip silently.
   - If `pr_url != null`: LEAVE the branch alone. Print a reminder: `Kept branch <branch> because PR exists at <pr_url>.`

3. **Remove the PR body file** if it exists: `rm -f <repo_root>/.worktrees/.pr-body-<ticket-id>.md`.

4. **Drop the ticket entry** from `state.tickets[]`. Write `.senior-state.json` back.

## After all targets are processed

- If `state.tickets[]` is now empty: delete `.senior-state.json` entirely.
- If the `.worktrees/` directory is now empty (apart from the state file, if it still exists): leave it — `.git/info/exclude` still covers it and it's the expected location for the next dispatch.

Print a final summary:

```
Aborted <N> tickets:
- <id>   worktree removed, branch deleted
- <id>   worktree removed, branch kept (PR <pr_url>)
- ...
```

## Hard rules

- **Always confirm before destructive ops.** Even with `$ARGUMENTS=all`, print the list and wait for `y`.
- **Never delete a branch that has an open PR.** Only `git worktree remove` in that case.
- **Never push.** Never touch remote refs.
- **Never `git reset --hard` on any branch.** Branch deletion via `git branch -D` is the most we do, and only on senior-created branches matching `senior/*`.
- **Never delete worktrees outside `<repo_root>/.worktrees/`.**
