# rig-spec

> An operational framework for AI-native development.
> Structure your AI agents. Make them reliable. Keep quality consistent.

---

## The Problem

AI agents are powerful — but without structure, they fail in predictable ways:

- They try to build everything at once and run out of context
- They declare features "done" without testing them properly
- They forget everything between sessions
- They can't objectively validate their own work
- They drift away from your architecture over time

**rig-spec is the harness that prevents all of that.**

It gives your AI agents the structure, context, memory, and validation loops they need to produce reliable, consistent results — across any project, any language, any AI tool.

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
```

Installs the `rig-spec` command to `~/.local/bin/`. No runtime required. Works on Mac and Linux (Windows: WSL or Git Bash).

Then in any project:

```bash
cd your-project
rig-spec init
```

---

## How It Works

`rig-spec` adds a `.rig/` folder to your project. This folder contains everything the agent needs:

```
.rig/
├── HARNESS.md          ← what every agent reads first
├── feedforward/        ← guides the agent before it acts
│   ├── specs/          ← what to build
│   ├── tasks/          ← how to divide the work
│   ├── rules/          ← coding and architecture conventions
│   ├── skills/         ← specialized context (NestJS, PostgreSQL, etc.)
│   └── mcp.config.md   ← MCP server declarations
├── feedback/           ← corrects the agent after it acts
│   ├── sensors/        ← linters, tests, type checkers, arch analysis
│   ├── review/         ← AI review agent instructions
│   └── audit/          ← continuous drift detection
├── memory/             ← persists state between sessions
│   ├── progress.md     ← what's done, what's next
│   ├── decisions.md    ← architectural decisions with rationale
│   ├── bootstrap.md    ← context reconstruction for new sessions
│   └── research/       ← saved research findings
└── orchestration/      ← coordinates multiple agents
    ├── contracts/      ← implementer-validator agreements
    ├── implementer.md  ← implementer agent instructions
    └── validator.md    ← validator agent instructions
```

**Your code is untouched. Your folder structure is untouched. Only `.rig/` is added.**

---

## Repository Structure

```
rig-spec/
├── install.sh      ← installs the rig-spec command to PATH (~/.local/bin)
├── rig-spec.sh     ← the full CLI: all subcommands + templates embedded
├── templates/.rig/ ← static templates (alternative: copy manually)
└── *.md            ← design documentation
```

---

## The Development Flow

```
init → research → shape → plan → run → validate → audit
```

```bash
rig-spec init                          # new project — auto-detects stack
rig-spec init --retrofit               # existing project (rules as [DRAFT])
rig-spec init --template node-api      # force a specific template
rig-spec research "topic"              # investigate before specifying
rig-spec shape "feature name"          # ask 5 questions, pre-fill spec
rig-spec plan feature-name             # break spec into tasks
rig-spec run task-01                   # assemble context for your AI agent
rig-spec validate                      # run all sensors
rig-spec validate task-01              # sensors + show task contract checklist
rig-spec resume                        # pick up where you left off
rig-spec audit                         # check for accumulated drift
```

> `run`, `research`, `shape`, and `plan` are **context assemblers** — they prepare and print the context so you can paste it into your AI agent of choice. No API calls are made.

---

## Quick Start (5 minutes)

**Step 1 — Install**

```bash
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
```

Reload your shell, then:

```bash
cd your-project
rig-spec init
```

**Step 2 — Fill in `HARNESS.md`**

Open `.rig/HARNESS.md` and add:
- What your project is (1 paragraph)
- Your tech stack
- Harness level: start with `1`

**Step 3 — Create your first spec**

```bash
cp .rig/feedforward/specs/_TEMPLATE.spec.md \
   .rig/feedforward/specs/my-first-feature.spec.md
```

Fill in: Problem, Goal, Out of Scope, User Stories, Acceptance Criteria, Approved Fixtures.

**Step 4 — Create tasks**

```bash
rig-spec plan my-first-feature
```

This assembles the context and prints instructions for your agent to create the task breakdown.

**Step 5 — Start working**

```bash
rig-spec run task-01
```

Opens the assembled context. Paste it into Claude, Gemini, GPT, or any other agent.

---

## How to Work

Every feature goes through the same sequence — what changes is *who* runs each step.

```
shape → plan → run → validate
```

### Path 1 — Single Agent, Separate Sessions

You orchestrate. Each command assembles a clean context that you paste into any AI agent.

```bash
rig-spec shape "feature name"
# → asks 5 questions, pre-fills spec, outputs context
# → paste into your agent → agent completes User Stories + AC

