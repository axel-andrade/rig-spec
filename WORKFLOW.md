# rig-spec — Workflow

> The complete development flow using rig-spec.
> From project initialization to validated, production-ready features.

---

## Overview

The `rig-spec` workflow follows a clear sequence:

```
init → overview → research → shape → plan → run → validate → audit
```

Each step has a specific purpose, a clear input, and a defined output. Nothing moves forward without completing the previous step.

---

## The Flow in Detail

### Step 1 — `init`

**Purpose:** Set up the harness for the project.

**Command:**
```bash
# New project
rig-spec init

# Existing project — scans src/ and infers structure
rig-spec init --retrofit
```

**What happens:**
1. Asks what the project does — seeds `HARNESS.md` Vision and Business Rules
2. Creates the `.rig/` folder structure
3. Scans the project for existing sensors (linters, test scripts, CI configs)
4. Detects the tech stack (`package.json`, `go.mod`, `requirements.txt`, etc.)
5. Generates a `HARNESS.md` with `## Vision` and `## Business Rules` pre-filled
6. In `--retrofit` mode: scans `src/` tree, detects TypeScript, detects test pattern, generates `structure.rules.md` from real folder layout

**Output:**
```
.rig/
├── HARNESS.md            ← generated from project scan
├── feedforward/
│   ├── specs/            ← empty, ready for specs
│   ├── tasks/            ← empty, ready for tasks
│   ├── rules/            ← empty, ready for rules
│   └── skills/           ← empty, ready for skills
├── feedback/
│   └── sensors/          ← populated from discovered tools
├── memory/
│   ├── progress.md       ← initialized, empty
│   ├── bootstrap.md      ← generated reading order
│   └── research/         ← empty, ready for research notes
└── orchestration/        ← empty until Level 3
```

**Why this step exists:** Without init, every project starts differently. The harness has no baseline, no discovered context, no structure. Init is the contract between you and the framework.

---

### Step 2 — `overview`

**Purpose:** Review and complete the project's vision and business rules before any work starts.

**Command:**
```bash
rig-spec overview
```

**What it shows:**
- **Project** — name, stack, description
- **Vision** — the product north star (auto-seeded from init, review and expand)
- **Business Rules** — non-negotiable domain constraints
- **Current Focus** — active feature and next task
- **Last Session** — what happened and what's next

**After running:**
Open `.rig/HARNESS.md` and complete:

```markdown
## Vision
[What the product is, who it serves, what core problem it solves.]

## Business Rules
- [Rule 1 — domain constraint the agent must never violate]
- [Rule 2 — ...]
```

Business rules are domain knowledge, not implementation details. Examples:
- "A patient record may only be accessed by its assigned practitioner"
- "Medication doses must be validated against patient weight before saving"
- "An invoice cannot be deleted after it has been sent"

These rules are injected into every `run` context — agents know them before writing any code.

**Why this step exists:** Agents that don't know the domain rules will produce technically correct code that violates business logic. Vision gives direction. Business rules set hard constraints.

---

### Step 3 — `research` (optional but recommended)

**Purpose:** Investigate before specifying. Saves findings in a clean, reusable file.

**Command:**
```bash
rig-spec research "how notifications should work in this codebase"
```

**What happens:**
1. Opens a dedicated research session (separate context window)
2. The agent explores the codebase, reads existing patterns, checks dependencies
3. Findings are written to a clean markdown file

**Output:**
```
.rig/memory/research/notifications.md
```

**Why this step exists:** This solves **Context Window Pollution**. Without it, research happens in the same window as implementation — polluting it with dead ends, failed explorations, and irrelevant context. Implementation then starts in a dirty window and hallucinates more.

With `research`, implementation starts in a clean window and reads only the distilled findings.

**The RPI Pattern:**
```
Research  → open, explore, discover → save to memory/research/
Plan      → read research, write spec and tasks
Implement → read spec + tasks + research findings (clean context)
```

---

### Step 4 — `shape`

**Purpose:** Create a spec for a feature or piece of work.

**Command:**
```bash
rig-spec shape "notification system"

# Or provide context upfront
rig-spec shape "notification system" --from prd.md
```

