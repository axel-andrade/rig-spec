# rig-spec — Architecture

> How the framework is structured, why each layer exists,
> and how everything connects.

---

## Core Principle: The Harness Lives Beside the Project

`rig-spec` never touches your project's code or folder structure. It lives entirely inside `.rig/` at the project root. This makes it:

- Safe to add to existing projects
- Easy to version alongside your code
- Readable by any AI agent or developer

```
your-project/
├── src/                  ← your code, untouched
├── package.json          ← your config, untouched
└── .rig/                 ← rig-spec lives here
    ├── HARNESS.md
    ├── feedforward/
    ├── feedback/
    ├── memory/
    └── orchestration/
```

---

## The Four Layers

The `.rig/` folder is divided into four layers. Each layer maps directly to a concept in Harness Engineering.

---

### Layer 1 — `feedforward/`

**What it is:** Everything that guides the agent BEFORE it acts.

**Why it exists:** An agent with no direction improvises. An agent with clear specs, tasks, rules, and skills has a path to follow.

```
.rig/feedforward/
├── specs/                ← what to build (feature specs, product spec)
├── tasks/                ← how to divide the work (task breakdowns per spec)
├── rules/                ← coding conventions, architecture rules
├── skills/               ← reusable specialized context (local skills)
├── agents/               ← agent profiles (architect, implementer, validator)
└── mcp.config.md         ← MCP servers configured for this project
```

**Files in this layer are written by humans or agents during planning.
They are consumed by agents during execution.**

---

### Layer 2 — `feedback/`

**What it is:** Everything that observes and corrects the agent AFTER it acts.

**Why it exists:** Instructions without verification are just hopes. Sensors close the loop and force real correctness.

```
.rig/feedback/
├── sensors/              ← sensor definitions (what runs after each task)
│   ├── lint.sensor.md
│   ├── test.sensor.md
│   ├── typecheck.sensor.md
│   ├── arch.sensor.md    ← architecture fitness checks
│   └── spec-compliance.sensor.md ← verifies impl matches spec
├── hooks/                ← scripts triggered automatically post-implementation
├── review/               ← inferential sensors (AI review agent instructions)
└── audit/                ← continuous drift sensors (run outside change cycle)
```

**Two types of sensors:**

| Type | Examples | Speed | Cost | Reliability |
|---|---|---|---|---|
| Computational | linters, tests, type checkers, arch analysis | milliseconds | cheap | deterministic |
| Inferential | AI code review, spec compliance check, LLM as judge | seconds | moderate | probabilistic |

Start with computational sensors. Add inferential when you need semantic judgment.

**Sensor timing — when each type runs:**

| Timing | Sensors |
|---|---|
| After every task (fast) | lint, typecheck, unit tests |
| After every task (slower) | integration tests, spec compliance |
| After integration | architecture fitness, full review agent |
| Continuously (scheduled) | dead code, dependency health, drift audit |

---

### Layer 3 — `memory/`

**What it is:** Persistent state that survives between sessions.

**Why it exists:** Every new AI session starts from zero. Without memory, the agent wastes tokens rediscovering what was already done, what failed, and why.

```
.rig/memory/
├── progress.md           ← current state of all features and tasks
├── decisions.md          ← architectural decisions with rationale (ADR-style)
├── bootstrap.md          ← ordered reading list to reconstruct context
└── research/             ← saved research findings (from rig-spec research)
    └── [topic].md
```

**The `bootstrap.md` file is the most important file in this layer.**
It tells any agent — in any new session — exactly what to read and in what order to fully understand the project's current state.

**The `research/` folder solves context window pollution.**
Research sessions write their findings here. Implementation sessions read from here — they never re-do the research.

---

### Layer 4 — `orchestration/`

**What it is:** The coordination layer between multiple agents.

**Why it exists:** One agent cannot objectively validate its own work. Separation of concerns between implementation and validation eliminates self-evaluation bias.

```
.rig/orchestration/
├── contracts/            ← agreements between implementer and validator
│   └── [feature]-[task].contract.md
├── implementer.md        ← implementer agent instructions and constraints
└── validator.md          ← validator agent instructions and constraints
```

---

### Entry Point — `HARNESS.md`

The single file any agent reads first when entering the project.

```
.rig/HARNESS.md
```

It contains:
- What the project is (1 paragraph)
- Current harness level active (1, 2, or 3)
- Current active feature or task
- Where to find specs, tasks, and progress
- Which sensors are configured
- Which skills and MCP servers are available

**This file is the bridge between your project and the harness.**
Any agent, in any session, reads this first.

---

## The Standards System

Standards capture how your project is built — patterns, conventions, and architectural decisions — and enforce them automatically on every implementation.

**The principle:** standards are feedforward. Compliance sensors are feedback.

### What Standards Cover

