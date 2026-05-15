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

## The Development Flow

```
init → research → shape → plan → run → validate → audit
```

```bash
npx rig-spec init --retrofit        # set up on existing project
npx rig-spec discover               # extract project standards from codebase
npx rig-spec research "topic"       # investigate before specifying
npx rig-spec shape "feature name"   # write the spec
npx rig-spec plan feature-name      # break into tasks
npx rig-spec run task-01            # implement + validate automatically
npx rig-spec resume                 # pick up where you left off
npx rig-spec audit                  # check for accumulated drift
```

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
Works with Claude Code, Gemini, Antigravity, Cursor, or any other AI tool. No lock-in. Everything is Markdown and YAML.

### Solves 13 Agent Failure Patterns
From "One Shot Hero" to "Continuous Drift" — every documented way AI agents fail in production is addressed by the framework. See [VISION.md](VISION.md) for the full list.

---

## Installation

### Option 1 — Shell Script (Recommended for existing projects)

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/rig-spec/main/install.sh | bash
```

This copies the `.rig/` template into your current project directory.

### Option 2 — npx (CLI — coming in Phase 4)

```bash
# New project
npx rig-spec init

# Existing project (scans for existing tools automatically)
npx rig-spec init --retrofit
```

### Option 3 — Manual

1. Clone this repository
2. Copy the `templates/.rig/` folder into your project root
3. Fill in `.rig/HARNESS.md` with your project details
4. Start with your first spec

```bash
git clone https://github.com/your-username/rig-spec.git
cp -r rig-spec/templates/.rig your-project/
```

---

## Quick Start (5 minutes)

**Step 1 — Install**

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/your-username/rig-spec/main/install.sh | bash
```

**Step 2 — Fill in `HARNESS.md`**

Open `.rig/HARNESS.md` and add:
- What your project is (1 paragraph)
- Your tech stack
- Harness level: start with `1`

**Step 3 — Create your first spec**

Copy `.rig/feedforward/specs/_TEMPLATE.spec.md`:

```bash
cp .rig/feedforward/specs/_TEMPLATE.spec.md \
   .rig/feedforward/specs/my-first-feature.spec.md
```

Fill in: Problem, Goal, Out of Scope, User Stories, Acceptance Criteria, Approved Fixtures.

**Step 4 — Create tasks**

Copy `.rig/feedforward/tasks/_TEMPLATE.task.md` for each task. Or ask your AI agent:

> "Read `.rig/feedforward/specs/my-first-feature.spec.md` and `.rig/HARNESS.md`. Break this spec into tasks following the task template in `.rig/feedforward/tasks/_TEMPLATE.task.md`. Save each task as a separate file."

**Step 5 — Start working**

Give your agent this prompt to start any session:

> "Read `.rig/HARNESS.md` and `.rig/memory/bootstrap.md`. Then read the task we're working on and implement it following all rules and conventions."

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

## Documentation

| Document | Contents |
|---|---|
| [VISION.md](VISION.md) | What rig-spec is, why it exists, the 13 failure patterns it solves |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer structure, skills system, MCP integration, harness levels |
| [WORKFLOW.md](WORKFLOW.md) | Complete development flow, two-agent pattern, CLI reference |
| [ROADMAP.md](ROADMAP.md) | Build phases, decision log, explicit non-goals |

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

Standards files define the rules. Sensors verify they were followed.

**Computational sensors (fast, deterministic):**
```
.rig/feedback/sensors/
├── arch.sensor.md               ← dependency-cruiser / ArchUnit checks module boundaries
├── naming.sensor.md             ← ESLint custom rules check naming conventions
└── structure.sensor.md          ← scripts check folder/file organization
```

**Inferential sensor (AI, semantic):**
```
.rig/feedback/sensors/
└── standards-compliance.sensor.md  ← AI reviewer reads rules/ and checks implementation
```

The inferential sensor catches what linters cannot: "this service is doing domain logic that belongs in the domain layer", "this component should be in `features/` not `components/`", "this API response format doesn't follow our standard envelope".

### For New Projects — Define Upfront

When running `rig-spec init`, you choose your architecture pattern:

```bash
npx rig-spec init
# → "What architecture? (clean / mvc / ddd / none)"
# → "Frontend included? (react / vue / none)"
# → Generates pre-filled rules templates for your stack
```

You get rules files already structured for your choices. Fill in the specifics, and enforcement starts on the first task.

### For Existing Projects — Discover First

When running `rig-spec init --retrofit`, or at any point:

```bash
npx rig-spec discover
```

**What `discover` does:**
1. Analyzes your codebase — folder structure, file naming, import patterns, class/component shapes
2. Generates **draft** standards files in `.rig/feedforward/rules/`
3. Marks every discovery as `[DRAFT — please review]`
4. You review, correct, and approve each rule
5. Sensors are configured automatically based on approved rules

**Why human review is required:** Discovered patterns may be accidents, not decisions. The human approves what's intentional. What's intentional becomes a rule. Rules become sensors.

### How It Works End to End

```
1. rig-spec discover (or init)
   → .rig/feedforward/rules/*.rules.md created

2. rig-spec run task-01
   → agent receives: task + spec + ALL rules files
   → agent knows your patterns before writing code

3. rig-spec validate task-01
   → arch.sensor    → checks module boundaries (dependency-cruiser)
   → naming.sensor  → checks naming (ESLint custom rules)
   → standards-compliance.sensor → AI checks semantic compliance with rules/
   → validator agent confirms everything

4. FAILED: "UserService imports directly from PaymentRepository — violates arch rules"
   → implementer receives specific violation
   → fixes it
   → retry
```

### Standards as Living Documentation

Your `rules/` files are not just enforcement tools — they are the documented contract of how your project is built. Any new developer (human or AI) reads them and immediately understands the codebase conventions.

When a pattern evolves, you update the rule. The sensors immediately enforce the new pattern everywhere going forward.

---

## What rig-spec Is NOT

- ❌ A code boilerplate or project generator
- ❌ A tool that only works with one AI model
- ❌ Something that reorganizes your existing project
- ❌ A replacement for your development tools
- ❌ A prompt collection

**rig-spec is the structure around your agents — not a replacement for them.**

---

## License

MIT