**What happens:**
1. The agent reads any existing research findings in `memory/research/`
2. Asks clarifying questions about the feature (or reads the PRD)
3. Validates spec completeness before writing (inferential sensor)
4. A structured spec file is generated

**Output:**
```
.rig/feedforward/specs/notification-system.spec.md
```

**Spec structure:**
```markdown
# Spec: Notification System

## Problem
Users have no awareness of events that happen while they're offline.

## Goal
Deliver real-time and async notifications across email and in-app channels.

## Out of Scope
- Push notifications (mobile)
- Notification preferences UI (separate spec)

## User Stories
- As a user, I want to receive an email when someone mentions me
- As a user, I want to see a badge count of unread notifications

## Acceptance Criteria
- Notifications are stored persistently in the database
- Email delivery works via the configured provider
- In-app notifications update in real-time via WebSocket
- Unread count badge updates without page refresh

## Approved Fixtures (Behavioural Harness)
### Input: user mentioned in comment
### Expected output:
  - notification record created with type: "mention"
  - email queued within 5 seconds
  - in-app badge count incremented by 1
```

**Why this step exists:** Specs are the single source of truth. They prevent the agent from improvising, eliminate ambiguity, and give the validator something concrete to check against. The approved fixtures section solves the **Behavioural Harness Gap** — humans define what "correct" looks like before any test is written.

---

### Step 5 — `plan`

**Purpose:** Break the spec into ordered, executable tasks.

**Command:**
```bash
rig-spec plan notification-system
```

**What happens:**
1. The agent reads the spec
2. Analyzes dependencies between pieces of work
3. Identifies what can run in parallel vs. sequentially
4. Assigns file ownership to each task (prevents Parallel Task Conflicts)
5. Generates individual task files with full context and contracts

**Output:**
```
.rig/feedforward/tasks/notification-system/
├── task-01-database-schema.md       ← must run first
├── task-02-notification-service.md  ← depends on task-01
├── task-03-email-adapter.md         ← parallel with task-04
├── task-04-websocket-adapter.md     ← parallel with task-03
└── task-05-api-endpoints.md         ← depends on 02, 03, 04
```

**Task structure:**
```markdown
# Task 01 — Database Schema

## Spec Reference
→ notification-system.spec.md

## What to Build
Create the `notifications` table with all required fields.

## Where to Build It
- Migration: `db/migrations/[timestamp]_create_notifications.ts`
- Model: `src/notifications/notification.model.ts`

## File Ownership (no other task may modify these files)
- db/migrations/*_create_notifications.ts
- src/notifications/notification.model.ts

## Reuse
- Follow the pattern in `src/users/user.model.ts`
- Use the existing migration runner in `db/migrate.ts`

## Dependencies
- None (this is task 01)

## Enables
- Task 02 (notification service depends on this schema)

## Skills to load
- postgres.skill.md
- testing.skill.md

## Contract (Definition of Done)
- [ ] Migration runs without errors
- [ ] Migration can be rolled back cleanly
- [ ] `notifications` table has all required fields
- [ ] Model has correct TypeScript types
- [ ] Unit tests for the model pass
- [ ] Approved fixtures from spec pass
```

**Why this step exists:** Without a plan, agents either do too much at once (One Shot Hero) or do too little and declare victory. File ownership prevents Parallel Task Conflicts. The contract defines what done means before any code is written.

---

### Step 6 — `run`

**Purpose:** Execute a task with a fully assembled context.

**Command:**
```bash
rig-spec run task-01
```

**What happens:**
1. The CLI assembles the full context into `.rig/context-[task-id].md`:
   - `.rig/HARNESS.md` (project overview)
   - `.rig/memory/progress.md` (current state)
   - `.rig/feedforward/specs/[spec].spec.md` (the spec)
   - `.rig/feedforward/tasks/[feature]/[task].md` (the task)
   - `.rig/feedforward/rules/` (coding conventions)
   - Relevant skills listed in the task
2. You paste the assembled context into your AI agent of choice
3. The **implementer agent** reads the context, writes the code, signs the contract
4. You run `rig-spec validate` to check the result

> `run` is a context assembler — it prepares and prints the context. No AI call is made. The agent is yours.

**Why assembling context matters:** Without full context, the agent improvises. With assembled context, it has everything it needs in one clean window — fewer tokens, better results, no guessing.