```
.rig/feedforward/rules/
├── architecture.rules.md    ← module boundaries, layering rules, dependency direction
├── naming.rules.md          ← file naming, class naming, function naming, variable naming
├── structure.rules.md       ← folder organization, where each type of file lives
├── component.rules.md       ← frontend component patterns, props conventions, state rules
├── api.rules.md             ← endpoint design, response envelope, error format, versioning
└── testing.rules.md         ← what must be tested, fixture requirements, test file location
```

Every rules file is injected into the agent's context before every task. The agent knows how your project is built before writing a single line of code.

### Standards Compliance Sensors

Standards files define expectations. Sensors verify they were met.

**Computational sensors — fast, deterministic:**

| Sensor | Tool | What it checks |
|---|---|---|
| `arch.sensor.md` | dependency-cruiser, ArchUnit | Module boundaries, forbidden imports, layering violations |
| `naming.sensor.md` | ESLint custom rules | File names, class names, function names, variable patterns |
| `structure.sensor.md` | Custom scripts | Folder organization, file placement, export patterns |

**Inferential sensor — semantic, AI-based:**

| Sensor | What it checks |
|---|---|
| `standards-compliance.sensor.md` | Reads all `rules/` files and verifies the implementation followed them semantically |

The inferential sensor catches violations that linters cannot: wrong layer for business logic, component in the wrong folder, API response that doesn't follow the project envelope, test that doesn't cover the required scenarios.

### Discover — For Existing Projects

`rig-spec discover` analyzes an existing codebase and generates draft standards:

```bash
rig-spec discover
```

**Process:**
1. Scans folder structure, file naming patterns, import graphs, class/component shapes
2. Generates draft files in `.rig/feedforward/rules/` — every item marked `[DRAFT]`
3. Human reviews each draft: confirm what's intentional, remove what's accidental, add what's missing
4. Approved rules become active feedforward context and configure compliance sensors automatically

**Why human review is non-negotiable:** discovered patterns may be accidents or legacy debt, not architectural intent. Only humans can decide what's a rule vs. what's a mistake.

### Init — For New Projects

`rig-spec init` asks about your architecture upfront:

```
→ Architecture pattern? (clean / mvc / ddd / none)
→ Frontend? (react / vue / none)
→ API style? (rest / graphql / none)
→ Testing approach? (tdd / bdd / none)
```

Based on answers, it generates pre-filled rules templates specific to your choices. You fill in the project-specific details. Enforcement starts on the first task.

### Standards as Living Documentation

Rules files are not just enforcement tools. They are the written contract of how the project is built — readable by any developer or agent joining the project.

When a convention evolves:
1. Update the rule in `rules/`
2. The sensor immediately enforces the new pattern going forward
3. The change is visible in git history with a clear rationale

---

## The Skills System

Skills are reusable packages of specialized knowledge. They are part of the feedforward layer.

### What a skill contains

```markdown
# Skill: NestJS

## Context
NestJS is a Node.js framework built on TypeScript using decorators and
dependency injection. This project uses NestJS for all API modules.

## Patterns to follow
- Controllers handle HTTP routing only — no business logic
- Business logic lives in Services
- Data access lives in Repositories
- [more patterns...]

## Pitfalls to avoid
- Do not use `any` type — always define interfaces
- Do not inject services into other services directly — use interfaces
- [more pitfalls...]

## Examples from this codebase
→ See src/users/users.controller.ts for the controller pattern
→ See src/users/users.service.ts for the service pattern
```

### Two types of skills

**Local skills** — specific to this project, live in `.rig/feedforward/skills/`:
```
.rig/feedforward/skills/
├── nestjs.skill.md
├── postgres.skill.md
└── testing.skill.md
```

**External skills** — from your personal skill library or community repos, referenced in `HARNESS.md`:
```markdown
# HARNESS.md — Skills section
## External Skills
- ~/skills/typescript-expert.skill.md
- ~/skills/clean-architecture.skill.md
```

Skills are loaded selectively per task — only the relevant ones, not all of them at once.

---

## MCP Integration

MCP (Model Context Protocol) is a protocol for providing real-time context to AI agents — databases, APIs, documentation, codebase indexing.

In `rig-spec`, MCP is feedforward — it provides context that supplements the static files.

### Configuration

```markdown
# .rig/feedforward/mcp.config.md

## MCP Servers configured for this project

### codebase-index
Purpose: Semantic search across the codebase
When to use: During research and planning phases
Config: See .mcp/codebase.json

### database-schema
Purpose: Real-time access to the current DB schema
When to use: During tasks that touch data models
Config: See .mcp/database.json

### api-docs
Purpose: External API documentation (Stripe, SendGrid, etc.)
When to use: During tasks that integrate external services
Config: See .mcp/api-docs.json
```

MCP servers declared here are available to agents but only loaded when relevant to the current task — not all at once.

---

## Harness Levels

You don't need to use everything at once. `rig-spec` has three progressive levels. Start where you are.

### Level 1 — Spec Only

