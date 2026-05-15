# HARNESS — [PROJECT_NAME]

> Read this file first. Every agent, every session, starts here.

---

## Project

**Name:** [PROJECT_NAME]
**Stack:** [STACK — e.g., Node.js + TypeScript + PostgreSQL]
**Description:** [One paragraph describing what this project does and its primary purpose.]

---

## Harness Level

**Active Level: 1** (Spec Only)

- Level 1: specs + tasks + contracts + memory ← you are here
- Level 2: + decisions + research + rules + skills + MCP
- Level 3: + sensors + two-agent validation + audit

Upgrade when you're ready: add the Phase 2 or Phase 3 files from the rig-spec templates.

---

## Current Focus

**Active Feature:** none
**Next Task:** none

→ Create your first spec: `feedforward/specs/_TEMPLATE.spec.md`

---

## Context Reconstruction

To pick up where you left off in any new session, read in this order:

1. This file (HARNESS.md)
2. `memory/progress.md` — what's done and what's next
3. `memory/decisions.md` — key decisions made (when exists)
4. The active spec in `feedforward/specs/`
5. The current task in `feedforward/tasks/`

Full instructions: `memory/bootstrap.md`

---

## Available Skills

[Add skills here as you create them in feedforward/skills/]
- None configured yet → see `feedforward/skills/_TEMPLATE.skill.md`

## MCP Servers

[Add MCP servers here when configured]
- None configured yet → see `feedforward/mcp.config.md` (Level 2)

## Active Sensors

- None (Level 1 — manual contract validation)
- Add sensors in `feedback/sensors/` to upgrade to Level 3

---

## Key Files

| File | Purpose |
|---|---|
| `feedforward/specs/` | Feature specifications |
| `feedforward/tasks/` | Task breakdowns per spec |
| `feedforward/rules/` | Coding conventions and architecture rules |
| `feedforward/skills/` | Specialized local knowledge |
| `feedback/sensors/` | Automated validation commands |
| `memory/progress.md` | Current state of all work |
| `memory/decisions.md` | Architectural decisions |
| `memory/research/` | Research session findings |
| `orchestration/contracts/` | Implementer-validator agreements |
