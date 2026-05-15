# rig-spec — Roadmap

> What to build, in what order, and why.
> Each phase has a clear goal, concrete deliverables, and solves specific agent failure patterns.

---

## Guiding Principle

Every addition to `rig-spec` must solve one of the 13 documented agent failure patterns.
If it doesn't solve a documented failure, it doesn't get built.

```
Documented failure → Design solution → Build → Validate with real use
```

---

## Failure Pattern Coverage by Phase

| # | Failure Pattern | Phase that solves it |
|---|---|---|
| 1 | One Shot Hero | Phase 1 (specs + tasks) |
| 2 | Premature Victory | Phase 1 (contracts) |
| 3 | Session Amnesia | Phase 1 (progress + bootstrap) |
| 4 | Untested Features | Phase 3 (sensors) |
| 5 | Single Process | Phase 3 (two-agent orchestration) |
| 6 | Accumulated Slope | Phase 3 (continuous sensors) |
| 7 | Context Window Pollution | Phase 2 (research/ + RPI pattern) |
| 8 | Spec Drift | Phase 3 (spec compliance sensor) |
| 9 | Architecture Fitness Violation | Phase 3 (arch sensors) |
| 10 | Parallel Task Conflicts | Phase 1 (file ownership in contracts) |
| 11 | Spec Quality Gap | Phase 2 (rules + spec linting) |
| 12 | Behavioural Harness Gap | Phase 1 (approved fixtures in spec) |
| 13 | Continuous Drift | Phase 3 (audit sensors) |

---

## Phase 0 — Foundation ✅

**Goal:** Full design documented and understood before writing any code.

**Why first:** Building without a spec is exactly what rig-spec is designed to prevent. The framework must use its own methodology from day one.

### Deliverables
- [x] `VISION.md` — what it is, why it exists, the 13 failure patterns
- [x] `ARCHITECTURE.md` — layer structure, skills, MCP, harness levels, adapter system
- [x] `WORKFLOW.md` — complete flow, two-agent pattern, contract format, CLI reference
- [x] `ROADMAP.md` — this file

---

## Phase 1 — Core Structure (Level 1 Harness) ✅

**Goal:** A usable harness that works in any project today, with zero tooling required.

**Solves:** patterns 1, 2, 3, 10, 12

### 1.1 — Folder Template ✅

The complete `.rig/` folder structure as a copyable template.

```
templates/.rig/
├── HARNESS.md
├── feedforward/
│   ├── specs/
│   │   └── _TEMPLATE.spec.md
│   ├── tasks/
│   │   └── _TEMPLATE.task.md
│   ├── rules/
│   │   ├── architecture.rules.md
│   │   ├── naming.rules.md
│   │   ├── structure.rules.md
│   │   ├── component.rules.md
│   │   ├── api.rules.md
│   │   └── testing.rules.md
│   ├── skills/
│   │   └── _TEMPLATE.skill.md
│   └── mcp.config.md
├── feedback/
│   ├── sensors/
│   │   └── _TEMPLATE.sensor.md
│   ├── review/
│   │   └── code-review.review.md
│   └── audit/
│       ├── dead-code.audit.md
│       ├── dependency-health.audit.md
│       └── drift-report.audit.md
├── memory/
│   ├── progress.md
│   ├── bootstrap.md
│   ├── decisions.md
│   └── research/
│       └── _TEMPLATE.research.md
├── orchestration/
│   ├── contracts/
│   │   └── _TEMPLATE.contract.md
│   ├── implementer.md
│   └── validator.md
└── adapters/
    ├── claude.md
    ├── gemini.md
    └── antigravity.md
```

### 1.2 — `HARNESS.md` Template ✅

The entry point file. Every agent reads this first.

Required sections:
- Project name and one-line description
- Harness level active
- Tech stack
- Current active feature (or "none")
- Pointers to specs, tasks, progress, bootstrap
- Available skills and MCP servers (empty until Phase 2)

### 1.3 — Rules Templates (Standards System) ✅