**Minimum viable harness. Works immediately in any project. No tooling required.**

Active layers:
- `feedforward/specs/` — write what you're building
- `feedforward/tasks/` — break it into tasks with contracts
- `memory/progress.md` — track what's done
- `memory/bootstrap.md` — reconstruct context between sessions

Failure patterns solved:
- ✅ One Shot Hero
- ✅ Premature Victory
- ✅ Session Amnesia

```
.rig/
├── HARNESS.md
├── feedforward/
│   ├── specs/
│   └── tasks/
└── memory/
    ├── progress.md
    └── bootstrap.md
```

---

### Level 2 — Spec + Memory + Skills

**Adds full context persistence, architectural memory, and specialized knowledge.**

Adds to Level 1:
- `memory/decisions.md` — architectural decisions with rationale
- `memory/research/` — clean research findings per topic
- `feedforward/rules/` — coding conventions and architecture rules
- `feedforward/skills/` — specialized local skills
- `feedforward/mcp.config.md` — MCP server declarations

Failure patterns additionally solved:
- ✅ Context Window Pollution (research/ + RPI pattern)
- ✅ Spec Quality Gap (rules guide spec writing)
- ✅ Architecture Fitness Violation (rules prevent drift early)

---

### Level 3 — Full Harness

**Complete harness with sensors, validators, multi-agent orchestration, and continuous monitoring.**

Adds to Level 2:
- `feedback/sensors/` — automated checks post-implementation
- `feedback/review/` — inferential review agent instructions
- `feedback/audit/` — continuous drift sensors
- `orchestration/` — two-agent pattern with contracts

Failure patterns additionally solved:
- ✅ Untested Features (sensors enforce real validation)
- ✅ Single Process (implementer + validator are separate)
- ✅ Spec Drift (spec compliance sensor)
- ✅ Parallel Task Conflicts (file ownership in contracts)
- ✅ Behavioural Harness Gap (approved fixtures pattern)
- ✅ Continuous Drift (audit sensors)

---

## Adapter System

`rig-spec` is agnostic by default. Every file in `.rig/` works with any AI tool.

For tool-specific optimizations, optional adapters can be added:

```
.rig/
└── adapters/
    ├── claude.md         ← Claude Code-specific instructions
    ├── gemini.md         ← Gemini-specific instructions
    └── antigravity.md    ← Antigravity-specific instructions
```

Adapters are never required. They only enhance the experience when using a specific tool. The `HARNESS.md` is always the primary entry point — adapters supplement it.

---

## File Format Conventions

| File type | Format | Purpose |
|---|---|---|
| Specs | Markdown | Human and agent readable, long-lived |
| Tasks | Markdown | Structured task breakdowns with contracts |
| Contracts | Markdown checklist | Implementer-validator agreements |
| Rules | Markdown | Coding conventions and architecture constraints |
| Skills | Markdown | Specialized context and reusable patterns |
| MCP config | Markdown | MCP server declarations and usage guidance |
| Sensors | Markdown | Sensor definitions with commands |
| Progress | Markdown | Session state and task status |
| Decisions | Markdown | ADR-style architectural decisions |
| Bootstrap | Markdown | Ordered reading instructions |
| Hooks | Shell scripts | Automated post-task execution |

**No proprietary formats. No binary files. No custom DSL.**
Everything is plain text, readable by humans and any AI tool.

---

## How Layers Connect

```
Human writes spec
        ↓
.rig/feedforward/specs/[feature].spec.md
        ↓
Spec Quality sensor validates completeness (inferential)
        ↓
Agent reads spec → generates tasks with file ownership
        ↓
.rig/feedforward/tasks/[feature]/task-XX.md
        ↓
Implementer agent reads:
  task + spec + rules + relevant skills + MCP context
        ↓
Implementer writes code + signs contract
        ↓
.rig/orchestration/contracts/[feature]-task-XX.contract.md
        ↓
Computational sensors run (lint, test, typecheck, arch)
        ↓
Validator agent reads contract + code + sensor results
        ↓
PASSED → memory/progress.md updated → next task
FAILED → implementer receives specific failures → retry
        ↓ (after all tasks complete)
Continuous audit sensors run on schedule
```

---

## Greenfield vs Retrofit

### Greenfield (new project)
Run `rig-spec init` and choose your starting level. The harness is set up before any code is written. Maximum harnessability from day one.

### Retrofit (existing project)
Run `rig-spec init --retrofit`. The CLI:
1. Scans the project for existing sensors (linters, test scripts, CI config)
2. Discovers the tech stack (package.json, requirements.txt, go.mod, etc.)
3. Generates a contextual `HARNESS.md` based on what it finds
4. Reports which sensors are already available and which are suggested
5. Starts at Level 1 — you upgrade when ready

**Retrofit always starts at Level 1. Upgrade incrementally.**

The harness is most needed in existing projects and hardest to build there — retrofit mode is designed to minimize that friction.
