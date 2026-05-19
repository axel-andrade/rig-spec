# MCP Configuration

> Level 2 — MCP servers available to agents in this project.
> Agents load these only when relevant to the current task — not all at once.
> Loading all servers simultaneously degrades performance — use progressive disclosure.

---

## Suggested Servers

Uncomment and configure the servers that apply to this project.

---

### context7 *(recommended)*

**Purpose:** Provides up-to-date library documentation beyond the model's training cutoff — correct API signatures, current config options, migration guides.
**When to use:** Any task that touches third-party libraries, framework configuration, or recently changed APIs.
**Config:** Add to your MCP client config as `@upstash/context7-mcp` or via `npx @context7/mcp`.

**Usage example:**
```
use context7 to get the latest docs for [library-name]@[version]
```

---

### brave-search *(recommended)*

**Purpose:** Real-time web search for current information — error messages, changelogs, community solutions, CVE advisories.
**When to use:** Research tasks, debugging unfamiliar errors, checking if a library issue is known upstream.
**Config:** Requires a Brave Search API key. See [brave.com/search/api](https://brave.com/search/api).

**Usage example:**
```
search for "[error message]" site:github.com
```

---

### filesystem

**Purpose:** Explicit filesystem access outside the project directory — useful when the agent needs to read global config, reference other projects, or write to a location outside `.rig/`.
**When to use:** Cross-project tasks, reading `~/.config/` entries, scaffolding in a different directory.
**Config:** Ships with most MCP clients. Scope to specific allowed paths for safety.

**Usage example:**
```
read ~/.config/[tool]/config.yaml to check the current settings
```

---

## Project-Specific Servers

[Add entries for MCP servers specific to this project's stack or domain.]

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
- If a server is unavailable, fall back to `memory/research/` for cached findings.
- Never load all servers simultaneously — only what the current task needs.
- context7 and brave-search address the knowledge cutoff problem: use them before writing code that depends on a library version newer than mid-2025.