```
templates/.rig/feedforward/rules/
├── architecture.rules.md
├── naming.rules.md
├── structure.rules.md
├── component.rules.md   ← frontend only
├── api.rules.md
└── testing.rules.md
```

Each template includes an explanation of what it covers, common examples with blanks to fill in, and instructions for the agent on how to apply the rules.

Rules files are **feedforward** — loaded into agent context before every task. They also serve as input for the standards compliance sensors in Phase 3.

During `init`:
- New projects: filled from architecture pattern choice (clean / mvc / ddd)
- Existing projects: left blank, to be populated by `rig-spec discover` (Phase 4 CLI)

### 1.4 — Spec Template ✅

```
templates/.rig/feedforward/specs/_TEMPLATE.spec.md
```

Required sections:
- Problem
- Goal
- Out of Scope
- User Stories
- Acceptance Criteria
- Approved Fixtures (behavioural harness — humans define expected outputs)

### 1.4 — Task Template ✅

```
templates/.rig/feedforward/tasks/_TEMPLATE.task.md
```

Required sections:
- Spec Reference
- What to Build
- Where to Build It
- File Ownership (prevents parallel conflicts)
- Reuse (what already exists to use)
- Dependencies (which tasks must complete first)
- Enables (which tasks this unblocks)
- Skills to Load
- Contract (Definition of Done — checklist)

### 1.5 — Contract Template ✅

```
templates/.rig/orchestration/contracts/_TEMPLATE.contract.md
```

Standard agreement between implementer and validator:
- Implementer commits to (checklist)
- Validator must check (verification method per item)
- File ownership declaration

### 1.6 — Progress Template ✅

```
templates/.rig/memory/progress.md
```

### 1.7 — Bootstrap Template ✅

```
templates/.rig/memory/bootstrap.md
```

Ordered reading list for context reconstruction:
1. `.rig/HARNESS.md`
2. `.rig/memory/progress.md`
3. `.rig/memory/decisions.md` (when exists)
4. Active spec file
5. Next pending task file

### How to Use Phase 1 (No CLI Required)

```bash
# Copy the template into your project
cp -r rig-spec/templates/.rig your-project/

# Fill in HARNESS.md with your project details
# Create your first spec from _TEMPLATE.spec.md
# Break it into tasks using _TEMPLATE.task.md
# Track progress in memory/progress.md
```

**Phase 1 works with zero tooling. It is files and discipline.**

---

## Phase 2 — Memory + Skills + MCP (Level 2 Harness) ✅

**Goal:** Full context persistence, architectural memory, specialized knowledge injection, and MCP integration.

**Solves:** patterns 7, 11

### 2.1 — Decisions Log Template

```
.rig/memory/decisions.md
```

ADR-style (Architecture Decision Record) format:
```markdown
## [date] — [Decision Title]
**Decided:** [what was chosen]
**Alternatives:** [what was considered]
**Rationale:** [why this option]
**Impact:** [what this affects going forward]
```

### 2.2 — Research Folder

```
.rig/memory/research/
└── _TEMPLATE.research.md
```

Research session output format:
- Topic investigated
- Key findings
- Relevant files discovered
- Patterns already in use
- Recommended approach
- Open questions

### 2.3 — Rules Templates

```
.rig/feedforward/rules/
├── architecture.rules.md    ← module boundaries, layering rules
├── coding.rules.md          ← naming, structure, style
└── testing.rules.md         ← test requirements, fixture requirements
```

Rules are injected into every agent context before task execution. They prevent recurring mistakes without human intervention.

### 2.4 — Local Skill Template

```
.rig/feedforward/skills/_TEMPLATE.skill.md
```

Required sections:
- Technology/domain name
- Context (what it is, how this project uses it)
- Patterns to follow (with codebase examples)
- Pitfalls to avoid
- Key files to reference

### 2.5 — MCP Configuration Template

```
.rig/feedforward/mcp.config.md
```

Declares available MCP servers:
- Server name and purpose
- When to use it (which task types benefit)
- Config file reference
- Usage examples

### 2.6 — Adapter Templates

```
.rig/adapters/
├── claude.md
├── gemini.md
└── antigravity.md
```

