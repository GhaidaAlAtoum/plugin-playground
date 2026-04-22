---
description: Deeper senior review of a single ticket's worktree. Read-only — no git side effects. Use when the user wants a more thorough review of a junior's work before deciding whether to approve for PR. Invoke with /senior-engineer:review <ticket-id>.
---

You are running a deeper senior review on one junior's worktree. This skill never modifies git state; it only reads the diff, evaluates quality, and updates `senior_verdict` + `senior_notes` in the dispatch state file.

## Arguments

`$ARGUMENTS` must be a single `<ticket-id>`. If missing or ambiguous, list the current dispatch's tickets from `.senior-state.json` and ask which one.

## Steps

1. **Locate state.** Find `.worktrees/.senior-state.json` in the current repo (`git rev-parse --show-toplevel`). If missing, stop: "no active dispatch in this repo".

2. **Look up the ticket** by id in `state.tickets`. If not found, list available ids and stop. If `status` is not `ready-for-review`, stop and explain — you can only review completed juniors.

3. **Deep read.** From the main thread:
   - `cd <worktree_path> && git log --format='%H%n%an <%ae>%n%s%n%n%b' <base_branch>..HEAD` — full commit message.
   - `cd <worktree_path> && git diff <base_branch>...HEAD` — full diff, not just the stat.
   - Read each changed file in full (not just the hunks) to assess context.
   - Check for tests: look at what test files are changed and whether they exercise the new/changed behavior.

4. **Evaluate.** Form opinions on:
   - **Scope**: are the changes limited to what the ticket asked for? Any drive-by edits?
   - **Tests**: does the test coverage exercise the new behavior and the unhappy paths?
   - **Correctness**: obvious bugs, off-by-one, missing error handling at boundaries, race conditions?
   - **Security**: user-input validation, injection, credential handling, path traversal — only at boundaries, not internal code.
   - **Style / fit**: does the change follow the patterns already in this file / module?
   - **Commit**: is the message clear and the `Refs: <id>` line present?

5. **Render the review** to the user. Suggested shape:

   ```
   ## Review: <ticket-id>  <title>
   Branch: <branch>   Commit: <sha>   Files: <N>

   ### Scope
   <one paragraph>

   ### Tests
   <one paragraph — what's covered, what's missing>

   ### Concerns
   - <specific issue, with file:line if applicable>
   - ...

   ### Verdict
   <approved_by_senior | needs-changes | reject>

   <If needs-changes or reject: 2-3 concrete next steps for the junior, or for the user to redispatch with clarification>
   ```

6. **Update state.** Set `senior_verdict` and `senior_notes` (serialize the Concerns + next steps into `senior_notes`). Write `.senior-state.json` back.

## Hard rules

- **Read-only against git.** No commits, no checkout, no branch ops, no push.
- **Do not modify the worktree** — no Edits, no Writes to files inside `<worktree_path>`.
- If the user wants changes made, point them at re-dispatching the ticket with clearer acceptance criteria, or at making the edits themselves in the worktree.
- Never run `gh` from this skill.
