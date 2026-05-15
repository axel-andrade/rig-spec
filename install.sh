#!/usr/bin/env bash
set -e

# rig-spec installer
# Adds the .rig/ harness folder to your current project
# Usage: curl -fsSL https://raw.githubusercontent.com/your-username/rig-spec/main/install.sh | bash

REPO="https://github.com/axel-andrade/rig-spec"
RAW="https://raw.githubusercontent.com/axel-andrade/rig-spec/main"
RIG_DIR=".rig"

# ─────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec installer${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
}

print_step() {
  echo -e "${BOLD}→ $1${RESET}"
}

print_ok() {
  echo -e "  ${GREEN}✓${RESET} $1"
}

print_warn() {
  echo -e "  ${YELLOW}⚠${RESET}  $1"
}

print_error() {
  echo -e "  ${RED}✗${RESET} $1"
}

# ─────────────────────────────────────────────
# Checks
# ─────────────────────────────────────────────

check_dependencies() {
  print_step "Checking dependencies..."
  local missing=0

  if ! command -v git &>/dev/null; then
    print_error "git is required but not found"
    missing=1
  else
    print_ok "git found"
  fi

  if [ "$missing" -eq 1 ]; then
    echo ""
    echo "Please install missing dependencies and try again."
    exit 1
  fi
}

check_existing() {
  if [ -d "$RIG_DIR" ]; then
    echo ""
    print_warn ".rig/ already exists in this directory."
    echo ""
    read -r -p "  Overwrite it? This will replace all template files. [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo ""
      echo "Installation cancelled."
      exit 0
    fi
    echo ""
  fi
}

# ─────────────────────────────────────────────
# Detect project context
# ─────────────────────────────────────────────

detect_stack() {
  print_step "Detecting project stack..."
  STACK="unknown"
  STACK_DETAILS=""

  if [ -f "package.json" ]; then
    STACK="node"
    if grep -q '"next"' package.json 2>/dev/null; then
      STACK="nextjs"
      STACK_DETAILS="Next.js"
    elif grep -q '"nestjs/core"' package.json 2>/dev/null || grep -q '"@nestjs/core"' package.json 2>/dev/null; then
      STACK="nestjs"
      STACK_DETAILS="NestJS"
    elif grep -q '"express"' package.json 2>/dev/null; then
      STACK="express"
      STACK_DETAILS="Express"
    else
      STACK_DETAILS="Node.js"
    fi
    print_ok "Detected: $STACK_DETAILS"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    STACK="python"
    STACK_DETAILS="Python"
    print_ok "Detected: Python"
  elif [ -f "go.mod" ]; then
    STACK="go"
    STACK_DETAILS="Go"
    print_ok "Detected: Go"
  elif [ -f "Cargo.toml" ]; then
    STACK="rust"
    STACK_DETAILS="Rust"
    print_ok "Detected: Rust"
  else
    STACK_DETAILS="Generic (language agnostic)"
    print_warn "No specific stack detected — using generic template"
  fi
}