Optional tool-specific instructions that supplement `HARNESS.md`.

---

## Phase 3 — Sensors + Two Agents (Level 3 Harness) ✅

**Goal:** Automated validation, full implementer/validator separation, spec compliance, and continuous monitoring.

**Solves:** patterns 4, 5, 6, 8, 9, 13

### 3.1 — Sensor Definition Templates

```
.rig/feedback/sensors/
├── _TEMPLATE.sensor.md
├── lint.sensor.md
├── test.sensor.md
├── typecheck.sensor.md
├── arch.sensor.md                    ← module boundaries (dependency-cruiser)
├── naming.sensor.md                  ← naming conventions (ESLint custom rules)
├── structure.sensor.md               ← folder/file organization (custom script)
├── spec-compliance.sensor.md         ← inferential: verifies impl matches spec
└── standards-compliance.sensor.md    ← inferential: verifies impl matches rules/
```

**Standards sensors explained:**

`arch.sensor.md` — computational. Runs dependency-cruiser or equivalent. Checks that module boundaries defined in `architecture.rules.md` are not violated. Example: "the `orders` module cannot import directly from `payments`."

`naming.sensor.md` — computational. Runs ESLint with custom rules generated from `naming.rules.md`. Checks file names, class names, function names against defined conventions.

`structure.sensor.md` — computational. Runs a custom script derived from `structure.rules.md`. Checks that each file type lives in the expected folder.

`standards-compliance.sensor.md` — inferential. The AI reviewer reads ALL `rules/` files and checks the implementation semantically. Catches violations that deterministic tools cannot detect: wrong layer for business logic, component responsibility violations, API envelope inconsistencies, test coverage gaps.

Each sensor definition:
- Command to run
- Expected exit code (0 = pass)
- How to interpret output for the agent
- Timing (after-task, post-integration, continuous)
- Error message format optimized for LLM correction

### 3.2 — Implementer Agent Profile

```
.rig/orchestration/implementer.md
```

Instructions:
- Read full assembled context (spec + task + rules + skills)
- Build only what the task contract specifies
- Sign each contract item when complete
- Do not self-validate or run sensors
- Do not modify files outside declared file ownership

### 3.3 — Validator Agent Profile

```
.rig/orchestration/validator.md
```

Instructions:
- Read signed contract + code + sensor results
- Check every contract item deterministically
- Do not suggest improvements outside contract scope
- Return: pass or specific failure list with file + line references
- Never mark as pass if any item is unchecked

### 3.4 — Review Agent Template (inferential sensor)

```
.rig/feedback/review/
└── code-review.review.md
```

Instructions for the review agent:
- Scope: only the files changed in this task
- Check: spec compliance, approved fixtures, architectural rules
- Output format optimized for agent self-correction

### 3.5 — Audit Sensor Templates

```
.rig/feedback/audit/
├── dead-code.audit.md
├── dependency-health.audit.md
└── drift-report.audit.md
```

Continuous sensors that run on schedule, outside the change lifecycle. Report health trends, not just current state.

---

## Phase 4 — CLI (bash) ✅

**Goal:** Um único script bash que qualquer pessoa instala com `curl | bash` e começa a usar imediatamente em qualquer projeto.

**Why bash:** rig-spec é agnostic a linguagem, modelo e stack. Exigir um runtime (Node.js, Python, Go) contradiz esse princípio — um dev Python não deveria precisar instalar Node.js para usar uma ferramenta agnostic. Bash roda em qualquer Unix (Mac, Linux) sem dependências.

### 4.1 — Dois arquivos, dois papéis

```
rig-spec/
├── install.sh      ← instalador global: baixa e instala o comando rig-spec no PATH
├── rig-spec.sh     ← o CLI: todos os subcomandos, templates embutidos
└── templates/
    └── .rig/       ← templates estáticos (copiável manualmente — Phase 1)
```

**Fluxo de instalação:**
```bash
# Uma linha — instala o comando rig-spec globalmente
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash

# Em qualquer projeto, a partir daí:
rig-spec init
rig-spec status
rig-spec validate
```

