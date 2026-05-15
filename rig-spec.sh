#!/usr/bin/env bash
# rig-spec — operational framework for AI-native development
# https://github.com/axel-andrade/rig-spec
set -e

RIGSPEC_VERSION="1.0.0"
RIG_DIR=".rig"
REPO="https://github.com/axel-andrade/rig-spec"
PROJECT_DESCRIPTION=""
RETROFIT=false

# ─────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RED='\033[0;31m'
RESET='\033[0m'

print_step() { echo -e "${BOLD}→ $1${RESET}"; }
print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
print_err()  { echo -e "  ${RED}✗${RESET} $1"; }
print_dim()  { echo -e "  ${DIM}$1${RESET}"; }

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

require_rig() {
  if [ ! -d "$RIG_DIR" ]; then
    echo ""
    print_err "No .rig/ folder found in this directory."
    echo ""
    echo "  Run first: rig-spec init"
    echo ""
    exit 1
  fi
}

today() { date +%Y-%m-%d; }

# Extracts the bash command block from a sensor/audit markdown file.
# Looks for ## Command followed by ```bash ... ```
extract_command() {
  local file="$1"
  awk '
    /^## Command/ { found=1; next }
    found && /^```bash/ { in_block=1; next }
    in_block && /^```/ { exit }
    in_block { print }
  ' "$file"
}

# ─────────────────────────────────────────────
# Stack & Sensor Detection
# ─────────────────────────────────────────────

detect_stack() {
  STACK="unknown"
  STACK_LABEL="Generic (language agnostic)"

  if [ -f "package.json" ]; then
    STACK="node"
    STACK_LABEL="Node.js"
    if grep -q '"next"' package.json 2>/dev/null; then
      STACK="nextjs"; STACK_LABEL="Next.js"
    elif grep -q '"@nestjs/core"' package.json 2>/dev/null; then
      STACK="nestjs"; STACK_LABEL="NestJS"
    elif grep -q '"express"' package.json 2>/dev/null; then
      STACK="express"; STACK_LABEL="Express"
    fi
    print_ok "Stack detected: $STACK_LABEL"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    STACK="python"; STACK_LABEL="Python"
    print_ok "Stack detected: Python"
  elif [ -f "go.mod" ]; then
    STACK="go"; STACK_LABEL="Go"
    print_ok "Stack detected: Go"
  elif [ -f "Cargo.toml" ]; then
    STACK="rust"; STACK_LABEL="Rust"
    print_ok "Stack detected: Rust"
  else
    print_warn "No specific stack detected — using generic template"
  fi
}