rig-spec plan feature-name
# → outputs context for the agent to break the spec into tasks

rig-spec run task-01
# → outputs full context (spec + task + rules + skills)
# → paste into your agent → agent implements

rig-spec validate
# → runs all sensors, reports pass/fail per item
```

Each step runs in its own context window. No pollution between research, planning, and implementation.

### Path 2 — Two Agents (Implementer + Validator)

Same flow, but validation is handled by a separate agent with a different mission.

```
rig-spec run task-01
  → Implementer: reads spec + task + rules, writes code, signs the contract
  → Validator:   reads signed contract + code + sensor results
                 checks every item, returns pass or specific failure list
  → If failed:   implementer receives exact failures → fixes → retry
```

The implementer and validator have separate profiles in `.rig/orchestration/`:

```
.rig/orchestration/
├── implementer.md   ← build only what the contract specifies, sign each item
└── validator.md     ← check every item, never mark pass if anything is unchecked
```

**Why two agents:** an agent validating its own work will always find reasons it passed. The validator has one job — find what's wrong. Separate missions eliminate self-evaluation bias.

### Which path to use

| Situation | Path |
|---|---|
| Getting started, small team | Path 1 — single agent, you review |
| High-stakes features, want objective validation | Path 2 — two agents |
| Retrofitting an existing project | Path 1 first, add Path 2 when sensors are in place |

Both paths use the same commands and the same `.rig/` structure. You can mix them per feature.

---

## Key Features

### Two-Agent Validation
Every implementation is validated by a separate agent with a separate mission. The implementer builds. The validator checks. Neither judges its own work.

### Explicit Contracts
Every task has a contract — a checklist of what "done" means, agreed before any code is written. The validator checks item by item.

### Session Memory
`progress.md`, `decisions.md`, and `bootstrap.md` ensure that every new session starts with full context — no wasted tokens figuring out where you left off.

### Progressive Harness Levels
Start with just specs and tasks (Level 1). Add memory and skills (Level 2). Add sensors and two-agent orchestration (Level 3). Use only what you need.

### Model-Agnostic
Works with Claude Code, Gemini, Antigravity, Cursor, or any other AI tool. No lock-in. Everything is Markdown. No API calls in the CLI.

### Solves 13 Agent Failure Patterns
From "One Shot Hero" to "Continuous Drift" — every documented way AI agents fail in production is addressed by the framework. See [VISION.md](VISION.md) for the full list.

---

## Stack Templates

`rig-spec init` auto-detects your stack and applies a pre-built template with rules and skills already filled in.

| Template | Detected from | Rules | Skills |
|---|---|---|---|
| `node-api` | `package.json` (Express / NestJS / Node) | layered arch, TS naming, REST API, Jest testing | TypeScript, Node.js |
| `fullstack-nextjs` | `package.json` + `"next"` dependency | App Router arch, React naming, component rules, API routes | Next.js, React |
| `python-api` | `pyproject.toml` / `requirements.txt` | layered arch, snake_case naming, FastAPI, pytest | FastAPI, Python |
| `generic` | (fallback) | blank stubs | skill template |

Override auto-detection when needed:

```bash
rig-spec init --template node-api
rig-spec init --template python-api
rig-spec init --template fullstack-nextjs
rig-spec init --template generic
```

Or copy static templates without the CLI:

```bash
cp -r rig-spec/templates/node-api/.rig your-project/
```

---

## Sensors

`rig-spec validate` runs every `*.sensor.md` file in `.rig/feedback/sensors/` and reports pass/fail.

**Auto-discovered on `init`** (found by scanning the project):

| Tool found | Sensor created |
|---|---|
| `.eslintrc.*` / `eslint.config.*` | `lint.sensor.md` |
| `tsconfig.json` | `typecheck.sensor.md` |
| `"test"` in `package.json` | `test.sensor.md` |
| `ruff.toml` / `[tool.ruff]` | `lint.sensor.md` |
| `mypy.ini` / `[tool.mypy]` | `typecheck.sensor.md` |
| `pytest.ini` / `[tool.pytest]` | `test.sensor.md` |

**Require manual config** (templates provided in `feedback/sensors/`):

| Sensor | What it checks |
|---|---|
| `arch.sensor.md` | Module boundary violations (dependency-cruiser or custom script) |
| `naming.sensor.md` | Naming convention compliance (ESLint custom rules) |
| `spec-compliance.sensor.md` | AI verifies implementation matches spec acceptance criteria |
| `standards-compliance.sensor.md` | AI verifies implementation matches `rules/` semantically |

To add any sensor: copy `_TEMPLATE.sensor.md`, fill in `## Command`, and `rig-spec validate` picks it up automatically.

