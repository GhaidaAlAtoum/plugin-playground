---
description: Aggregate shipped, in-progress, and carryover tasks into changelog-style release notes — local-first, optional Atlassian enrichment
---

Generate changelog-style release notes from local tasks for a release label or time window. Primarily for POs (`role: po`) and engineers cutting a release.

## Local-first — Atlassian MCP is additive

This skill **always runs** using local task files as the primary source:
- Reads `Tasks/*.md` and `Tasks/Archive/*.md` with a matching `release:` frontmatter field, or a `jira:` key if running by window.
- Title, status, and description come from the local task file frontmatter.

If the Atlassian MCP is registered in the current session, the skill **enriches** items that have a `jira:` key with canonical title/status/URL from Jira. Non-Jira tasks are never touched by enrichment. The skill always prints which source was used so the user knows whether enrichment happened.

## Steps

1. **Parse arguments**: The first argument is either a release **label** or a **time window**.
   - Window shorthands (same syntax as `/recap`): `last week`, `last month`, `last quarter`, `this week`, `this month`, `this quarter`, `YYYY-MM-DD to YYYY-MM-DD`.
   - Anything else is treated as a release label (e.g. `v2.4`, `Q2-2026`, `april-release`).
   - Bare `/release-notes` with no argument: ask the user whether they want a label or a window.

2. **Scan tasks**: Glob `Tasks/*.md` and `Tasks/Archive/*.md`. Read frontmatter on each:
   - **Label mode**: include tasks whose `release:` frontmatter matches the label (exact string match).
   - **Window mode**: include tasks where `completedDate` falls in the range, OR tasks where `status` is `in-progress` / `in-review` / `blocked` and the file `mtime` falls in the range.

3. **Bucket by status**:
   - **Shipped** — `status: done` (all included tasks qualify if matched by `completedDate` in window mode, or `release:` label match with `status: done`).
   - **In progress** — `status: in-progress` or `in-review`.
   - **Carryover / blocked** — `status: blocked`, or `status: open` whose file `mtime` is older than the window start / whose `release:` matches but status is not done.

4. **MCP availability check**: At this point, determine whether an Atlassian MCP is registered in the current session.
   - **Available** — print one line before the report:
     ```
     Atlassian MCP detected — enriching Jira-keyed items with canonical title/status/URL.
     ```
     Then, for every task in the report with a `jira:` key, fetch its live title/status/URL and override the local frontmatter values in the output. Local task files are not rewritten.
   - **Unavailable** — print the standard error-pattern line and continue:
     ```
     ⚠️  Atlassian MCP not available — running local-only. Jira titles and statuses come from your task files (may be stale). Run /doctor to diagnose.
     ```

   Never abort. Never silently degrade. Local-only is a first-class mode.

5. **Present release notes** (plain markdown):
   ```
   ## Release Notes — <label or window>

   Source: <local-only | local + Atlassian MCP>

   ### Shipped (N)
   - [POE-1234] Migrate auth tokens — done 2026-04-12
   - Fix login bug — done 2026-04-14

   ### In progress (N)
   - [POE-1289] Rate limiter — in-progress

   ### Carryover / blocked (N)
   - [POE-1301] API rate limiting — blocked on infra approval
   ```

   When enrichment ran, append Jira URLs to enriched items: `[POE-1234](https://.../POE-1234) Migrate auth tokens`.

6. **Export option**: After presenting, offer to write the report to `Releases/<label>.md` (or `Releases/YYYY-MM-DD-recap.md` in window mode). Ask before writing — never auto-write. Create `Releases/` if it doesn't exist.

## Rules

- Read-only by default. Only writes the exported file if the user explicitly confirms step 6.
- **Never fabricate** ticket titles, statuses, or URLs. If a `jira:` key is present but the MCP is unavailable, use the title from the local task file and note it may be stale (already covered by the unavailable branch message).
- **Always print the source line** (`local-only` or `local + Atlassian MCP`) so the user knows whether enrichment happened.
- Skip empty buckets — don't show "### Shipped (0)".
- Label matching is case-sensitive and exact. If the user expects `v2.4` but tasks have `release: V2.4`, surface a one-line tip.
