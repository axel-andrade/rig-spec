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
├── HARNESS.md          ← vision, business rules, current focus — every agent reads this first
├── STANDARDS.md        ← index: where architecture, naming, UI tokens, API rules live
├── feedforward/        ← guides the agent before it acts
│   ├── specs/          ← what to build
│   ├── tasks/          ← how to divide the work
│   ├── rules/          ← coding and architecture conventions
│   ├── skills.registry.md ← auto skill routing by task keywords
│   ├── skills/         ← specialized context (NestJS, PostgreSQL, etc.)
│   └── mcp.config.md   ← MCP server declarations
├── feedback/           ← corrects the agent after it acts
│   ├── sensors/        ← linters, tests, endpoints, compliance checks
│   ├── reports/        ← validation artifacts (rig-spec validate)
│   ├── review/         ← AI review agent instructions (always on validate)
│   └── audit/          ← continuous drift detection
├── memory/             ← persists state between sessions
│   ├── progress.md     ← what's done, what's next
│   ├── decisions.md    ← architectural decisions with rationale
│   ├── learnings.md    ← implementation discoveries and gotchas
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
init → overview → research → shape → plan → run → validate → audit
```

```bash
rig-spec init                          # new project — auto-detects stack
rig-spec init --retrofit               # existing project — scans src/ structure
rig-spec init --template node-api      # force a specific template
rig-spec overview                      # show vision, business rules, current state
rig-spec research "topic"              # investigate before specifying
rig-spec shape "feature name"          # ask 5 questions, create timestamped spec
rig-spec plan feature-name             # break spec into tasks (with Q&A)
rig-spec plan feature-name --lite      # skip Q&A — quick minimal task breakdown
rig-spec replan feature-name           # pivot mid-feature, preserve completed tasks
rig-spec run task-01                   # assemble context for your AI agent
rig-spec validate                      # run all sensors
rig-spec validate task-01              # sensors + show task contract checklist
rig-spec resume                        # pick up where you left off
rig-spec archive feature-name          # archive completed spec from progress.md
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

**Step 2 — Fill in vision and business rules**

```bash
rig-spec overview
```

Shows the generated `.rig/HARNESS.md` in a clean one-pager. Open the file and fill in:
- `## Vision` — what the product is, who it serves, what core problem it solves
- `## Business Rules` — non-negotiable domain constraints agents must know before coding
- `## Current Focus` — which feature is active

**Step 3 — Create your first spec**

```bash
rig-spec shape "my first feature"
```

Asks 5 questions, creates a timestamped draft spec (`YYYYMMDD-HHMMSS-slug.spec.md`), and assembles context for your agent to complete it with User Stories, Acceptance Criteria, and Approved Fixtures. Run `rig-spec shape "..." --complete` in Phase 2 to let the agent finalize the spec and choose the canonical slug.

> **Note:** After `init`, open `.rig/HARNESS.md` and fill in the `## Vision` and `## Business Rules` sections — `init` warns you if they still contain placeholder text.

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

## How to Use With Your AI Agent

`rig-spec` works with any AI tool. How you use it depends on the tool.

### File-reading agents (Claude Code, Cursor, Windsurf)

`rig-spec init` creates entry point files the tool reads automatically:

```
CLAUDE.md       ← Claude Code reads this on every session
.cursorrules    ← Cursor reads this automatically
.windsurfrules  ← Windsurf reads this automatically
AGENTS.md       ← generic (any agent that supports it)
```

All of them contain the same instruction: read `.rig/HARNESS.md` first.

**Usage:** open the project normally. The agent already has context. To start a task:

```bash
rig-spec run task-01        # assembles context into .rig/context-task-01.md
```

Then tell the agent:
```
Read .rig/context-task-01.md and implement what the contract specifies.
```

### Chat agents (Claude.ai, ChatGPT, Gemini)

Chat tools can't read your local files — you copy the context and paste it into the conversation.

```bash
rig-spec run task-01        # generates .rig/context-task-01.md
cat .rig/context-task-01.md # copy this entire output
```

Paste it as the first message. The agent reads, implements, and replies with code. You copy the code back to your files.

### Quick reference — what each command generates

| Command | Output | When to use |
|---|---|---|
| `rig-spec run task-01` | `.rig/context-task-01.md` | Implement a task |
| `rig-spec shape "feature"` | `.rig/context-shape-[slug].md` | Write a spec |
| `rig-spec plan feature` | `.rig/context-plan-[slug].md` | Break a spec into tasks |
| `rig-spec resume` | prints directly | Resume where you left off |

`context-*.md` files are temporary and already in `.rig/.gitignore`.

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

### Vision and Business Rules in HARNESS.md
`HARNESS.md` now carries the product vision and non-negotiable domain rules. Every agent reads them before touching any task — eliminating implementations that work technically but violate business logic.

### Session Memory
`progress.md`, `decisions.md`, `learnings.md`, and `bootstrap.md` ensure that every new session starts with full context — no wasted tokens figuring out where you left off. `learnings.md` captures implementation discoveries made during tasks (patterns found, gotchas, non-obvious behavior) so future agents don't repeat the same mistakes.