### 4.2 — Subcomandos

| Comando | O que faz |
|---|---|
| `rig-spec init` | Cria `.rig/` no projeto atual, detecta stack e sensores |
| `rig-spec init --retrofit` | Modo retrofit: gera rules em branco marcadas [DRAFT] |
| `rig-spec status` | Lê `memory/progress.md` e exibe estado atual |
| `rig-spec resume` | Imprime o contexto completo para a próxima sessão do agente |
| `rig-spec validate [task]` | Lê `feedback/sensors/`, extrai e executa cada comando |
| `rig-spec audit` | Executa sensores de `feedback/audit/`, salva relatório |
| `rig-spec run <task-id>` | Monta contexto completo do task e imprime para o agente |
| `rig-spec research <topic>` | Cria arquivo de pesquisa em `memory/research/` |
| `rig-spec shape <feature>` | Cria spec a partir do template com campos a preencher |
| `rig-spec plan <spec>` | Cria estrutura de tasks a partir de uma spec |
| `rig-spec version` | Exibe versão instalada |

### 4.3 — Princípio dos comandos AI-assistidos

`run`, `research`, `shape` e `plan` são **context assemblers** — eles não chamam nenhuma API de AI.

O que eles fazem:
1. Leem os arquivos `.rig/` relevantes
2. Montam o contexto em um único bloco de markdown
3. Imprimem na tela ou salvam em `.rig/context-[task].md`
4. Instruem o usuário: "Cole este contexto no seu agente de IA"

Isso mantém o framework 100% agnostic — o agente pode ser Claude, Gemini, GPT ou qualquer outro.

### Technical Stack
```
Runtime:     bash (≥ 3.2 — compatível com macOS e Linux)
Language:    bash
File format: Markdown (no proprietary formats)
AI calls:    Nenhuma — delegado ao agente do usuário
Backend:     Nenhum — tudo em arquivos locais
Windows:     WSL ou Git Bash
```

---

## Phase 5 — Harness Templates ✅

**Goal:** Pre-built harnesses for the most common project topologies.

**Why last:** Templates are only useful after the harness design is proven in real use.

### Topologies

| Template | Stack | Rules pre-filled | Skills included | Sensors |
|---|---|---|---|---|
| `node-api` | Node.js / Express / NestJS + TypeScript | architecture, naming, api, testing | typescript, nodejs | lint (ESLint), typecheck (tsc), test (npm test) |
| `fullstack-nextjs` | Next.js + TypeScript + React | architecture, naming, component, api, testing | nextjs, react | lint (ESLint), typecheck (tsc), test (Jest) |
| `python-api` | Python + FastAPI | architecture, naming, api, testing | fastapi, python | lint (Ruff), typecheck (mypy), test (pytest) |
| `generic` | Language-agnostic | blank stubs only | skill template only | none |

### How templates are applied

**Automatic** — `rig-spec init` detects the stack and applies the matching template:
```bash
# project with package.json + express → node-api rules + skills applied automatically
rig-spec init

# project with pyproject.toml → python-api rules + skills applied automatically
rig-spec init
```

**Manual override** — force a specific template regardless of detection:
```bash
rig-spec init --template node-api
rig-spec init --template python-api
rig-spec init --template fullstack-nextjs
rig-spec init --template generic
```

**Manual install** (no CLI) — copy the topology folder directly:
```bash
cp -r rig-spec/templates/node-api/.rig your-project/
```

### Static template files

```
templates/
├── .rig/                    ← generic base (all stack-agnostic files)
├── node-api/.rig/
│   ├── feedforward/rules/   ← architecture, naming, api, testing (Node.js)
│   ├── feedforward/skills/  ← typescript.skill.md, nodejs.skill.md
│   └── feedback/sensors/    ← lint, typecheck, test
├── python-api/.rig/
│   ├── feedforward/rules/   ← architecture, naming, api, testing (Python)
│   ├── feedforward/skills/  ← fastapi.skill.md, python.skill.md
│   └── feedback/sensors/    ← lint (ruff), typecheck (mypy), test (pytest)
└── fullstack-nextjs/.rig/
    ├── feedforward/rules/   ← architecture, naming, component, api, testing (Next.js)
    ├── feedforward/skills/  ← nextjs.skill.md, react.skill.md
    └── feedback/sensors/    ← lint, typecheck, test
```

