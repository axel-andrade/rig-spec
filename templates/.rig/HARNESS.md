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

## Project Standards

→ **`STANDARDS.md`** — index of all coding/architecture/UI rules (`feedforward/rules/`)

→ **`feedforward/skills.registry.md`** — automatic skill routing on `rig-spec run`

## Available Skills

- None configured yet → see `feedforward/skills/_TEMPLATE.skill.md`

## MCP Servers

- None configured yet → see `feedforward/mcp.config.md` (Level 2)

## Active Sensors

- None (Level 1 — manual contract validation)

## Git Workflow

**Branch per feature:** create a branch from `main` when starting a spec.

```
git checkout -b feat/[feature-name]
```

**Commit per task:** after `rig-spec validate` passes and the task is marked done, commit the work.

```
git add -p
git commit -m "feat([feature-name]): [task-id] — [one line summary]"
```

**Merge when the spec is complete:** all tasks done, all sensors green, audit clean.

```
git checkout main && git merge --no-ff feat/[feature-name]
```

> Agents must not commit on behalf of the human unless explicitly instructed. The commit step belongs to the human after `rig-spec done`.

---

## Key Files

| File | Purpose |
|---|---|
| `feedforward/specs/` | Feature specifications |
| `feedforward/tasks/` | Task breakdowns per spec |
| `STANDARDS.md` | Index of patterns (architecture, naming, UI tokens) |
| `feedforward/rules/` | Coding conventions and architecture rules |
| `feedforward/skills.registry.md` | Auto skill routing by task keywords |
| `feedforward/skills/` | Specialized local knowledge |
| `feedback/sensors/` | Automated validation commands |
| `feedback/reports/` | Validation reports from `rig-spec validate` |
| `memory/progress.md` | Current state of all work |
| `memory/decisions.md` | Architectural decisions |
| `memory/learnings.md` | Implementation discoveries and gotchas |
| `memory/research/` | Research session findings |
| `orchestration/contracts/` | Implementer-validator agreements |