**If the agent cannot finish in one session (Continuation Protocol):**

If the agent's context fills up or the task is larger than expected, it should:
1. Write a `[CHECKPOINT]` to `memory/progress.md` describing exactly where it stopped and what remains
2. Leave unfinished contract items unchecked
3. Signal: `CHECKPOINT SAVED — run rig-spec resume to continue in a clean context`

Then run `rig-spec resume` — the next agent starts with a clean context window and reads the checkpoint to know exactly where to pick up.

---

### Step 7 — `validate`

**Purpose:** Verify the implementation against the contract, sensors, and project standards (via review).

**Run after every `run`, once the agent has finished:**
```bash
rig-spec validate task-01
```

**What happens:**

1. Prints the task **contract checklist**
2. Runs every **computational** sensor in `.rig/feedback/sensors/`
3. Marks **inferential** sensors (`standards-compliance`, `spec-compliance`) as `REVIEW`
4. Writes a **validation report** to `.rig/feedback/reports/validation-task-01-YYYY-MM-DD.md` with a sensor matrix table
5. Tells you to run the **review agent** with `code-review.review.md`, `validation-matrix.review.md`, and applicable `feedforward/rules/`

#### Which sensors are active

**Auto-discovered on `rig-spec init`** (found by scanning the project):
- ESLint → `lint.sensor.md` (if `.eslintrc.*` or `eslint.config.*` found)
- TypeScript → `typecheck.sensor.md` (if `tsconfig.json` found)
- npm test → `test.sensor.md` (if `"test"` script in `package.json` found)
- Ruff → `lint.sensor.md` (if `ruff.toml` or `[tool.ruff]` in `pyproject.toml`)
- mypy → `typecheck.sensor.md` (if `mypy.ini` or `[tool.mypy]` in `pyproject.toml`)
- pytest → `test.sensor.md` (if `pytest.ini` or `[tool.pytest]` in `pyproject.toml`)

**Require manual configuration** (templates provided, commands need adjusting):
- `arch.sensor.md` — dependency boundary checks (dependency-cruiser, custom script)
- `naming.sensor.md` — naming convention checks (ESLint custom rules)
- `structure.sensor.md` — folder layout checks (custom script)
- `spec-compliance.sensor.md` — inferential: AI verifies impl matches spec
- `standards-compliance.sensor.md` — inferential: AI verifies impl matches rules/

To add a sensor manually: copy `_TEMPLATE.sensor.md`, fill in the `## Command` block, and `rig-spec validate` will pick it up automatically.

#### Phase A — Computational Sensors (fast, deterministic)
```bash
→ lint.sensor.md         → runs your linter (ESLint, Ruff, etc.)
→ typecheck.sensor.md    → runs your type checker (tsc, mypy)
→ test.sensor.md         → runs your test suite (npm test, pytest)
→ arch.sensor.md         → checks module boundaries (manual config required)
```

#### Phase B — Inferential Sensors (AI-assisted, semantic)
```
→ spec-compliance.sensor.md       (manual config required)
  Verifies implementation against spec acceptance criteria
  Checks approved fixtures produce expected outputs

→ standards-compliance.sensor.md  (manual config required)
  AI reviewer reads rules/ and checks semantic compliance
  Catches violations linters cannot: wrong layer, wrong abstraction
```

#### Phase C — Contract Validation (the validator agent)

The **validator agent** receives:
- The signed contract from the implementer
- The code that was written
- All sensor results

It checks every item in the contract:

```markdown
Contract: notification-system / task-01

- [x] Migration runs without errors         ← sensors confirmed
- [x] Migration can be rolled back cleanly  ← validator checked manually
- [x] `notifications` table has all fields  ← validator checked schema
- [x] Model has correct TypeScript types    ← typecheck confirmed
- [ ] Unit tests for the model pass         ← FAILED: missing edge case test
- [ ] Approved fixtures pass                ← FAILED: badge count not updating
```

#### Phase D — Decision

```
ALL PASSED → implementer writes discoveries to memory/learnings.md
           → progress.md updated → ready for next task
ANY FAILED → implementer receives specific failures → retry
```

**The retry loop:**
```
run → validate FAILED
   → implementer receives: list of specific contract failures + sensor output
   → implementer fixes only the failing items
   → validate runs again
   → (up to configured max retries, then escalates to human)
```

