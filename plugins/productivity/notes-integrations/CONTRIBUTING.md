# Contributing to notes-integrations

## Technical architecture

### Plugin layer diagram

`notes-integrations` is a consumer-only plugin. It reads and writes the same local files as `daily-notes` but never declares its own MCP server configs — it relies on MCPs the user has already configured in their Claude Code session.

```mermaid
flowchart TB
    subgraph ext["External MCPs (user-configured)"]
        AT["☁️ Atlassian (Jira)"]
        UB["☁️ Unblocked"]
    end

    subgraph ni["notes-integrations skills"]
        jp["/jira-pull"]
        jpush["/jira-push"]
        tn["/enrich-tickets"]
        mc["/enrich-meeting"]
        recap["/recap"]
        rn["/release-notes"]
    end

    subgraph local["Local files (shared with daily-notes)"]
        TF["📁 Tasks/"]
        SP["📄 Scratch Pad.md"]
        MF["📁 Meetings/ & People/"]
        DN["📁 Daily Notes/"]
    end

    AT --> jp --> TF
    TF --> jpush --> AT
    AT --> tn
    SP --> tn --> SP
    UB --> mc --> MF
    TF & MF & DN --> recap
    AT -.->|optional| recap
    TF --> rn
    AT -.->|optional enrichment| rn

    %% /start (in daily-notes) reads Atlassian when available
    AT -.->|optional, via daily-notes /start| TF
```

### Jira sync — data directions

```mermaid
flowchart LR
    J["☁️ Jira"]
    L["📁 Tasks/"]
    S["📄 Scratch Pad.md"]

    J -->|"/jira-pull — import open tickets"| L
    L -->|"/jira-push — resolve drift"| J
    J -.->|"daily-notes /start — read-only status check"| L
    J -->|"/enrich-tickets — enrich references"| S
```

### MCP dependency rules

- **Do not bundle MCP server configs** in `plugin.json`. This plugin must not conflict with other marketplaces (e.g. `poe-foundation-plugin`) that ship the same Atlassian or Unblocked MCPs.
- Each skill must check MCP availability at the start of its run and fail with a clear message — never silently degrade in ways that corrupt local files.
- `/recap` and `/release-notes` have no MCP hard dependency — Atlassian is offered as optional enhancement on top of a local-only base report. Both must always run (and print a source line) even when no MCP is registered.

### Status mapping — Jira ↔ local

| Local status | Jira equivalent |
|---|---|
| `open` | To Do |
| `in-progress` | In Progress |
| `in-review` | In Review |
| `done` | Done |
| `blocked` | *(no equivalent — flag to user)* |

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with `description:` frontmatter and natural-language steps.
2. Document which MCP(s) are required and add graceful fallback if unavailable.
3. Update `README.md` — add to skills table (include MCP required column) and add a usage example.
4. Update the Prerequisites table if a new MCP is introduced.
5. Update this file — add the skill to the architecture diagram.
6. Bump the minor version in `plugin.json`.