detect_sensors() {
  print_step "Detecting existing tools..."
  SENSORS=()

  # Linters
  if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
    SENSORS+=("eslint")
    print_ok "ESLint found → lint sensor configured"
  fi

  if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
    SENSORS+=("prettier")
    print_ok "Prettier found → format sensor configured"
  fi

  if [ -f "ruff.toml" ] || grep -q "ruff" pyproject.toml 2>/dev/null; then
    SENSORS+=("ruff")
    print_ok "Ruff found → lint sensor configured"
  fi

  # Type checkers
  if [ -f "tsconfig.json" ]; then
    SENSORS+=("typescript")
    print_ok "TypeScript found → typecheck sensor configured"
  fi

  if [ -f "mypy.ini" ] || grep -q "mypy" pyproject.toml 2>/dev/null; then
    SENSORS+=("mypy")
    print_ok "mypy found → typecheck sensor configured"
  fi

  # Test runners
  if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    SENSORS+=("npm-test")
    print_ok "npm test script found → test sensor configured"
  fi

  if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
    SENSORS+=("pytest")
    print_ok "pytest found → test sensor configured"
  fi

  # Architecture
  if [ -f "package.json" ] && grep -q '"depcruise"' package.json 2>/dev/null; then
    SENSORS+=("depcruise")
    print_ok "dependency-cruiser found → architecture sensor configured"
  fi

  if [ ${#SENSORS[@]} -eq 0 ]; then
    print_warn "No sensors detected — you'll start with manual contract validation (Level 1)"
    print_warn "Add linters or test scripts later to enable automated sensors"
  fi
}

# ─────────────────────────────────────────────
# Create .rig/ structure
# ─────────────────────────────────────────────

create_structure() {
  print_step "Creating .rig/ folder structure..."

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
}

# ─────────────────────────────────────────────
# Write core files
# ─────────────────────────────────────────────

write_harness_md() {
  local project_name
  project_name=$(basename "$(pwd)")

  cat > "$RIG_DIR/HARNESS.md" << EOF
# HARNESS — $project_name

> Read this file first. Every agent, every session, starts here.

---

## Project

**Name:** $project_name
**Stack:** $STACK_DETAILS
**Description:** [Add a one-paragraph description of this project]

---

## Harness Level

**Active Level: 1** (Spec Only)

- Level 1: specs + tasks + contracts + memory ← you are here
- Level 2: + decisions + research + rules + skills + MCP
- Level 3: + sensors + two-agent validation + audit

Run \`rig-spec level 2\` or \`rig-spec level 3\` to upgrade.

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

[Add skills here as you create them]
- None configured yet → see \`feedforward/skills/_TEMPLATE.skill.md\`

## MCP Servers

[Add MCP servers here when configured]
- None configured yet → see \`feedforward/mcp.config.md\`

## Active Sensors

$(for sensor in "${SENSORS[@]}"; do echo "- $sensor"; done)
$([ ${#SENSORS[@]} -eq 0 ] && echo "- None (Level 1 — manual contract validation)")

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
**What happened:** Project initialized.
**What's next:** Create your first spec in `feedforward/specs/`.
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
This tells you: what the project is, current harness level, active feature, available tools.

### 2. Current State
→ Read `.rig/memory/progress.md`
This tells you: what's done, what's in progress, what's next, any blockers.

### 3. Architectural Decisions (when exists)
→ Read `.rig/memory/decisions.md`
This tells you: why things are the way they are. Do not re-debate decided issues.

### 4. Active Feature (when in progress)
→ Read the active spec: `.rig/feedforward/specs/[active-feature].spec.md`
This tells you: what we're building, acceptance criteria, approved fixtures.

### 5. Current Task (when in progress)
→ Read the next pending task in `.rig/feedforward/tasks/[feature]/`
This tells you: exactly what to build, file ownership, contract, skills to load.

### 6. Research Findings (when relevant)
→ Read `.rig/memory/research/[relevant-topic].md`
This tells you: prior investigation results. Do not re-research what's already documented.

---

## After Reading

You are now fully context-aware. Proceed with the current task.

If something is unclear after reading all files, ask — don't assume.
EOF

  print_ok "memory/bootstrap.md created"
}

write_spec_template() {
  cat > "$RIG_DIR/feedforward/specs/_TEMPLATE.spec.md" << 'EOF'
# Spec: [Feature Name]

> Replace this with your feature name.
> This spec is the source of truth for implementation and validation.

---

## Problem

[What problem does this feature solve? Be specific. 2-4 sentences.]

---

## Goal

[What is the measurable outcome? What changes for the user?]

---

## Out of Scope

[What will NOT be built in this spec? Be explicit to prevent scope creep.]

- Not included:
- Not included:

---

## User Stories

- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

---

## Acceptance Criteria

[Specific, verifiable conditions that must be true when this feature is done.]

- [ ] [Criterion 1 — must be testable]
- [ ] [Criterion 2 — must be testable]
- [ ] [Criterion 3 — must be testable]

---

## Approved Fixtures

> Humans define expected outputs here BEFORE agents write any tests.
> The implementation must produce these exact outputs for these inputs.

### Fixture 1: [scenario name]
**Input:** [describe the input]
**Expected output:** [describe the exact expected output]

### Fixture 2: [scenario name]
**Input:** [describe the input]
**Expected output:** [describe the exact expected output]

---

## Design Notes (optional)

[Any architectural decisions, constraints, or context the agent should know.]
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

[List the files to create or modify.]

- Create: `src/[module]/[file].[ext]`
- Modify: `src/[module]/[other-file].[ext]`

---

## File Ownership

> No other task may modify these files while this task is in progress.
> Declare all files this task creates or modifies.

- `src/[module]/[file].[ext]`
- `src/[module]/[other-file].[ext]`

---

## Reuse

[What already exists in the codebase that this task should use or follow?]

- Follow the pattern in `src/[existing-module]/`
- Use the existing `[utility]` from `src/shared/`

---

## Dependencies

[Which tasks must be complete before this one can start?]

- Task [XX] must be complete first (provides [what])

## Enables

[Which tasks are unblocked when this one completes?]

- Task [XX+1] (needs [what this task produces])

---

## Skills to Load

[Which skills does the agent need for this task?]

- `feedforward/skills/[technology].skill.md`

---

## Contract — Definition of Done

> Every item must be verified before this task is marked complete.
> Computational items are checked by sensors. Others by the validator agent.

- [ ] [Deliverable 1] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 2] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 3] ← verified by: [test / typecheck / validator]
- [ ] Approved fixtures from spec pass ← verified by: validator
- [ ] No files outside file ownership were modified ← verified by: validator
EOF

  print_ok "feedforward/tasks/_TEMPLATE.task.md created"
}

write_contract_template() {
  mkdir -p "$RIG_DIR/orchestration/contracts"
  cat > "$RIG_DIR/orchestration/contracts/_TEMPLATE.contract.md" << 'EOF'
# Contract: [spec-name] / task-[XX]

> Agreement between the implementer and validator agents.
> Written during plan. Signed during validate.

---

## Implementer Commits To

> Check each item when complete. The validator will verify each one.

- [ ] [Specific deliverable — must be verifiable]
- [ ] [Specific deliverable — must be verifiable]
- [ ] [Specific deliverable — must be verifiable]

## File Ownership

Files created or modified by this task (no other task may touch these):

- `[file path]`
- `[file path]`

---

## Validator Must Check

> For each item above, how to verify it.

| Item | Verification method |
|---|---|
| [Deliverable 1] | Run: `[command]` — expect exit 0 |
| [Deliverable 2] | Manually verify: [what to check] |
| [Deliverable 3] | Run test: `[test name or file]` |

---

## Sensor Results (filled by validator)

- [ ] lint: PASS / FAIL
- [ ] typecheck: PASS / FAIL
- [ ] tests: PASS / FAIL

## Verdict

- [ ] **PASSED** — all items verified, task complete
- [ ] **FAILED** — see failures below

### Failures (if any)

[List specific failures with file + line references so the implementer can fix exactly what failed]
EOF

  print_ok "orchestration/contracts/_TEMPLATE.contract.md created"
}

write_skill_template() {
  cat > "$RIG_DIR/feedforward/skills/_TEMPLATE.skill.md" << 'EOF'
# Skill: [Technology or Domain Name]

> Load this skill when working on tasks involving [technology/domain].

---

## Context

[What this technology is and how this specific project uses it. 2-4 sentences.]

---

## Patterns to Follow

[What the agent should do when working in this domain.]

### Pattern 1: [Pattern Name]
[Explanation + example from this codebase]
→ Reference: `src/[example-file]`

### Pattern 2: [Pattern Name]
[Explanation + example from this codebase]
→ Reference: `src/[example-file]`

---

## Pitfalls to Avoid

[Common mistakes the agent should NOT make.]

- Do NOT: [specific anti-pattern]
- Do NOT: [specific anti-pattern]

---

## Key Files in This Codebase

[Files the agent should read to understand how this technology is used here.]

- `src/[file]` — [what it shows]
- `src/[file]` — [what it shows]
EOF

  print_ok "feedforward/skills/_TEMPLATE.skill.md created"
}

write_sensor_templates() {
  # Only write sensors for detected tools
  for sensor in "${SENSORS[@]}"; do
    case "$sensor" in
      eslint)
        cat > "$RIG_DIR/feedback/sensors/lint.sensor.md" << 'EOF'
# Sensor: Lint

**Type:** Computational (deterministic)
**Timing:** After every task

## Command
```bash
npx eslint src/ --max-warnings 0
```

## Pass condition
Exit code 0. Zero warnings, zero errors.

## On failure
The agent receives the full ESLint output. Fix all reported issues before retrying.
Do not suppress rules — fix the actual problem.
EOF
        ;;
      typescript)
        cat > "$RIG_DIR/feedback/sensors/typecheck.sensor.md" << 'EOF'
# Sensor: Type Check

**Type:** Computational (deterministic)
**Timing:** After every task

## Command
```bash
npx tsc --noEmit
```

## Pass condition
Exit code 0. Zero type errors.

## On failure
The agent receives the full TypeScript error output with file and line references.
Fix all type errors. Do not use `any` or `@ts-ignore` to suppress them.
EOF
        ;;
      npm-test)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
# Sensor: Tests

**Type:** Computational (deterministic)
**Timing:** After every task

## Command
```bash
npm test
```

## Pass condition
Exit code 0. All tests pass.

## On failure
The agent receives the test runner output with failed test names and assertions.
Fix the implementation to match the approved fixtures — do not change the tests
to match a broken implementation.
EOF
        ;;
      pytest)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
# Sensor: Tests

**Type:** Computational (deterministic)
**Timing:** After every task

## Command
```bash
pytest
```

## Pass condition
Exit code 0. All tests pass.

## On failure
The agent receives the pytest output with failed test names and assertion details.
Fix the implementation — do not change tests to match a broken implementation.
EOF
        ;;
    esac
  done

  if [ ${#SENSORS[@]} -gt 0 ]; then
    print_ok "Sensor files created for: ${SENSORS[*]}"
  fi
}

write_rules_templates() {
  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << 'EOF'
# Architecture Rules

> Loaded into every agent context before task execution.
> Defines module boundaries and layering constraints.
> DRAFT — fill in the rules for this project.

---

## Module Boundaries

[Define which modules can import from which. Example:]
- `[module-a]` may NOT import from `[module-b]`
- `[shared]` may be imported by any module
- Domain layer may NOT import from infrastructure layer

## Layering Rules

[Define the allowed dependency direction. Example:]
- Controllers → Services → Repositories → Database
- A layer may only depend on the layer directly below it

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (when configured)
EOF

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << 'EOF'
# Naming Rules

> Loaded into every agent context before task execution.
> Defines naming conventions for files, classes, functions, and variables.
> DRAFT — fill in the conventions for this project.

---

## Files

- [file type]: `[pattern]` — e.g., services: `*.service.ts`
- [file type]: `[pattern]` — e.g., controllers: `*.controller.ts`

## Classes / Components

- [type]: `[pattern]` — e.g., services: `PascalCase` + `Service` suffix

## Functions / Methods

- [type]: `[pattern]` — e.g., handlers: `camelCase`, verb prefix

## Variables

- [type]: `[pattern]` — e.g., constants: `UPPER_SNAKE_CASE`

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (when configured)
EOF

  cat > "$RIG_DIR/feedforward/rules/structure.rules.md" << 'EOF'
# Structure Rules

> Loaded into every agent context before task execution.
> Defines where each file type must live in the folder structure.
> DRAFT — fill in the structure for this project.

---

## Folder Layout

```
[describe your project's folder structure here]
src/
├── [module]/
│   ├── [what goes here]
│   └── [what goes here]
└── shared/
    └── [what goes here]
```

## Rules

- [file type] must live in: `[path pattern]`
- [file type] must live in: `[path pattern]`
- Tests must live next to the file they test / in a `__tests__` folder [choose one]

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (when configured)
EOF

  cat > "$RIG_DIR/feedforward/rules/component.rules.md" << 'EOF'
# Component Rules

> Frontend only. Remove this file if this is a backend-only project.
> Loaded into every agent context before task execution.
> Defines component structure, responsibilities, and patterns.
> DRAFT — fill in the rules for this project.

---

## Component Responsibilities

- Presentational components: only rendering, no business logic
- Container components: data fetching and state, no layout
- [Define your component split pattern here]

## Structure per Component

```
[ComponentName]/
├── index.ts         ← exports
├── [ComponentName].tsx
├── [ComponentName].test.tsx
└── [ComponentName].module.css  ← if using CSS modules
```

## Rules

- Do NOT put API calls directly in components — use [hooks / services / state layer]
- Do NOT use `any` type for props — define explicit prop interfaces
- [Add your project-specific rules]

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (inferential review)
EOF

  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'EOF'
# API Rules

> Loaded into every agent context before task execution.
> Defines API design conventions, response formats, and error handling.
> DRAFT — fill in the conventions for this project.

---

## Response Envelope

[Define your standard response format. Example:]
```json
{
  "data": {},
  "error": null
}
```

## Error Format

[Define your standard error response. Example:]
```json
{
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

## Endpoint Conventions

- [Method + path pattern for resource listing]
- [Method + path pattern for single resource]
- [Method + path pattern for creation]
- [Method + path pattern for update]
- [Method + path pattern for deletion]

## Rules

- [Specific rule — e.g., always return 400 for validation errors, never 500]
- [Specific rule — e.g., IDs are UUIDs, never sequential integers in public APIs]

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (inferential review)
EOF

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << 'EOF'
# Testing Rules

> Loaded into every agent context before task execution.
> Defines test requirements, structure, and approved fixture policy.
> DRAFT — fill in the rules for this project.

---

## Coverage Requirements

- [Layer or module]: minimum [X]% coverage
- Critical paths (payments, auth, etc.): [X]% minimum

## Test Structure

- Unit tests: `[pattern]` — e.g., `*.spec.ts` next to source file
- Integration tests: `[pattern]` — e.g., `tests/integration/`
- E2E tests: `[pattern]` — e.g., `tests/e2e/`

## Approved Fixtures Policy

> Humans define expected outputs in the spec BEFORE agents write tests.
> Agents must write tests that validate those exact outputs.
> Agents may NOT change an approved fixture to make a failing test pass.

## Rules

- Do NOT mock the database in integration tests
- Do NOT use `any` in test assertions
- Test names must describe behavior, not implementation
- [Add your project-specific rules]

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (when configured)
EOF

  print_ok "feedforward/rules/ templates created (6 files)"
}

write_decisions_md() {
  cat > "$RIG_DIR/memory/decisions.md" << 'EOF'
# Decisions

> Architectural decisions made during this project.
> Read before making any significant technical choice — do not re-debate decided issues.

---

_No decisions recorded yet._

---

## Template

```markdown
## [YYYY-MM-DD] — [Decision Title]

**Decided:** [What was chosen]
**Alternatives considered:** [What else was evaluated]
**Rationale:** [Why this option was chosen]
**Impact:** [What this means going forward]
```
EOF

  print_ok "memory/decisions.md created"
}

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

print_summary() {
  echo ""
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo -e "${GREEN}${BOLD}rig-spec installed successfully${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Harness level:${RESET} 1 (Spec Only)"
  echo -e "  ${BOLD}Stack detected:${RESET} $STACK_DETAILS"
  if [ ${#SENSORS[@]} -gt 0 ]; then
    echo -e "  ${BOLD}Sensors configured:${RESET} ${SENSORS[*]}"
  else
    echo -e "  ${BOLD}Sensors:${RESET} none detected (manual validation)"
  fi
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Edit .rig/HARNESS.md — add your project description"
  echo "  2. Create your first spec:"
  echo "     cp .rig/feedforward/specs/_TEMPLATE.spec.md \\"
  echo "        .rig/feedforward/specs/my-feature.spec.md"
  echo "  3. Ask your AI agent to break it into tasks:"
  echo "     'Read .rig/HARNESS.md and .rig/feedforward/specs/my-feature.spec.md."
  echo "      Break this into tasks following .rig/feedforward/tasks/_TEMPLATE.task.md'"
  echo ""
  echo -e "  ${BOLD}Documentation:${RESET} https://github.com/axel-andrade/rig-spec"
  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
  print_header
  check_dependencies
  check_existing
  detect_stack
  detect_sensors
  echo ""
  create_structure
  write_harness_md
  write_progress_md
  write_bootstrap_md
  write_spec_template
  write_task_template
  write_contract_template
  write_skill_template
  write_rules_templates
  write_sensor_templates
  write_decisions_md
  print_summary
}

main