**Why two agents:** If the implementer validates its own work, it will find reasons why it passed. The validator has one job: find what's wrong. Separate missions, no bias.

---

### Step 8 — `audit` (scheduled, outside change cycle)

**Purpose:** Detect drift that accumulates between tasks — not visible in any single change.

**Command:**
```bash
rig-spec audit
```

**What happens:**
1. Runs continuous drift sensors from `feedback/audit/`
2. Checks for: dead code, outdated dependencies, architectural drift, unused exports
3. Reports health trends over time (not just the current state)

**Output:**
```
.rig/feedback/audit/report-[date].md
```

**Why this step exists:** This solves **Continuous Drift**. Individual tasks may pass all sensors, but gradual accumulation of small violations degrades the codebase over time. Audit runs on a schedule and catches what per-task sensors miss.

---

## Memory Between Sessions

When you return to a project after any break, run:

```bash
rig-spec resume
```

This triggers the bootstrap sequence:

```
1. Read .rig/HARNESS.md
   → understand the project

2. Read .rig/memory/progress.md
   → know what's done and what's next (including any [CHECKPOINT] markers)

3. Read .rig/memory/decisions.md
   → remember why things are the way they are

4. Read .rig/memory/learnings.md
   → recall implementation discoveries and gotchas from previous tasks

5. Read .rig/memory/research/ (relevant files)
   → recall prior research findings

6. Read the active spec
   → understand the current feature context

7. Read the next pending task
   → know exactly what to work on
```

**No more wasted tokens figuring out where you left off.**

---

## Full Example: From Zero to Validated Feature

```bash
# Set up harness on existing project
rig-spec init --retrofit
# → .rig/ created, src/ scanned, HARNESS.md generated with Vision + Business Rules

# Review and complete vision + business rules
rig-spec overview
# → open .rig/HARNESS.md → fill in Vision and Business Rules

# Research before specifying
rig-spec research "notification patterns in this codebase"
# → .rig/memory/research/notifications.md created

# Spec the notification system
rig-spec shape "notification system"
# → .rig/feedforward/specs/notification-system.spec.md created

# Break into tasks
rig-spec plan notification-system
# → .rig/feedforward/tasks/notification-system/ with 5 tasks

# Run task 01
rig-spec run task-01
# → context assembled → implementer builds schema
# → sensors run → validator checks contract
# → PASSED → progress.md updated

# New session, no amnesia
rig-spec resume
# → context rebuilt → ready for task-02

# Run task 02
rig-spec run task-02
# → FAILED: missing error handling
# → implementer receives specific failure
# → retry → PASSED

# Check overall status
rig-spec status
# → notification-system: 2/5 tasks complete

# Run weekly audit
rig-spec audit
# → .rig/feedback/audit/report-2026-05-15.md generated
```

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
```

Installs the `rig-spec` command to `~/.local/bin/`. No runtime required. Works on Mac and Linux.

---

## CLI Reference

| Command | Description |
|---|---|
| `rig-spec init` | Initialize harness — auto-detects stack and applies matching template |
| `rig-spec init --retrofit` | Initialize for existing project — scans `src/` structure, rules as [DRAFT] |
| `rig-spec init --template <name>` | Force a specific template: `node-api`, `python-api`, `fullstack-nextjs`, `generic` |
| `rig-spec overview` | Show project vision, business rules, and current state in one screen |
| `rig-spec status` | Show progress across all active specs |
| `rig-spec resume` | Print full context for the next agent session |
| `rig-spec validate` | Run all sensors in `feedback/sensors/` |
| `rig-spec validate <task-id>` | Run sensors and show the task contract checklist |
| `rig-spec audit` | Run continuous drift sensors, save report |
| `rig-spec run <task-id>` | Assemble and print full task context for the agent |
| `rig-spec research <topic>` | Create a research file in `memory/research/` |
| `rig-spec shape <feature>` | Ask 5 questions, pre-fill spec, assemble context for agent |
| `rig-spec plan <spec-name>` | Create task structure from a spec |
| `rig-spec version` | Show installed version |

> `run`, `research`, `shape`, and `plan` are **context assemblers** — they prepare and print the context so you can paste it into your AI agent of choice. No API calls are made.