---

## Harness Levels

| Level | What's active | Start here if... |
|---|---|---|
| **1 — Spec Only** | specs, tasks, contracts, progress, bootstrap | You're new to the framework |
| **2 — + Memory & Skills** | + decisions, research, rules, skills, MCP | You want full context persistence |
| **3 — Full Harness** | + sensors, two-agent validation, audit | You want automated quality enforcement |

All projects start at Level 1. Upgrade when you're ready.

---

## Works With Any AI Tool

`rig-spec` is built on plain Markdown. It works with:

- **Claude Code** (via `AGENTS.md` or direct reference)
- **Antigravity** (reference `.rig/` files as context)
- **Gemini** (attach `.rig/HARNESS.md` + relevant files)
- **Cursor / Windsurf** (include `.rig/` in context)
- **Any other agent** that can read files

Optional adapters in `.rig/adapters/` provide tool-specific optimizations.

---

## Manual Installation (No Internet Required)

```bash
git clone https://github.com/axel-andrade/rig-spec.git
cp -r rig-spec/templates/.rig your-project/
```

Then fill in `.rig/HARNESS.md` and start with your first spec.

---

## Project Standards System

One of the most powerful features of `rig-spec` is how it captures and enforces your project's own patterns — architecture, naming, component structure, API conventions — and uses them as both context for agents and as automated compliance checks.

**The core insight:** standards are feedforward. Compliance is feedback.

```
rules/ (feedforward)     →    sensors/ (feedback)
"here's how we do it"   →    "did you follow it?"
```

### Where Standards Live

```
.rig/feedforward/rules/
├── architecture.rules.md    ← layering rules, module boundaries
├── naming.rules.md          ← naming conventions for files, classes, functions
├── structure.rules.md       ← folder organization patterns
├── component.rules.md       ← frontend component patterns (when applicable)
├── api.rules.md             ← endpoint design, response format, error handling
└── testing.rules.md         ← what to test, how to structure tests
```

These files are injected into the agent's context before every task. The agent knows your patterns before writing a single line.

### Sensors That Enforce Standards

**Computational sensors (fast, deterministic):**
```
.rig/feedback/sensors/
├── arch.sensor.md        ← checks module boundaries (dependency-cruiser)
├── naming.sensor.md      ← checks naming conventions (ESLint custom rules)
└── structure.sensor.md   ← checks folder/file organization
```

**Inferential sensor (AI, semantic):**
```
.rig/feedback/sensors/
└── standards-compliance.sensor.md  ← AI reviewer reads rules/ and checks implementation
```

The inferential sensor catches what linters cannot: wrong layer for business logic, component in the wrong folder, API response that doesn't follow the project envelope.

---

## Documentation

| Document | Contents |
|---|---|
| [VISION.md](VISION.md) | What rig-spec is, why it exists, the 13 failure patterns it solves |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer structure, skills system, MCP integration, harness levels |
| [WORKFLOW.md](WORKFLOW.md) | Complete development flow, two-agent pattern, CLI reference |
| [ROADMAP.md](ROADMAP.md) | Build phases, decision log, explicit non-goals |

---

## What rig-spec Is NOT

- ❌ A code boilerplate or project generator
- ❌ A tool that only works with one AI model
- ❌ Something that reorganizes your existing project
- ❌ A replacement for your development tools
- ❌ A prompt collection
- ❌ A Node.js package or anything that requires a runtime

**rig-spec is the structure around your agents — not a replacement for them.**

---

## License

MIT