detect_sensors() {
  SENSORS=()

  if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || \
     [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || \
     [ -f ".eslintrc.cjs" ]; then
    SENSORS+=("eslint"); print_ok "ESLint found"
  fi

  if [ -f "ruff.toml" ] || ([ -f "pyproject.toml" ] && grep -q "ruff" pyproject.toml 2>/dev/null); then
    SENSORS+=("ruff"); print_ok "Ruff found"
  fi

  if [ -f "tsconfig.json" ]; then
    SENSORS+=("typescript"); print_ok "TypeScript found"
  fi

  if [ -f "mypy.ini" ] || ([ -f "pyproject.toml" ] && grep -q "mypy" pyproject.toml 2>/dev/null); then
    SENSORS+=("mypy"); print_ok "mypy found"
  fi

  if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    SENSORS+=("npm-test"); print_ok "npm test found"
  fi

  if [ -f "pytest.ini" ] || ([ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null); then
    SENSORS+=("pytest"); print_ok "pytest found"
  fi

  if [ -f "package.json" ] && grep -q '"depcruise"' package.json 2>/dev/null; then
    SENSORS+=("depcruise"); print_ok "dependency-cruiser found"
  fi

  if [ ${#SENSORS[@]} -eq 0 ]; then
    print_warn "No sensors detected — starting at Level 1 (manual validation)"
  fi
}

# Refines stack detection using free-text description keywords.
# Only overrides if the file-based detection found nothing.
refine_stack_from_description() {
  local desc="${PROJECT_DESCRIPTION,,}"
  [ -z "$desc" ] && return

  # Only override if still unknown
  if [ "$STACK" = "unknown" ]; then
    if echo "$desc" | grep -qE "next\.?js|nextjs"; then
      STACK="nextjs"; STACK_LABEL="Next.js"
    elif echo "$desc" | grep -qE "nest\.?js|nestjs"; then
      STACK="nestjs"; STACK_LABEL="NestJS"
    elif echo "$desc" | grep -qE "\bexpress\b"; then
      STACK="express"; STACK_LABEL="Express"
    elif echo "$desc" | grep -qE "react|vue|angular|svelte|vite"; then
      STACK="node"; STACK_LABEL="Node.js"
    elif echo "$desc" | grep -qE "fastapi|django|flask|\bpython\b"; then
      STACK="python"; STACK_LABEL="Python"
    elif echo "$desc" | grep -qE "\bgo\b|golang"; then
      STACK="go"; STACK_LABEL="Go"
    elif echo "$desc" | grep -qE "\brust\b|cargo"; then
      STACK="rust"; STACK_LABEL="Rust"
    fi

    if [ "$STACK" != "unknown" ]; then
      print_ok "Stack inferred from description: $STACK_LABEL"
    fi
  fi
}

# ─────────────────────────────────────────────
# Template Writers
# ─────────────────────────────────────────────

write_harness_md() {
  local project_name
  project_name=$(basename "$(pwd)")

  local sensors_list=""
  if [ ${#SENSORS[@]} -gt 0 ]; then
    for s in "${SENSORS[@]}"; do sensors_list+="- $s"$'\n'; done
  else
    sensors_list="- None (Level 1 — manual contract validation)"
  fi

  cat > "$RIG_DIR/HARNESS.md" << EOF
# HARNESS — $project_name

> Read this file first. Every agent, every session, starts here.

---

## Project

**Name:** $project_name
**Stack:** $STACK_LABEL
**Description:** ${PROJECT_DESCRIPTION:-[Add a one-paragraph description of this project]}

---

## Harness Level

**Active Level: 1** (Spec Only)

- Level 1: specs + tasks + contracts + memory ← you are here
- Level 2: + decisions + research + rules + skills + MCP
- Level 3: + sensors + two-agent validation + audit

---

## Current Focus

**Active Feature:** none
**Next Task:** none

→ Create your first spec: \`feedforward/specs/_TEMPLATE.spec.md\`

---

## Context Reconstruction

To pick up where you left off in any new session, read in this order:

1. This file (HARNESS.md)
2. \`memory/progress.md\` — what's done and what's next
3. \`memory/decisions.md\` — key decisions made (when exists)
4. The active spec in \`feedforward/specs/\`
5. The current task in \`feedforward/tasks/\`

Full instructions: \`memory/bootstrap.md\`

---

## Available Skills

- None configured yet → see \`feedforward/skills/_TEMPLATE.skill.md\`

## MCP Servers

- None configured yet → see \`feedforward/mcp.config.md\`

## Active Sensors

$sensors_list
---

## Key Files

| File | Purpose |
|---|---|
| \`feedforward/specs/\` | Feature specifications |
| \`feedforward/tasks/\` | Task breakdowns per spec |
| \`feedforward/rules/\` | Coding conventions and architecture rules |
| \`feedforward/skills/\` | Specialized local knowledge |
| \`feedback/sensors/\` | Automated validation commands |
| \`memory/progress.md\` | Current state of all work |
| \`memory/decisions.md\` | Architectural decisions |
| \`memory/research/\` | Research session findings |
| \`orchestration/contracts/\` | Implementer-validator agreements |
EOF
  print_ok "HARNESS.md created"
}

write_progress_md() {
  cat > "$RIG_DIR/memory/progress.md" << 'EOF'
# Progress

> Updated after every validated task.
> This file is the source of truth for project state.

---

## Active Features

_No features in progress yet._

---

## Completed Features

_None yet._

---

## Last Session

**Date:** —
**What happened:** Project initialized with rig-spec.
**What's next:** Create your first spec in `feedforward/specs/`.
**Blockers:** None.
EOF
  print_ok "memory/progress.md created"
}

write_bootstrap_md() {
  cat > "$RIG_DIR/memory/bootstrap.md" << 'EOF'
# Bootstrap — Context Reconstruction

> Read this at the start of every new session.
> Following this order reconstructs full project context with minimum tokens.

---

## Reading Order

### 1. Project Overview
→ Read `.rig/HARNESS.md`
What it answers: What is this project? What level? What's active?

### 2. Current State
→ Read `.rig/memory/progress.md`
What it answers: What's done? What's next? Any blockers?

### 3. Architectural Decisions (when exists)
→ Read `.rig/memory/decisions.md`
What it answers: Why are things the way they are? Do not re-debate decided issues.

### 4. Research Findings (when relevant)
→ Read `.rig/memory/research/[relevant-topic].md`
What it answers: What was already investigated?

### 5. Active Feature Spec (when in progress)
→ Read `.rig/feedforward/specs/[active-feature].spec.md`
What it answers: What are we building? Acceptance criteria? Approved fixtures?

### 6. Current Task (when in progress)
→ Read the next pending task in `.rig/feedforward/tasks/[feature]/`
What it answers: What exactly to build? File ownership? Contract?

---

## After Reading

You are now fully context-aware. Proceed with the current task.
If something is unclear, ask — do not assume.
EOF
  print_ok "memory/bootstrap.md created"
}

write_decisions_md() {
  cat > "$RIG_DIR/memory/decisions.md" << 'EOF'
# Decisions

> ADR-style architectural decisions.
> Read before making any significant technical choice — do not re-debate decided issues.

---

_No decisions recorded yet._

---

## Template

```markdown
## [YYYY-MM-DD] — [Decision Title]

**Decided:** [What was chosen]
**Alternatives considered:** [What else was evaluated]
**Rationale:** [Why this option]
**Impact:** [What this means going forward]
```
EOF
  print_ok "memory/decisions.md created"
}

write_spec_template() {
  cat > "$RIG_DIR/feedforward/specs/_TEMPLATE.spec.md" << 'EOF'
# Spec: [Feature Name]

---

## Problem

[What problem does this feature solve? 2-4 sentences.]

---

## Goal

[What is the measurable outcome?]

---

## Out of Scope

- Not included:
- Not included:

---

## User Stories

- As a [user type], I want to [action] so that [benefit]

---

## Acceptance Criteria

- [ ] [Criterion 1 — must be testable]
- [ ] [Criterion 2 — must be testable]

---

## Approved Fixtures

> Humans define expected outputs here BEFORE agents write any tests.

### Fixture 1: [scenario name]
**Input:** [describe the input]
**Expected output:** [describe the exact expected output]

---

## Design Notes (optional)

[Architectural constraints the agent should know.]
EOF
  print_ok "feedforward/specs/_TEMPLATE.spec.md created"
}

write_task_template() {
  cat > "$RIG_DIR/feedforward/tasks/_TEMPLATE.task.md" << 'EOF'
# Task [XX] — [Task Name]

---

## Spec Reference

→ `feedforward/specs/[spec-name].spec.md`

---

## What to Build

[Clear description of what this task produces. 2-4 sentences.]

---

## Where to Build It

- Create: `src/[module]/[file].[ext]`
- Modify: `src/[module]/[other-file].[ext]`

---

## File Ownership

> No other task may modify these files while this task is in progress.

- `src/[module]/[file].[ext]`

---

## Reuse

- Follow the pattern in `src/[existing-module]/`

---

## Dependencies

- Task [XX] must be complete first (provides [what])

## Enables

- Task [XX+1] (needs [what this task produces])

---

## Skills to Load

- `feedforward/skills/[technology].skill.md`

---

## Contract — Definition of Done

- [ ] [Deliverable 1] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 2] ← verified by: [test / typecheck / validator]
- [ ] Approved fixtures from spec pass ← verified by: validator
- [ ] No files outside file ownership were modified ← verified by: validator
EOF
  print_ok "feedforward/tasks/_TEMPLATE.task.md created"
}

write_contract_template() {
  cat > "$RIG_DIR/orchestration/contracts/_TEMPLATE.contract.md" << 'EOF'
# Contract: [spec-name] / task-[XX]

---

## Implementer Commits To

- [ ] [Specific deliverable]
- [ ] [Specific deliverable]
- [ ] Approved fixtures from spec produce expected outputs
- [ ] No files outside declared file ownership were modified

## File Ownership

- `[file path]`

---

## Validator Must Check

| Item | Verification method |
|---|---|
| [Deliverable 1] | Run: `[command]` — expect exit 0 |
| [Deliverable 2] | Manually verify: [what to check] |

---

## Sensor Results

- [ ] lint: PASS / FAIL
- [ ] typecheck: PASS / FAIL
- [ ] tests: PASS / FAIL

## Verdict

- [ ] **PASSED** — all items verified, task complete
- [ ] **FAILED** — see failures below

### Failures (if any)

[File path, line number, expected vs actual.]
EOF
  print_ok "orchestration/contracts/_TEMPLATE.contract.md created"
}

write_skill_template() {
  cat > "$RIG_DIR/feedforward/skills/_TEMPLATE.skill.md" << 'EOF'
# Skill: [Technology or Domain Name]

> Load this skill when working on tasks involving [technology/domain].

---

## Context

[What this technology is and how this project uses it. 2-4 sentences.]

---

## Patterns to Follow

### Pattern 1: [Pattern Name]
[Explanation + example]
→ Reference: `src/[example-file]`

---

## Pitfalls to Avoid

- Do NOT: [anti-pattern]

---

## Key Files

- `src/[file]` — [what it shows]
EOF
  print_ok "feedforward/skills/_TEMPLATE.skill.md created"
}

write_rules_templates() {
  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << 'EOF'
# Architecture Rules

> DRAFT — fill in and remove [DRAFT] markers before activating.

---

## Module Boundaries

- `[module-a]` may NOT import from `[module-b]`
- `[shared]` may be imported by any module

## Layering Rules

- [Layer A] → [Layer B] → [Layer C] (allowed direction)

## Forbidden Patterns

- [e.g., Direct database access from controllers]

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << 'EOF'
# Naming Rules

> DRAFT — fill in and remove [DRAFT] markers before activating.

---

## Files

- [file type]: `[pattern]`

## Classes / Components

- [type]: `[casing + suffix rule]`

## Functions / Methods

- [type]: `[casing + prefix rule]`

## Variables / Constants

- [type]: `[casing rule]`

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/structure.rules.md" << 'EOF'
# Structure Rules

> DRAFT — fill in and remove [DRAFT] markers before activating.

---

## Folder Layout

```
src/
└── [describe your structure here]
```

## Placement Rules

- `[file type]` must live in: `[path]`

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'EOF'
# API Rules

> DRAFT — fill in and remove [DRAFT] markers before activating.

---

## Response Envelope

```json
{ "data": {}, "error": null }
```

## Error Format

```json
{ "data": null, "error": { "code": "ERROR_CODE", "message": "..." } }
```

## Endpoint Conventions

- List:   `GET    /[resource]`
- Single: `GET    /[resource]/:id`
- Create: `POST   /[resource]`
- Update: `PUT    /[resource]/:id`
- Delete: `DELETE /[resource]/:id`

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << 'EOF'
# Testing Rules

> DRAFT — fill in and remove [DRAFT] markers before activating.

---

## Coverage Requirements

- [Module]: minimum [X]%

## Test Location

- Unit tests: `[pattern]`
- Integration tests: `[path]`

## Approved Fixtures Policy

- Expected outputs are defined by humans in the spec BEFORE agents write tests.
- Agents may NOT change a fixture to make a failing test pass.

## Rules

- Do NOT mock the database in integration tests
- Test names must describe behavior, not implementation

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ templates created (5 files)"
}

# ─────────────────────────────────────────────
# Topology: Node.js / NestJS / Express
# ─────────────────────────────────────────────

write_rules_node() {
  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << 'EOF'
# Architecture Rules — Node.js (Layered)

---

## Layer Hierarchy

```
Controllers → Services → Repositories → Database
```

- `controllers/` handle HTTP: parse request, call service, return response. No business logic.
- `services/` contain all business logic. No HTTP concerns. No direct DB access.
- `repositories/` handle all database queries. Return domain objects, not raw rows.
- `shared/` utilities may be imported by any layer.

## Module Boundaries

- A controller may ONLY import from its own service.
- A service may ONLY import from repositories and shared/.
- A repository may NOT import from controllers or services.
- Cross-module imports go through interfaces, not concrete implementations.

## Forbidden Patterns

- Direct database access from a controller
- HTTP request/response objects inside a service
- Business logic inside a controller
- Raw SQL inside a service (use the repository)

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << 'EOF'
# Naming Rules — Node.js / TypeScript

---

## Files

- Controllers: `[name].controller.ts`
- Services: `[name].service.ts`
- Repositories: `[name].repository.ts`
- DTOs (input): `[name].dto.ts`
- Interfaces: `[name].interface.ts`
- Types: `[name].types.ts`
- Tests: `[name].spec.ts` or `[name].test.ts`
- Modules (NestJS): `[name].module.ts`

## Classes

- PascalCase with suffix: `UserService`, `OrderRepository`, `CreateUserDto`

## Functions and Methods

- camelCase: `getUserById`, `createOrder`, `validateEmail`
- Boolean helpers: `is`, `has`, `can` prefix: `isActive`, `hasPermission`

## Variables and Constants

- camelCase for variables: `userId`, `orderTotal`
- SCREAMING_SNAKE_CASE for module-level constants: `MAX_RETRY_COUNT`
- Env vars: `SCREAMING_SNAKE_CASE`

## Interfaces vs Types

- Use `interface` for object shapes that may be extended
- Use `type` for unions, intersections, and utility types

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'EOF'
# API Rules — REST / Node.js

---

## Response Envelope

All endpoints return the same envelope:

```json
{ "data": { ... }, "error": null }
```

On error:
```json
{ "data": null, "error": { "code": "ERROR_CODE", "message": "Human-readable message" } }
```

## HTTP Methods

- `GET    /[resource]`         — list (paginated)
- `GET    /[resource]/:id`     — single item
- `POST   /[resource]`         — create
- `PUT    /[resource]/:id`     — full replace
- `PATCH  /[resource]/:id`     — partial update
- `DELETE /[resource]/:id`     — delete

## Status Codes

- `200` OK (GET, PUT, PATCH)
- `201` Created (POST)
- `204` No Content (DELETE)
- `400` Bad Request (validation)
- `401` Unauthorized (missing/invalid token)
- `403` Forbidden (insufficient permissions)
- `404` Not Found
- `422` Unprocessable Entity (business rule violation)
- `500` Internal Server Error (unexpected)

## Validation

- Validate all inputs at the controller/route level using DTOs or schema validation.
- Never trust client-provided IDs without authorization checks.
- Return `400` for schema violations, `422` for business rule violations.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << 'EOF'
# Testing Rules — Node.js / Jest

---

## Test Structure

- Unit tests: `src/[module]/[name].spec.ts` (next to the file)
- Integration tests: `test/` or `src/__tests__/`
- E2E tests: `test/e2e/`

## Coverage

- Services: minimum 80% line coverage
- Repositories: covered by integration tests, not unit tests
- Controllers: covered by E2E or integration tests

## Rules

- Do NOT mock the database in integration tests — use a real test database.
- Do NOT change a test to make it pass — fix the implementation.
- Test names describe behavior: `"should return 404 when user is not found"`
- One assertion per test where possible.
- Use `beforeEach` for setup, `afterEach`/`afterAll` for cleanup.

## Approved Fixtures Policy

- Expected outputs are defined in the spec BEFORE agents write tests.
- Agents may NOT modify a fixture to make a test pass.
- If a fixture is wrong, raise it with the human — do not change it silently.

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ filled for Node.js stack (4 files)"
}

write_skills_node() {
  cat > "$RIG_DIR/feedforward/skills/typescript.skill.md" << 'EOF'
# Skill: TypeScript

> Load when writing any TypeScript code in this project.

---

## Context

This project uses TypeScript throughout. All new code must be typed.
Strict mode is enabled — no implicit `any`.

---

## Patterns to Follow

### Strict typing
- Never use `any`. Use `unknown` when the type is truly unknown, then narrow it.
- Prefer interfaces for object shapes; types for unions and utility types.
- Use `readonly` for properties that should not be mutated.

### Null safety
- Avoid `!` (non-null assertion). Handle `null`/`undefined` explicitly.
- Use optional chaining `?.` and nullish coalescing `??`.

### Generics
- Use generics when a function works with multiple types.
- Name generic params descriptively: `TEntity`, `TResult` over `T`.

---

## Pitfalls to Avoid

- Do NOT use `any` to silence type errors — fix the type.
- Do NOT use `@ts-ignore` without a comment explaining why.
- Do NOT cast with `as` unless you have verified the shape at runtime.

---

## Key Files

- `tsconfig.json` — compiler options
EOF
  print_ok "feedforward/skills/typescript.skill.md created"

  cat > "$RIG_DIR/feedforward/skills/nodejs.skill.md" << 'EOF'
# Skill: Node.js

> Load when working on server-side code, modules, or runtime behavior.

---

## Context

This is a Node.js server application. All async operations use `async/await`.
Error handling follows the layered pattern — errors bubble up to the controller/route handler.

---

## Patterns to Follow

### Async/await
- Always `await` promises. Never leave floating promises.
- Wrap async route handlers to catch unhandled rejections.

### Error handling
- Services throw typed errors (e.g., `UserNotFoundError extends Error`).
- Controllers/route handlers catch and convert to HTTP responses.
- Never swallow errors silently — log or rethrow.

### Environment config
- All config from environment variables, validated at startup.
- Never hardcode secrets, URLs, or credentials.
- Use a config module/object — not `process.env` scattered through the codebase.

---

## Pitfalls to Avoid

- Do NOT use `require()` — use ES module `import`.
- Do NOT use `process.exit()` in library code.
- Do NOT block the event loop with synchronous I/O.

---

## Key Files

- `package.json` — scripts and dependencies
EOF
  print_ok "feedforward/skills/nodejs.skill.md created"
}

# ─────────────────────────────────────────────
# Topology: Python / FastAPI
# ─────────────────────────────────────────────

write_rules_python() {
  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << 'EOF'
# Architecture Rules — Python (Layered)

---

## Layer Hierarchy

```
Routers → Services → Repositories → Database
```

- `routers/` handle HTTP: parse request, call service, return response. No business logic.
- `services/` contain all business logic. No HTTP concerns. No direct DB access.
- `repositories/` handle all database queries. Return domain models, not raw rows.
- `core/` or `shared/` utilities may be imported by any layer.

## Module Boundaries

- A router may ONLY import from its own service.
- A service may ONLY import from repositories and shared/core.
- A repository may NOT import from routers or services.

## Forbidden Patterns

- Direct database session access from a router/endpoint
- HTTP request objects inside a service
- Business logic inside a router function
- Raw SQL inside a service (use the repository)

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << 'EOF'
# Naming Rules — Python

---

## Files and Modules

- All file names: `snake_case.py`
- Routers: `[name]_router.py` or `[name].py` in `routers/`
- Services: `[name]_service.py`
- Repositories: `[name]_repository.py`
- Models: `[name].py` in `models/`
- Schemas (Pydantic): `[name]_schema.py` or `[name].py` in `schemas/`
- Tests: `test_[name].py`

## Classes

- PascalCase: `UserService`, `OrderRepository`, `CreateUserSchema`
- Pydantic models: PascalCase with semantic suffix: `UserResponse`, `CreateUserRequest`

## Functions and Methods

- snake_case: `get_user_by_id`, `create_order`, `validate_email`
- Boolean helpers: `is_`, `has_`, `can_` prefix: `is_active`, `has_permission`

## Variables and Constants

- snake_case for variables: `user_id`, `order_total`
- SCREAMING_SNAKE_CASE for module-level constants: `MAX_RETRY_COUNT`
- Env vars: `SCREAMING_SNAKE_CASE`

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'EOF'
# API Rules — REST / FastAPI

---

## Response Envelope

All endpoints return the same envelope:

```json
{ "data": { ... }, "error": null }
```

On error:
```json
{ "data": null, "error": { "code": "ERROR_CODE", "message": "Human-readable message" } }
```

## HTTP Methods

- `GET    /[resource]`         — list (paginated)
- `GET    /[resource]/{id}`    — single item
- `POST   /[resource]`         — create
- `PUT    /[resource]/{id}`    — full replace
- `PATCH  /[resource]/{id}`    — partial update
- `DELETE /[resource]/{id}`    — delete

## Status Codes

- `200` OK
- `201` Created
- `204` No Content (DELETE)
- `400` Bad Request (validation)
- `401` Unauthorized
- `403` Forbidden
- `404` Not Found
- `422` Unprocessable Entity (FastAPI default for validation errors)
- `500` Internal Server Error

## Input Validation

- Use Pydantic schemas for all request bodies.
- Path and query parameters validated with type annotations.
- Never trust client input — validate before passing to service.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << 'EOF'
# Testing Rules — Python / pytest

---

## Test Structure

- All test files: `test_[module].py`
- Location: `tests/` at project root, mirroring `src/` structure
- Integration tests: `tests/integration/`

## Coverage

- Services: minimum 80% line coverage
- Repositories: covered by integration tests against a real test database
- Routers: covered by integration tests using TestClient

## Rules

- Do NOT mock the database in integration tests — use a real test database.
- Do NOT change a test to make it pass — fix the implementation.
- Test function names describe behavior: `test_returns_404_when_user_not_found`
- Use `pytest.fixture` for reusable setup — not `setUp` class methods.
- Use `parametrize` for data-driven tests.

## Approved Fixtures Policy

- Expected outputs are defined in the spec BEFORE agents write tests.
- Agents may NOT modify a fixture to make a test pass.

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ filled for Python stack (4 files)"
}

write_skills_python() {
  cat > "$RIG_DIR/feedforward/skills/fastapi.skill.md" << 'EOF'
# Skill: FastAPI

> Load when writing FastAPI routers, dependencies, or middleware.

---

## Context

This project uses FastAPI for the HTTP layer. Routes are organized by domain in `routers/`.
Dependency injection is used for services, database sessions, and authentication.

---

## Patterns to Follow

### Router organization
```python
router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, service: UserService = Depends(get_user_service)):
    return await service.get_by_id(user_id)
```

### Dependency injection
- Database sessions injected via `Depends(get_db)`.
- Services injected via `Depends(get_[name]_service)`.
- Authentication via `Depends(get_current_user)`.

### Error handling
- Raise `HTTPException` in routers for HTTP-layer errors.
- Services raise domain exceptions (e.g., `UserNotFoundError`).
- A middleware or exception handler converts domain errors to HTTP responses.

---

## Pitfalls to Avoid

- Do NOT put business logic in router functions.
- Do NOT use global state for the database session.
- Do NOT return raw SQLAlchemy model objects — use Pydantic schemas.

---

## Key Files

- `main.py` — app creation and router registration
- `dependencies.py` — shared FastAPI dependencies
EOF
  print_ok "feedforward/skills/fastapi.skill.md created"

  cat > "$RIG_DIR/feedforward/skills/python.skill.md" << 'EOF'
# Skill: Python

> Load when writing any Python code in this project.

---

## Context

Python 3.11+. All async I/O uses `async/await`. Type hints required on all function signatures.

---

## Patterns to Follow

### Type hints
```python
def get_user(user_id: int) -> UserResponse:
    ...

async def create_order(data: CreateOrderDto) -> Order:
    ...
```

### Error handling
- Define custom exception classes for domain errors.
- Never catch bare `except:` — always catch a specific exception type.
- Log errors before re-raising or converting.

### Async
- All I/O-bound operations are `async`.
- Never call blocking I/O inside an async function — use async libraries.

---

## Pitfalls to Avoid

- Do NOT use mutable default arguments: `def f(items=[])` is a bug.
- Do NOT ignore return values of functions that signal errors.
- Do NOT use `print()` for logging — use the `logging` module.

---

## Key Files

- `pyproject.toml` — project config, dependencies, tool settings
EOF
  print_ok "feedforward/skills/python.skill.md created"
}

# ─────────────────────────────────────────────
# Topology: Next.js / Fullstack
# ─────────────────────────────────────────────

write_rules_nextjs() {
  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << 'EOF'
# Architecture Rules — Next.js (App Router)

---

## Layer Hierarchy

```
Pages/Components → Server Actions / API Routes → Services → Repositories → Database
```

- `app/` — Next.js App Router pages and layouts. No business logic.
- `components/` — React components. Receive data as props or via server components.
- `lib/` or `server/` — Server-side services and repositories. Never imported by client components.
- `api/` routes — thin HTTP handlers that call services.

## Client vs Server

- Server Components fetch data directly. Client Components receive data as props.
- Mark files `"use client"` only when browser APIs or interactivity is needed.
- Never import server-only modules (DB, secrets) in client components.

## Module Boundaries

- `components/` may NOT import from `lib/server/` or repositories.
- `app/` pages are thin — data fetching in Server Components, logic in lib/services.
- `lib/` services are framework-agnostic — no Next.js imports.

## Forbidden Patterns

- Direct database access inside a React component
- `"use client"` on a component that does not need it
- Environment secrets accessed on the client side
- Business logic inside API route handlers

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << 'EOF'
# Naming Rules — Next.js / TypeScript / React

---

## Files

- Pages (App Router): `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- Components: `PascalCase.tsx` — `UserCard.tsx`, `OrderList.tsx`
- Server actions: `[name].actions.ts`
- API routes: `route.ts` (inside `app/api/[resource]/`)
- Services: `[name].service.ts`
- Repositories: `[name].repository.ts`
- Hooks: `use[Name].ts` — `useUser.ts`, `useOrderList.ts`
- Types: `[name].types.ts`
- Tests: `[name].test.tsx` or `[name].spec.tsx`

## Components

- PascalCase: `UserCard`, `OrderSummary`, `NavigationMenu`
- Default export for page-level components; named exports for shared components.

## Functions

- camelCase: `getUserById`, `formatCurrency`
- React event handlers: `handle[Event]`: `handleSubmit`, `handleUserClick`
- Boolean helpers: `is`, `has`, `can` prefix

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/component.rules.md" << 'EOF'
# Component Rules — React / Next.js

---

## Component Types

### Server Components (default in App Router)
- Fetch data directly (database, API).
- Cannot use hooks, browser APIs, or event handlers.
- Pass data down to Client Components as props.

### Client Components (`"use client"`)
- Use only when hooks, state, or browser APIs are needed.
- Keep as small and leaf-level as possible.
- Never fetch directly from a database — receive data as props or via Server Actions.

## Props

- All props explicitly typed with TypeScript interfaces.
- No `any` in prop types.
- Optional props use `?` and have sensible defaults.

## State Management

- Local UI state: `useState`.
- Server state: React Query / SWR, or Server Components with revalidation.
- Avoid global state for data that belongs in the server layer.

## Composition

- Prefer composition over configuration — small focused components over large ones with many props.
- Extract reusable UI into `components/ui/`.
- Domain-specific components live in `components/[domain]/`.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'EOF'
# API Rules — Next.js API Routes

---

## Response Envelope

```typescript
{ data: T | null, error: { code: string; message: string } | null }
```

## Route Handler Pattern

```typescript
// app/api/[resource]/route.ts
export async function GET(request: Request) {
  try {
    const data = await service.list()
    return Response.json({ data, error: null })
  } catch (err) {
    return Response.json({ data: null, error: { code: 'INTERNAL', message: 'Unexpected error' } }, { status: 500 })
  }
}
```

## HTTP Methods

- `GET`    — read (list or single)
- `POST`   — create
- `PUT`    — full replace
- `PATCH`  — partial update
- `DELETE` — delete

## Server Actions vs API Routes

- Prefer Server Actions for form mutations — no extra route needed.
- Use API Routes for: external webhooks, mobile clients, public APIs.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
EOF

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << 'EOF'
# Testing Rules — Next.js / Jest + Testing Library

---

## Test Structure

- Component tests: `[ComponentName].test.tsx` (next to the component)
- Service/util tests: `[name].test.ts`
- Integration tests: `tests/integration/`
- E2E tests: `tests/e2e/` (Playwright)

## Rules

- Test component behavior, not implementation.
- Use `@testing-library/react` — query by role/label, not class names.
- Do NOT test internal state directly.
- Server Components: use integration tests, not unit tests.
- Approved Fixtures define expected outputs — agents may NOT change them.

## Coverage

- Shared components: minimum 70% coverage
- Services: minimum 80% coverage

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ filled for Next.js stack (5 files)"
}

write_skills_nextjs() {
  cat > "$RIG_DIR/feedforward/skills/nextjs.skill.md" << 'EOF'
# Skill: Next.js (App Router)

> Load when working on pages, layouts, routing, or server-side logic.

---

## Context

This project uses Next.js 14+ with the App Router. Server Components are the default.
Data fetching happens server-side; client components handle interactivity only.

---

## Patterns to Follow

### Data fetching in Server Components
```tsx
// app/users/page.tsx
export default async function UsersPage() {
  const users = await userService.list()  // direct service call
  return <UserList users={users} />
}
```

### Server Actions for mutations
```tsx
// app/users/actions.ts
"use server"
export async function createUser(formData: FormData) {
  await userService.create({ name: formData.get("name") as string })
  revalidatePath("/users")
}
```

### Route handlers
```typescript
// app/api/users/route.ts
export async function GET() {
  const users = await userService.list()
  return Response.json({ data: users, error: null })
}
```

---

## Pitfalls to Avoid

- Do NOT add `"use client"` to components that do not need it.
- Do NOT import server modules into client components.
- Do NOT use `useEffect` for initial data fetching — use Server Components.

---

## Key Files

- `app/` — all routes and layouts
- `lib/` — server-side services and utilities
- `components/` — shared UI components
EOF
  print_ok "feedforward/skills/nextjs.skill.md created"

  cat > "$RIG_DIR/feedforward/skills/react.skill.md" << 'EOF'
# Skill: React

> Load when writing React components or hooks.

---

## Context

React 18+. Components are Server Components by default in Next.js App Router.
Add `"use client"` only when hooks or browser APIs are needed.

---

## Patterns to Follow

### Component structure
```tsx
interface UserCardProps {
  user: User
  onSelect?: (id: string) => void
}

export function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div onClick={() => onSelect?.(user.id)}>
      {user.name}
    </div>
  )
}
```

### Custom hooks
```tsx
// hooks/useUser.ts
export function useUser(id: string) {
  return useQuery({ queryKey: ["user", id], queryFn: () => fetchUser(id) })
}
```

---

## Pitfalls to Avoid

- Do NOT mutate state directly — always use `setState` or `useReducer`.
- Do NOT use `index` as a `key` in lists with dynamic items.
- Do NOT derive state in `useEffect` — derive it during render.

---

## Key Files

- `components/` — shared and domain components
EOF
  print_ok "feedforward/skills/react.skill.md created"
}

# ─────────────────────────────────────────────
# Topology Dispatchers
# ─────────────────────────────────────────────

write_topology_rules() {
  # Retrofit always writes generic [DRAFT] stubs — never overwrite existing patterns
  if [ "$RETROFIT" = true ]; then
    write_rules_templates
    return
  fi
  case "$STACK" in
    node|nestjs|express) write_rules_node ;;
    python)              write_rules_python ;;
    nextjs)              write_rules_nextjs ;;
    *)                   write_rules_templates ;;
  esac
}

write_topology_skills() {
  # Retrofit skips skill generation — existing project may already have conventions
  if [ "$RETROFIT" = true ]; then
    write_skill_template
    return
  fi
  case "$STACK" in
    node|nestjs|express) write_skills_node ;;
    python)              write_skills_python ;;
    nextjs)              write_skills_nextjs ;;
    *)                   write_skill_template ;;
  esac
}

