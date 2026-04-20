# plugin-playground

A Claude Code plugin marketplace focused on personal productivity — a lightweight, file-based note-taking and task-tracking system that lives in your project folder.

## Plugins

| Plugin | Summary |
|---|---|
| [**daily-notes**](plugins/productivity/daily-notes/README.md) | Scratch pad → `/sync` → tasks, talking points, meetings, and a daily log. Works out of the box. Optional Obsidian and per-person contact tracking. |
| [**notes-integrations**](plugins/productivity/notes-integrations/README.md) | MCP-powered enrichment layer on top of `daily-notes`: pull Jira tickets into tasks, surface Unblocked context in meeting notes, integrate with Google Calendar, generate time-window recaps. Requires `daily-notes`. |

`daily-notes` is standalone. `notes-integrations` layers on top of it and depends on it — install `daily-notes` first if you plan to use both.

## Install

```bash
claude plugin marketplace add ghaidaatoum/plugin-playground
```

Then open `/plugin` in Claude Code, go to the **Discover** tab, and install whichever plugins you want.

To try it locally without publishing to GitHub:

```bash
claude plugin marketplace add /Users/ghaidaatoum/plugin-playground
```

## Layout

```
plugin-playground/
├── .claude-plugin/
│   └── marketplace.json          # marketplace manifest
├── plugins/
│   └── productivity/
│       ├── daily-notes/
│       │   └── .claude-plugin/plugin.json
│       └── notes-integrations/
│           └── .claude-plugin/plugin.json
├── README.md
└── LICENSE
```

Each plugin carries its own `README.md`, `CONTRIBUTING.md`, and `skills/` directory. See individual plugin READMEs for skill reference, configuration options, and usage examples.

## License

MIT — see [LICENSE](LICENSE).