### Progressive Harness Levels
Start with just specs and tasks (Level 1). Add memory and skills (Level 2). Add sensors and two-agent orchestration (Level 3). Use only what you need.

### Continuation Protocol
If a task is too large for one context window, the agent writes a `[CHECKPOINT]` to `progress.md` and signals for continuation. Running `rig-spec resume` starts a fresh context window that reads the checkpoint and picks up exactly where the previous agent stopped — no lost work, no duplicate effort.

### Git Workflow Built In
`HARNESS.md` includes a git workflow section: one branch per feature, one commit per validated task. After `rig-spec done`, the CLI suggests the commit command with the correct format. Agents never commit autonomously — the commit step belongs to the human.

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

**Retrofit mode** (`--retrofit`) behaves differently — it doesn't apply a template. Instead, it scans the actual project:

- Reads `src/`, `app/`, or `lib/` (2 levels deep) → generates `structure.rules.md` from the real folder tree
- Detects TypeScript files → adjusts naming rules
- Detects test location pattern (co-located vs. separate folder)
- Detects module names and lists them in `architecture.rules.md`
- Writes architecture/naming/API/testing rules as `[DRAFT]` for you to fill in

This means `structure.rules.md` is populated immediately — you just confirm it. The other rule files need manual completion.

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

To add a sensor: copy `_TEMPLATE.sensor.md`, fill in the `command:` key in the YAML frontmatter, and `rig-spec validate` picks it up automatically.

**Shorthand sensors (`sensors.config.yaml`):** for simple one-liner commands, skip the `.sensor.md` file entirely. Add entries to `.rig/feedback/sensors/sensors.config.yaml`:

```yaml
lint:      npm run lint
test:      npm test
typecheck: npx tsc --noEmit
```

If a `.sensor.md` with the same name exists, it takes priority. Use `.sensor.md` when you need `On Failure` instructions or custom timing.

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

Your project's patterns — architecture, naming, API shape, UI tokens, components — live in **fixed locations**. Agents read them before every task; sensors and review verify them after.

**The core insight:** standards are feedforward. Compliance is feedback.

```
STANDARDS.md (index)  →  rules/ (what to follow)  →  sensors/ + review (did you follow it?)
```

### Canonical locations

| What | Where |
|---|---|
| **Index (start here)** | `.rig/STANDARDS.md` |
| Architecture & layering | `.rig/feedforward/rules/architecture.rules.md` |
| Naming | `.rig/feedforward/rules/naming.rules.md` |
| Folder layout | `.rig/feedforward/rules/structure.rules.md` |
| API conventions | `.rig/feedforward/rules/api.rules.md` |
| Tests | `.rig/feedforward/rules/testing.rules.md` |
| React/UI components | `.rig/feedforward/rules/component.rules.md` (frontend) |
| Colors, spacing, typography | `.rig/feedforward/rules/design-tokens.rules.md` (frontend) |

On `rig-spec run`, all existing `*.rules.md` files are injected into the agent context. On retrofit, `structure.rules.md` is generated from your real `src/` tree; other files start as `[DRAFT]` for you to complete.

### Automatic skill routing

`.rig/feedforward/skills.registry.md` maps **keywords in the task** → **skills** (local `.rig` files or external paths like `~/.claude/skills/...`).

Example: a task mentioning `endpoint` and `service` auto-loads `nodejs.skill.md`; a task mentioning `component` and `page` loads `react.skill.md`.

```bash
rig-spec run task-03   # assembles rules + auto-matched skills + task contract
```

Disable auto-routing for one task by adding `skills: manual` in the task file.

### Best sensors per task type

| Task type | Recommended sensors |
|---|---|
| Any code | `lint`, `typecheck`, `test` |
| API / routes | + `endpoint` (integration or curl smoke) |
| Every task | + `spec-compliance`, `standards-compliance` (review agent) |
| Module boundaries | + `arch` (dependency-cruiser, etc.) |

Templates ship on `init`. Configure `endpoint.sensor.md` with your real test command.

### Validation report (visual artifact)

```bash
rig-spec validate task-01
```

Produces `.rig/feedback/reports/validation-task-01-YYYY-MM-DD.md` with:

- **Sensor matrix** — pass / fail / review per sensor
- **Contract checklist** — copied from the task
- **Review instructions** — always points to `code-review.review.md` + `validation-matrix.review.md` + `STANDARDS.md`

Computational sensors run in the CLI. Inferential sensors are marked `REVIEW` — run your review agent against the report and rules until **Overall: PASS**.

---

## Documentation

| Document | Contents |
|---|---|
| [VISION.md](VISION.md) | What rig-spec is, why it exists, the 13 failure patterns it solves |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer structure, skills system, MCP integration, harness levels |
| [WORKFLOW.md](WORKFLOW.md) | Complete development flow, two-agent pattern, CLI reference |

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
