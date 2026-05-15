# MCP Configuration

> Level 2 — MCP servers available to agents in this project.
> Agents load these only when relevant to the current task — not all at once.

---

## Configured Servers

[Add an entry for each MCP server configured for this project.]

### [server-name]

**Purpose:** [What real-time context this server provides]
**When to use:** [Which task types benefit from this server]
**Config file:** `[path to .mcp config file]`

**Usage example:**
```
[How the agent should invoke this server for common tasks]
```

---

## Notes

- MCP servers declared here supplement the static files in `.rig/` — they are not a replacement.
- If a server is unavailable, fall back to the static files in `memory/research/`.
- Never load all servers simultaneously — only what the current task needs.