# Updates the Available Skills section in HARNESS.md to list actual skill files.
# Called after write_topology_skills so the list reflects what was created.
patch_harness_skills() {
  local harness="$RIG_DIR/HARNESS.md"
  [ ! -f "$harness" ] && return

  local skills_dir="$RIG_DIR/feedforward/skills"
  local skill_files
  skill_files=$(find "$skills_dir" -name "*.skill.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)

  if [ -z "$skill_files" ]; then
    return
  fi

  local skills_list=""
  while IFS= read -r f; do
    local name
    name=$(basename "$f" .skill.md)
    skills_list+="- \`feedforward/skills/$(basename "$f")\` — ${name} patterns"$'\n'
  done <<< "$skill_files"

  # Replace the "None configured yet" line with the actual list
  local tmp
  tmp=$(mktemp)
  awk -v replacement="$skills_list" '
    /^- None configured yet → see `feedforward\/skills\/_TEMPLATE/ {
      printf "%s", replacement
      next
    }
    { print }
  ' "$harness" > "$tmp" && mv "$tmp" "$harness"
}

write_sensor_templates() {
  for sensor in "${SENSORS[@]}"; do
    case "$sensor" in
      eslint)
        cat > "$RIG_DIR/feedback/sensors/lint.sensor.md" << 'EOF'
# Sensor: Lint (ESLint)

**Type:** Computational
**Timing:** After every task

## Command
```bash
npx eslint src/ --max-warnings 0
```

## Pass condition
Exit code 0. Zero warnings, zero errors.

## On failure
Fix all reported issues. Do not suppress rules.
EOF
        ;;
      ruff)
        cat > "$RIG_DIR/feedback/sensors/lint.sensor.md" << 'EOF'
# Sensor: Lint (Ruff)

**Type:** Computational
**Timing:** After every task

## Command
```bash
ruff check .
```

## Pass condition
Exit code 0. Zero violations.

## On failure
Fix all reported issues. Do not add noqa suppressions without justification.
EOF
        ;;
      typescript)
        cat > "$RIG_DIR/feedback/sensors/typecheck.sensor.md" << 'EOF'
# Sensor: Type Check (TypeScript)

**Type:** Computational
**Timing:** After every task

## Command
```bash
npx tsc --noEmit
```

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `any` or `@ts-ignore`.
EOF
        ;;
      mypy)
        cat > "$RIG_DIR/feedback/sensors/typecheck.sensor.md" << 'EOF'
# Sensor: Type Check (mypy)

**Type:** Computational
**Timing:** After every task

## Command
```bash
mypy .
```

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `type: ignore` without justification.
EOF
        ;;
      npm-test)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
# Sensor: Tests (npm test)

**Type:** Computational
**Timing:** After every task

## Command
```bash
npm test
```

## Pass condition
Exit code 0. All tests pass.

## On failure
Fix the implementation. Do not change tests to match a broken implementation.
EOF
        ;;
      pytest)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
# Sensor: Tests (pytest)

**Type:** Computational
**Timing:** After every task

## Command
```bash
pytest
```

## Pass condition
Exit code 0. All tests pass.

## On failure
Fix the implementation. Do not change tests to match a broken implementation.
EOF
        ;;
    esac
  done

  if [ ${#SENSORS[@]} -gt 0 ]; then
    print_ok "Sensor files created: ${SENSORS[*]}"
  fi
}

write_sensor_generic_template() {
  cat > "$RIG_DIR/feedback/sensors/_TEMPLATE.sensor.md" << 'EOF'
# Sensor: [Name]

**Type:** Computational | Inferential
**Timing:** After every task | After integration | Continuous

## Command
```bash
[command to run]
```

## Pass condition
Exit code 0. [Any additional conditions.]

## On failure
[What the agent must do when this sensor fails.]
EOF
}

# Generates AI tool entry point files at the project root.
# All files contain the same minimal instruction: read HARNESS.md first.
# Skips any file that already exists (respects existing config).
write_agent_entrypoints() {
  local project_name
  project_name=$(basename "$(pwd)")
  local created=()
  local skipped=()

  local content="# $project_name — AI Agent Instructions

Read \`.rig/HARNESS.md\` and \`.rig/memory/bootstrap.md\` at the start of every session.
This is required for full project context before taking any action.
"

  # Map: filename → tool name
  declare -A entrypoints
  entrypoints["CLAUDE.md"]="Claude Code"
  entrypoints["AGENTS.md"]="Generic (any agent)"
  entrypoints[".cursorrules"]="Cursor"
  entrypoints[".windsurfrules"]="Windsurf"
  entrypoints["GEMINI.md"]="Gemini"

  for file in "CLAUDE.md" "AGENTS.md" ".cursorrules" ".windsurfrules" "GEMINI.md"; do
    if [ -f "$file" ]; then
      skipped+=("$file")
    else
      printf '%s' "$content" > "$file"
      created+=("$file")
    fi
  done

  # GitHub Copilot needs a directory
  if [ -f ".github/copilot-instructions.md" ]; then
    skipped+=(".github/copilot-instructions.md")
  else
    mkdir -p ".github"
    printf '%s' "$content" > ".github/copilot-instructions.md"
    created+=(".github/copilot-instructions.md")
  fi

  if [ ${#created[@]} -gt 0 ]; then
    print_ok "Agent entry points created: ${created[*]}"
  fi
  if [ ${#skipped[@]} -gt 0 ]; then
    print_warn "Already existed (not overwritten): ${skipped[*]}"
  fi
}

# ─────────────────────────────────────────────
# cmd_init
# ─────────────────────────────────────────────

cmd_init() {
  local retrofit=false
  local template_override=""
  local args=("$@")
  local i=0
  while [ $i -lt ${#args[@]} ]; do
    case "${args[$i]}" in
      --retrofit) retrofit=true; RETROFIT=true ;;
      --template)
        i=$(( i + 1 ))
        template_override="${args[$i]}" ;;
      --template=*) template_override="${args[$i]#--template=}" ;;
    esac
    i=$(( i + 1 ))
  done

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec init${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  # Check existing
  if [ -d "$RIG_DIR" ]; then
    print_warn ".rig/ already exists in this directory."
    echo ""
    read -r -p "  Overwrite it? This replaces all template files. [y/N] " resp
    if [[ ! "$resp" =~ ^[Yy]$ ]]; then
      echo "  Cancelled."; echo ""; exit 0
    fi
    echo ""
  fi

  # Free-text description
  echo -e "  ${DIM}Describe your project in one sentence (Enter to skip):${RESET}"
  read -r -p "  → " PROJECT_DESCRIPTION
  echo ""

  print_step "Detecting project..."
  detect_stack
  refine_stack_from_description
  if [ -n "$template_override" ]; then
    STACK="$template_override"
    case "$STACK" in
      node-api)         STACK="node";   STACK_LABEL="Node.js (node-api template)" ;;
      python-api)       STACK="python"; STACK_LABEL="Python (python-api template)" ;;
      fullstack-nextjs) STACK="nextjs"; STACK_LABEL="Next.js (fullstack-nextjs template)" ;;
      generic)          STACK="unknown"; STACK_LABEL="Generic (language agnostic)" ;;
      *) print_warn "Unknown template '$STACK' — using generic" ; STACK="unknown"; STACK_LABEL="Generic" ;;
    esac
    print_ok "Template override: $STACK_LABEL"
  fi
  detect_sensors
  echo ""

  print_step "Creating .rig/ structure..."
  mkdir -p "$RIG_DIR/feedforward/specs"
  mkdir -p "$RIG_DIR/feedforward/tasks"
  mkdir -p "$RIG_DIR/feedforward/rules"
  mkdir -p "$RIG_DIR/feedforward/skills"
  mkdir -p "$RIG_DIR/feedforward/agents"
  mkdir -p "$RIG_DIR/feedback/sensors"
  mkdir -p "$RIG_DIR/feedback/review"
  mkdir -p "$RIG_DIR/feedback/audit"
  mkdir -p "$RIG_DIR/memory/research"
  mkdir -p "$RIG_DIR/orchestration/contracts"
  mkdir -p "$RIG_DIR/adapters"
  print_ok "Folder structure created"

  print_step "Writing core files..."
  write_harness_md
  write_progress_md
  write_bootstrap_md
  write_decisions_md
  write_spec_template
  write_task_template
  write_contract_template
  write_topology_rules
  write_topology_skills
  patch_harness_skills
  write_sensor_generic_template
  write_sensor_templates

  # Write .rig/.gitignore to keep context assembler outputs out of version control
  cat > "$RIG_DIR/.gitignore" << 'EOF'
# Assembled context files — generated by rig-spec run/shape/plan, not meant for commit
context-*.md
EOF

  print_step "Creating agent entry points..."
  write_agent_entrypoints

  echo ""
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo -e "${GREEN}${BOLD}.rig/ initialized${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Project:${RESET} $(basename "$(pwd)")"
  echo -e "  ${BOLD}Stack:${RESET} $STACK_LABEL"
  if [ "$RETROFIT" = true ]; then
    echo -e "  ${BOLD}Mode:${RESET} retrofit (rules as [DRAFT] — fill in your existing patterns)"
  else
    echo -e "  ${BOLD}Template:${RESET} $( [ "$STACK" = "unknown" ] && echo "generic" || echo "$STACK (rules + skills pre-filled)" )"
  fi
  echo -e "  ${BOLD}Level:${RESET} 1 (Spec Only)"
  if [ ${#SENSORS[@]} -gt 0 ]; then
    echo -e "  ${BOLD}Sensors:${RESET} ${SENSORS[*]}"
  fi
  echo -e "  ${BOLD}Entry points:${RESET} CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules, GEMINI.md, .github/copilot-instructions.md"
  echo ""
  echo "  Next steps:"
  echo ""
  if [ -z "$PROJECT_DESCRIPTION" ]; then
    echo "  1. Edit .rig/HARNESS.md — add your project description"
  else
    echo "  1. Review .rig/HARNESS.md — description already filled"
  fi
  if [ "$RETROFIT" = true ]; then
    echo "  2. Fill in .rig/feedforward/rules/ — capture your existing patterns"
    echo "     Remove [DRAFT] markers when each rule file is complete"
    echo "  3. Create your first spec:"
    echo "     rig-spec shape \"feature name\""
  else
    echo "  2. Create your first spec:"
    echo "     rig-spec shape \"feature name\""
  fi
  echo ""
  echo "  Check status anytime: rig-spec status"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_status
# ─────────────────────────────────────────────

cmd_status() {
  require_rig
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec status${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"

  local progress="$RIG_DIR/memory/progress.md"
  if [ ! -f "$progress" ]; then
    echo ""; print_warn "No progress.md found."; echo ""; return
  fi

  echo ""

  # Active feature from HARNESS.md
  local harness="$RIG_DIR/HARNESS.md"
  if [ -f "$harness" ]; then
    local active_feature
    active_feature=$(grep "^\*\*Active Feature:\*\*" "$harness" | sed 's/\*\*Active Feature:\*\* //')
    local next_task
    next_task=$(grep "^\*\*Next Task:\*\*" "$harness" | sed 's/\*\*Next Task:\*\* //')
    echo -e "  ${BOLD}Active feature:${RESET} $active_feature"
    echo -e "  ${BOLD}Next task:${RESET} $next_task"
    echo ""
  fi

  # Count specs
  local spec_count=0
  if [ -d "$RIG_DIR/feedforward/specs" ]; then
    spec_count=$(find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" | wc -l | tr -d ' ')
  fi

  # Count tasks
  local task_count=0
  local task_done=0
  if [ -d "$RIG_DIR/feedforward/tasks" ]; then
    task_count=$(find "$RIG_DIR/feedforward/tasks" -name "*.task.md" ! -name "_TEMPLATE*" | wc -l | tr -d ' ')
  fi
  if [ -f "$progress" ]; then
    task_done=$(grep -c "^\- \[x\]" "$progress" 2>/dev/null || echo 0)
  fi

  echo -e "  ${BOLD}Specs:${RESET} $spec_count"
  echo -e "  ${BOLD}Tasks:${RESET} $task_count total, $task_done completed"
  echo ""

  # Show Last Session block
  if grep -q "^## Last Session" "$progress"; then
    echo -e "  ${BOLD}Last session:${RESET}"
    awk '/^## Last Session/{p=1; next} p && /^---/{exit} p && NF{print "  " $0}' "$progress"
    echo ""
  fi

  # Show sensors
  local sensor_count=0
  if [ -d "$RIG_DIR/feedback/sensors" ]; then
    sensor_count=$(find "$RIG_DIR/feedback/sensors" -name "*.sensor.md" ! -name "_TEMPLATE*" | wc -l | tr -d ' ')
  fi
  if [ "$sensor_count" -gt 0 ]; then
    echo -e "  ${BOLD}Sensors configured:${RESET} $sensor_count"
  else
    print_dim "No sensors configured (Level 1 — manual validation)"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# cmd_resume
# ─────────────────────────────────────────────

cmd_resume() {
  require_rig
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec resume${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "${DIM}Copy the context below and paste into your AI agent.${RESET}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Print HARNESS.md
  if [ -f "$RIG_DIR/HARNESS.md" ]; then
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""
  fi

  # Print progress.md
  if [ -f "$RIG_DIR/memory/progress.md" ]; then
    cat "$RIG_DIR/memory/progress.md"
    echo ""
    echo "---"
    echo ""
  fi

  # Print active spec if set
  local harness="$RIG_DIR/HARNESS.md"
  if [ -f "$harness" ]; then
    local active
    active=$(grep "^\*\*Active Feature:\*\*" "$harness" | sed 's/\*\*Active Feature:\*\* //' | tr -d ' ')
    if [ -n "$active" ] && [ "$active" != "none" ]; then
      local spec_file="$RIG_DIR/feedforward/specs/${active}.spec.md"
      if [ -f "$spec_file" ]; then
        echo "## Active Spec"
        echo ""
        cat "$spec_file"
        echo ""
        echo "---"
        echo ""
      fi
    fi
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo -e "  ${DIM}Paste the block above into your AI agent.${RESET}"
  echo -e "  ${DIM}It now has full context to continue working.${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_validate
# ─────────────────────────────────────────────

cmd_validate() {
  require_rig
  local task_id="$1"

  echo ""
  if [ -n "$task_id" ]; then
    echo -e "${BOLD}${CYAN}rig-spec validate — $task_id${RESET}"
  else
    echo -e "${BOLD}${CYAN}rig-spec validate${RESET}"
  fi
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  # If task-id given, find and show the task contract before running sensors
  local task_file=""
  if [ -n "$task_id" ]; then
    task_file=$(find "$RIG_DIR/feedforward/tasks" -name "*${task_id}*.md" ! -name "_TEMPLATE*" 2>/dev/null | head -1)
    if [ -n "$task_file" ]; then
      echo -e "  ${BOLD}Contract:${RESET} $(basename "$task_file")"
      echo ""
      # Print contract checklist items from the task file
      if grep -q "^## Contract" "$task_file" 2>/dev/null; then
        awk '/^## Contract/{p=1; next} p && /^---/{exit} p && /^- \[/{print "  " $0}' "$task_file"
        echo ""
        echo -e "  ${DIM}──────────────────────────────────────${RESET}"
        echo ""
      fi
    else
      print_warn "Task not found: $task_id — running all sensors without contract scope"
      echo ""
    fi
  fi

  local sensors_dir="$RIG_DIR/feedback/sensors"
  local sensor_files
  sensor_files=$(find "$sensors_dir" -name "*.sensor.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)

  if [ -z "$sensor_files" ]; then
    print_warn "No sensors configured."
    echo ""
    echo "  Add sensor files to .rig/feedback/sensors/ to enable automated validation."
    echo "  See: .rig/feedback/sensors/_TEMPLATE.sensor.md"
    echo ""
    return 0
  fi

  local passed=0
  local failed=0
  local errors=()

  while IFS= read -r sensor_file; do
    local sensor_name
    sensor_name=$(basename "$sensor_file" .sensor.md)
    local cmd
    cmd=$(extract_command "$sensor_file")

    if [ -z "$cmd" ]; then
      print_warn "$sensor_name — no command found in sensor file"
      continue
    fi

    echo -ne "  Running ${BOLD}$sensor_name${RESET}... "
    if eval "$cmd" > /tmp/rig-sensor-output 2>&1; then
      echo -e "${GREEN}PASS${RESET}"
      ((passed++)) || true
    else
      echo -e "${RED}FAIL${RESET}"
      ((failed++)) || true
      errors+=("$sensor_name")
      echo ""
      echo -e "  ${DIM}Output:${RESET}"
      head -20 /tmp/rig-sensor-output | while IFS= read -r line; do
        echo "    $line"
      done
      echo ""
    fi
  done <<< "$sensor_files"

  echo ""
  if [ "$failed" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}All sensors passed${RESET} ($passed/$((passed+failed)))"
    if [ -n "$task_id" ] && [ -n "$task_file" ]; then
      echo ""
      echo -e "  ${DIM}Sensors passed. Review contract items above and mark them in the task file.${RESET}"
    fi
  else
    echo -e "  ${RED}${BOLD}$failed sensor(s) failed${RESET}: ${errors[*]}"
    echo ""
    if [ -n "$task_id" ]; then
      echo "  Fix the failures above, then re-run: rig-spec validate $task_id"
    else
      echo "  Fix the failures above, then re-run: rig-spec validate"
    fi
  fi
  echo ""

  return $failed
}

# ─────────────────────────────────────────────
# cmd_audit
# ─────────────────────────────────────────────

cmd_audit() {
  require_rig
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec audit${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  local audit_dir="$RIG_DIR/feedback/audit"
  local audit_files
  audit_files=$(find "$audit_dir" -name "*.audit.md" 2>/dev/null | sort)

  if [ -z "$audit_files" ]; then
    print_warn "No audit sensors configured."
    echo ""
    return 0
  fi

  local report_file="$audit_dir/report-$(today).md"
  {
    echo "# Drift Report — $(today)"
    echo ""
    echo "Generated by: rig-spec audit"
    echo ""
    echo "---"
    echo ""
  } > "$report_file"

  local passed=0
  local failed=0

  while IFS= read -r audit_file; do
    local audit_name
    audit_name=$(basename "$audit_file" .audit.md)
    local cmd
    cmd=$(extract_command "$audit_file")

    if [ -z "$cmd" ]; then
      continue
    fi

    echo -ne "  Running ${BOLD}$audit_name${RESET}... "
    if eval "$cmd" > /tmp/rig-audit-output 2>&1; then
      echo -e "${GREEN}CLEAN${RESET}"
      ((passed++)) || true
      {
        echo "## $audit_name"
        echo ""
        echo "Status: CLEAN"
        echo ""
      } >> "$report_file"
    else
      echo -e "${YELLOW}ISSUES FOUND${RESET}"
      ((failed++)) || true
      {
        echo "## $audit_name"
        echo ""
        echo "Status: ISSUES FOUND"
        echo ""
        echo '```'
        cat /tmp/rig-audit-output
        echo '```'
        echo ""
      } >> "$report_file"
    fi
  done <<< "$audit_files"

  echo ""
  echo -e "  Report saved: ${BOLD}$report_file${RESET}"
  if [ "$failed" -gt 0 ]; then
    echo -e "  ${YELLOW}$failed audit(s) found issues${RESET} — review the report"
  else
    echo -e "  ${GREEN}All audits clean${RESET}"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# cmd_run
# ─────────────────────────────────────────────

cmd_run() {
  require_rig
  local task_id="$1"

  if [ -z "$task_id" ]; then
    echo ""
    print_err "Usage: rig-spec run <task-id>"
    echo ""
    echo "  Example: rig-spec run task-01"
    echo ""
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec run — $task_id${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  # Find the task file
  local task_file
  task_file=$(find "$RIG_DIR/feedforward/tasks" -name "*${task_id}*.md" ! -name "_TEMPLATE*" 2>/dev/null | head -1)

  if [ -z "$task_file" ]; then
    print_err "Task not found: $task_id"
    echo ""
    echo "  Available tasks:"
    find "$RIG_DIR/feedforward/tasks" -name "*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | \
      while IFS= read -r f; do echo "    $(basename "$f")"; done
    echo ""
    exit 1
  fi

  print_ok "Task found: $task_file"

  # Find spec reference
  local spec_ref
  spec_ref=$(grep "→ \`feedforward/specs/" "$task_file" 2>/dev/null | head -1 | sed "s/.*\`\(.*\)\`.*/\1/")
  local spec_file=""
  if [ -n "$spec_ref" ]; then
    spec_file="$RIG_DIR/$spec_ref"
    [ ! -f "$spec_file" ] && spec_file=""
  fi

  # Find skills listed in the task
  local skills_content=""
  if grep -q "feedforward/skills/" "$task_file" 2>/dev/null; then
    while IFS= read -r skill_ref; do
      local skill_path="$RIG_DIR/$skill_ref"
      if [ -f "$skill_path" ] && [ "$skill_ref" != "feedforward/skills/_TEMPLATE.skill.md" ]; then
        skills_content+=$(cat "$skill_path")
        skills_content+=$'\n\n---\n\n'
      fi
    done < <(grep -o "feedforward/skills/[^ \`]*" "$task_file")
  fi

  # Assemble context
  local context_file="$RIG_DIR/context-${task_id}.md"
  {
    echo "# Agent Context — $task_id"
    echo ""
    echo "> Assembled by rig-spec run. Read everything below before writing any code."
    echo ""
    echo "---"
    echo ""

    echo "## Project Overview"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""

    echo "## Current State"
    echo ""
    cat "$RIG_DIR/memory/progress.md"
    echo ""
    echo "---"
    echo ""

    if [ -f "$RIG_DIR/memory/decisions.md" ]; then
      echo "## Architectural Decisions"
      echo ""
      cat "$RIG_DIR/memory/decisions.md"
      echo ""
      echo "---"
      echo ""
    fi

    # Rules
    if [ -d "$RIG_DIR/feedforward/rules" ]; then
      local rules_files
      rules_files=$(find "$RIG_DIR/feedforward/rules" -name "*.rules.md" 2>/dev/null | sort)
      if [ -n "$rules_files" ]; then
        echo "## Project Rules"
        echo ""
        while IFS= read -r rules_file; do
          cat "$rules_file"
          echo ""
          echo "---"
          echo ""
        done <<< "$rules_files"
      fi
    fi

    if [ -n "$spec_file" ] && [ -f "$spec_file" ]; then
      echo "## Feature Spec"
      echo ""
      cat "$spec_file"
      echo ""
      echo "---"
      echo ""
    fi

    if [ -n "$skills_content" ]; then
      echo "## Skills"
      echo ""
      echo "$skills_content"
    fi

    echo "## Your Task"
    echo ""
    cat "$task_file"
    echo ""
    echo "---"
    echo ""

    echo "## Instructions"
    echo ""
    echo "You are the **implementer**. Read the task contract above and build exactly what it specifies."
    echo ""
    echo "Rules:"
    echo "- Build only what the contract specifies"
    echo "- Only modify files listed in File Ownership"
    echo "- Check each contract item when complete"
    echo "- Do not self-validate — rig-spec validate will run after"
    echo ""
  } > "$context_file"

  print_ok "Context assembled: $context_file"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Paste the context into your AI agent:"
  echo ""
  echo "     cat $context_file"
  echo ""
  echo "  2. Agent implements the task and signs the contract."
  echo ""
  echo "  3. Once the agent is done, run sensors:"
  echo ""
  echo "     rig-spec validate"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_research
# ─────────────────────────────────────────────

cmd_research() {
  require_rig
  local topic="$*"

  if [ -z "$topic" ]; then
    echo ""
    print_err "Usage: rig-spec research <topic>"
    echo ""
    echo "  Example: rig-spec research \"notification patterns in this codebase\""
    echo ""
    exit 1
  fi

  local slug
  slug=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
  local research_file="$RIG_DIR/memory/research/${slug}.md"

  if [ -f "$research_file" ]; then
    print_warn "Research file already exists: $research_file"
    read -r -p "  Overwrite it? [y/N] " resp
    [[ ! "$resp" =~ ^[Yy]$ ]] && exit 0
  fi

  cat > "$research_file" << EOF
# Research: $topic

> Output of a dedicated research session — $(today).

---

## Topic

$topic

## Key Findings

- [Finding 1]
- [Finding 2]

## Relevant Files Discovered

- \`src/[file]\` — [why it matters]

## Patterns Already in Use

- [Pattern — where it's used]

## Recommended Approach

[The concrete recommendation based on findings.]

## Open Questions

- [ ] [Question] ← owner: [human / architect agent]
EOF

  echo ""
  print_ok "Research file created: $research_file"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Copy the prompt below and paste into your AI agent:"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Research session for: $topic"
  echo ""
  echo "Explore the codebase and investigate: $topic"
  echo ""
  echo "Write your findings in this format:"
  cat "$research_file"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  2. Paste the agent's output into: $research_file"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_shape
# ─────────────────────────────────────────────

cmd_shape() {
  require_rig
  local feature=""
  local from_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_file="$2"; shift 2 ;;
      *)      feature="${feature:+$feature }$1"; shift ;;
    esac
  done

  if [ -z "$feature" ]; then
    echo ""
    print_err "Usage: rig-spec shape <feature-name> [--from <file>]"
    echo ""
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec shape — $feature${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Answer a few questions to shape this spec.${RESET}"
  echo -e "  ${DIM}Press Enter to skip any question.${RESET}"
  echo ""

  # ── Interactive questions ──────────────────
  echo -e "  ${BOLD}1. What problem does this solve?${RESET}"
  echo -e "  ${DIM}(What's broken or missing today?)${RESET}"
  read -r -p "  → " q_problem
  echo ""

  echo -e "  ${BOLD}2. Who are the users?${RESET}"
  echo -e "  ${DIM}(Who will use this feature?)${RESET}"
  read -r -p "  → " q_users
  echo ""

  echo -e "  ${BOLD}3. What is the main goal?${RESET}"
  echo -e "  ${DIM}(What changes for the user when this is done?)${RESET}"
  read -r -p "  → " q_goal
  echo ""

  echo -e "  ${BOLD}4. What is explicitly out of scope?${RESET}"
  echo -e "  ${DIM}(What will NOT be built in this spec?)${RESET}"
  read -r -p "  → " q_out_of_scope
  echo ""

  echo -e "  ${BOLD}5. Any known constraints or design decisions?${RESET}"
  echo -e "  ${DIM}(Architecture choices, limitations, dependencies — optional)${RESET}"
  read -r -p "  → " q_constraints
  echo ""

  # ── Create spec file ──────────────────────
  local slug
  slug=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
  local spec_file="$RIG_DIR/feedforward/specs/${slug}.spec.md"

  # Build out-of-scope list
  local oos_content="- Not included: [add more]"
  if [ -n "$q_out_of_scope" ]; then
    oos_content="- $q_out_of_scope"$'\n'"- [add more if needed]"
  fi

  # Build design notes
  local design_content="[No constraints specified.]"
  if [ -n "$q_constraints" ]; then
    design_content="$q_constraints"
  fi

  cat > "$spec_file" << EOF
# Spec: $feature

---

## Problem

${q_problem:-[What problem does this feature solve? 2-4 sentences.]}

---

## Goal

${q_goal:-[What is the measurable outcome? What changes for the user?]}

---

## Users

${q_users:-[Who will use this feature?]}

---

## Out of Scope

$oos_content

---

## User Stories

- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

---

## Acceptance Criteria

- [ ] [Criterion 1 — must be testable]
- [ ] [Criterion 2 — must be testable]
- [ ] [Criterion 3 — must be testable]

---

## Approved Fixtures

> **HUMAN FILLS THIS SECTION.**
> Define expected outputs before any agent writes tests.
> The implementation must match these exactly.
> Agents may NOT change a fixture to make a test pass.

### Fixture 1: [scenario name]
**Input:** [describe the input]
**Expected output:** [describe the exact expected output]

---

## Design Notes

$design_content
EOF

  print_ok "Spec created: $spec_file"
  echo ""

  # ── Assemble agent context ─────────────────
  local context_file="$RIG_DIR/context-shape-${slug}.md"
  {
    echo "# Complete this spec: $feature"
    echo ""
    echo "> You are helping write a spec for a software feature."
    echo "> The human has already answered the key questions below."
    echo "> Your job is to complete the missing sections following the rig-spec format."
    echo ""
    echo "---"
    echo ""
    echo "## Project Context"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""

    # Include research if available
    if [ -d "$RIG_DIR/memory/research" ]; then
      local research_files
      research_files=$(find "$RIG_DIR/memory/research" -name "*.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)
      if [ -n "$research_files" ]; then
        echo "## Prior Research"
        echo ""
        while IFS= read -r rf; do
          cat "$rf"
          echo ""
          echo "---"
          echo ""
        done <<< "$research_files"
      fi
    fi

    if [ -n "$from_file" ] && [ -f "$from_file" ]; then
      echo "## Input Document (provided by human)"
      echo ""
      cat "$from_file"
      echo ""
      echo "---"
      echo ""
    fi

    echo "## What the Human Already Defined"
    echo ""
    echo "**Feature:** $feature"
    [ -n "$q_problem" ]      && echo "**Problem:** $q_problem"
    [ -n "$q_goal" ]         && echo "**Goal:** $q_goal"
    [ -n "$q_users" ]        && echo "**Users:** $q_users"
    [ -n "$q_out_of_scope" ] && echo "**Out of scope:** $q_out_of_scope"
    [ -n "$q_constraints" ]  && echo "**Constraints:** $q_constraints"
    echo ""
    echo "---"
    echo ""
    echo "## Current Spec (partial — needs completion)"
    echo ""
    cat "$spec_file"
    echo ""
    echo "---"
    echo ""
    echo "## Your Instructions"
    echo ""
    echo "Complete the spec above. Specific rules:"
    echo ""
    echo "**User Stories**"
    echo "- Write 2-4 user stories based on the users and goal described"
    echo "- Format: \"As a [user type], I want [action] so that [benefit]\""
    echo "- Do not invent user types beyond what was described"
    echo ""
    echo "**Acceptance Criteria**"
    echo "- Write 3-6 criteria — each must be specific and testable"
    echo "- Bad: \"The system works correctly\""
    echo "- Good: \"Email is delivered within 5 seconds of the event\""
    echo "- Each criterion must be verifiable by a test or a validator agent"
    echo ""
    echo "**Approved Fixtures**"
    echo "- Leave the Approved Fixtures section EMPTY with a note: '[Human must fill this]'"
    echo "- Do NOT invent expected outputs — that is the human's job"
    echo "- The human defines what 'correct' looks like before any test is written"
    echo ""
    echo "**Out of Scope**"
    echo "- Do not add items to Out of Scope beyond what the human stated"
    echo "- If you think something should be excluded, add it as a question at the end"
    echo ""
    echo "**Format**"
    echo "- Output the complete, filled spec in Markdown"
    echo "- Preserve all section headers exactly as in the template"
    echo "- Save the result to: \`$spec_file\`"
    echo ""
    echo "At the end, list any open questions you have for the human before implementation starts."

  } > "$context_file"

  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Fill in the Approved Fixtures section in the spec:"
  echo "     $spec_file"
  echo ""
  echo "  2. Then paste this context into your AI agent to complete the spec:"
  echo ""
  echo "     cat $context_file"
  echo ""
  echo -e "  ${DIM}The agent will write User Stories and Acceptance Criteria${RESET}"
  echo -e "  ${DIM}based on your answers. Approved Fixtures are yours to define.${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_plan
# ─────────────────────────────────────────────

cmd_plan() {
  require_rig
  local spec_name="$1"

  if [ -z "$spec_name" ]; then
    echo ""
    print_err "Usage: rig-spec plan <spec-name>"
    echo ""
    echo "  Available specs:"
    find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | \
      while IFS= read -r f; do echo "    $(basename "$f" .spec.md)"; done
    echo ""
    exit 1
  fi

  local spec_file="$RIG_DIR/feedforward/specs/${spec_name}.spec.md"
  if [ ! -f "$spec_file" ]; then
    print_err "Spec not found: $spec_file"
    exit 1
  fi

  local tasks_dir="$RIG_DIR/feedforward/tasks/${spec_name}"
  mkdir -p "$tasks_dir"

  local context_file="$RIG_DIR/context-plan-${spec_name}.md"
  {
    echo "# Plan Tasks: $spec_name"
    echo ""
    echo "> Read everything below, then create the task breakdown."
    echo ""
    echo "---"
    echo ""
    echo "## Project Overview"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""
    echo "## Feature Spec"
    echo ""
    cat "$spec_file"
    echo ""
    echo "---"
    echo ""
    echo "## Task Template"
    echo ""
    cat "$RIG_DIR/feedforward/tasks/_TEMPLATE.task.md"
    echo ""
    echo "---"
    echo ""
    echo "## Instructions"
    echo ""
    echo "Break the spec above into ordered, executable tasks."
    echo ""
    echo "Rules:"
    echo "- Each task must have a clear contract (Definition of Done)"
    echo "- Assign file ownership to every task (prevents parallel conflicts)"
    echo "- Identify what can run in parallel vs. sequentially"
    echo "- Each task must reference which spec it comes from"
    echo ""
    echo "Output one file per task to: $tasks_dir/"
    echo "File naming: task-01-[name].task.md, task-02-[name].task.md, ..."
    echo ""
  } > "$context_file"

  echo ""
  print_ok "Tasks folder created: $tasks_dir"
  print_ok "Context assembled: $context_file"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Copy the context and paste into your AI agent:"
  echo ""
  echo "     cat $context_file"
  echo ""
  echo "  2. Save each task file the agent generates to: $tasks_dir/"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_help
# ─────────────────────────────────────────────

cmd_help() {
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec${RESET} v${RIGSPEC_VERSION}"
  echo -e "${DIM}Operational framework for AI-native development${RESET}"
  echo ""
  echo -e "${BOLD}Usage:${RESET}"
  echo "  rig-spec <command> [options]"
  echo ""
  echo -e "${BOLD}Setup:${RESET}"
  echo "  init                       Initialize .rig/ in current project"
  echo "  init --retrofit            Initialize for existing project (rules as [DRAFT])"
  echo "  init --template <name>     Force a specific stack template"
  echo "                             Templates: node-api, python-api, fullstack-nextjs, generic"
  echo ""
  echo -e "${BOLD}Workflow:${RESET}"
  echo "  status               Show current project state"
  echo "  resume               Print full context for the next agent session"
  echo "  run <task-id>        Assemble task context for your AI agent"
  echo "  validate             Run all configured sensors"
  echo "  audit                Run continuous drift sensors"
  echo ""
  echo -e "${BOLD}Spec-driven:${RESET}"
  echo "  research <topic>     Create a research file in memory/research/"
  echo "  shape <feature>      Create a spec from the template"
  echo "  plan <spec-name>     Create task structure from a spec"
  echo ""
  echo -e "${BOLD}Other:${RESET}"
  echo "  version              Show version"
  echo "  help                 Show this help"
  echo ""
  echo -e "${BOLD}Docs:${RESET} $REPO"
  echo ""
}

# ─────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    init)         cmd_init "$@" ;;
    status)       cmd_status ;;
    resume)       cmd_resume ;;
    validate)     cmd_validate "$@" ;;
    audit)        cmd_audit ;;
    run)          cmd_run "$@" ;;
    research)     cmd_research "$@" ;;
    shape)        cmd_shape "$@" ;;
    plan)         cmd_plan "$@" ;;
    version|--version|-v)
                  echo "rig-spec $RIGSPEC_VERSION" ;;
    help|--help|-h)
                  cmd_help ;;
    *)
      echo ""
      print_err "Unknown command: $cmd"
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