---

## What Will NOT Be Built

Explicit non-goals. If they appear in a PR, they will be rejected.

| Not building | Why |
|---|---|
| Visual UI / dashboard | Adds complexity without proportional value for a file-based system |
| Cloud sync or backend | Everything stays local — simplicity and privacy are features |
| Custom DSL | Markdown is universal. A DSL creates lock-in and learning overhead |
| Model-specific features | Any feature that only works with one LLM violates the agnostic principle |
| Code scaffolding / boilerplate | rig-spec structures how you work, not what you build |
| Opinionated project structure | The `.rig/` folder is the only structure rig-spec requires |

---

## Decision Log

| # | Decision | Alternatives | Rationale |
|---|---|---|---|
| D1 | Name: `rig-spec` | Scaffold, Forge, Spine | Captures both pillars: rig (operational harness) + spec (spec-driven) |
| D2 | Folder: `.rig/` | `.harness/`, `.ai/`, `.context/` | Matches framework name, short, unique namespace, unlikely to conflict |
| D3 | Layers over phases | Phase-based (Kiro-style), plugin-based | Teaches feedforward/feedback concepts through structure |
| D4 | Markdown + YAML only | Custom DSL, binary formats | Universal, zero lock-in, human and agent readable |
| D5 | Two separate agents | Single agent with self-review | Eliminates self-evaluation bias; objective validation |
| D6 | Explicit contracts per task | Implicit validation | Clear agreement between agents, no ambiguity about done |
| D7 | Automatic validate after run | Manual opt-in | System decides when done, not the agent |
| D8 | Three memory files + research/ | Database, structured JSON | No dependencies, human and agent readable, sessions are independent |
| D9 | `curl \| bash` global installer + bash CLI | npx, Go binary, Python package | Zero dependencies — bash runs everywhere; one command installs globally |
| D10 | Greenfield + retrofit support | Greenfield only | Existing projects are the primary real-world use case |
| D11 | Harness levels (1, 2, 3) | All-or-nothing | Progressive adoption; start simple, add complexity when needed |
| D12 | Sensor discovery on retrofit | Manual sensor config | Reduces setup friction; starts from what already exists |
| D13 | Skills inside `.rig/feedforward/skills/` | External-only, separate repo | Local skills for project-specific knowledge; external for shared patterns |
| D14 | MCP config in `feedforward/mcp.config.md` | Separate MCP config file | Keeps all feedforward context in one layer |
| D15 | Approved fixtures in spec | AI-generated test definitions | Humans define what "correct" looks like before any agent writes tests |
| D16 | File ownership in task contracts | No ownership tracking | Prevents parallel task conflicts without coordination overhead |
| D17 | `research/` in memory/ | Research in specs/, separate folder | Keeps research separate from specs; clean boundary between discovery and planning |
| D18 | `audit` command for continuous drift | Ad-hoc manual checks | Continuous sensors catch what per-task sensors miss; health trends over time |
| D19 | Standards in `feedforward/rules/` as both context AND sensor input | Separate standards docs, runtime-only rules | Single source of truth: same file guides agent AND drives compliance sensors |
| D20 | `discover` generates drafts requiring human approval | Auto-apply discovered patterns | Discovered patterns may be accidents; only humans decide what's intentional |
| D21 | Computational + inferential standards sensors | Computational only | Linters catch structure; AI reviewer catches semantic violations linters cannot |
| D22 | CLI em bash puro | Node.js/TypeScript, Go, Python | rig-spec é agnostic a linguagem — exigir um runtime contradiz o princípio. Bash roda sem dependências em qualquer Unix |
| D23 | CLI = context assembler para comandos AI-assistidos | CLI chama API diretamente | Manter 100% agnostic ao modelo; o agente é do usuário, não do framework |
