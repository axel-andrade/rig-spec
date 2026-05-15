#!/usr/bin/env bash
# rig-spec — operational framework for AI-native development
# https://github.com/axel-andrade/rig-spec
set -e

RIGSPEC_VERSION="0.1.0"
RIG_DIR=".rig"
REPO="https://github.com/axel-andrade/rig-spec"

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
**Description:** [Add a one-paragraph description of this project]

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

# ─────────────────────────────────────────────
# cmd_init
# ─────────────────────────────────────────────

cmd_init() {
  local retrofit=false
  for arg in "$@"; do
    [ "$arg" = "--retrofit" ] && retrofit=true
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

  print_step "Detecting project..."
  detect_stack
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
  write_skill_template
  write_rules_templates
  write_sensor_generic_template
  write_sensor_templates

  echo ""
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo -e "${GREEN}${BOLD}.rig/ initialized${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Project:${RESET} $(basename "$(pwd)")"
  echo -e "  ${BOLD}Stack:${RESET} $STACK_LABEL"
  echo -e "  ${BOLD}Level:${RESET} 1 (Spec Only)"
  if [ ${#SENSORS[@]} -gt 0 ]; then
    echo -e "  ${BOLD}Sensors:${RESET} ${SENSORS[*]}"
  fi
  echo ""
  echo "  Next steps:"
  echo ""
  echo "  1. Edit .rig/HARNESS.md — add your project description"
  echo "  2. Create your first spec:"
  echo "     cp .rig/feedforward/specs/_TEMPLATE.spec.md \\"
  echo "        .rig/feedforward/specs/my-feature.spec.md"
  echo "  3. Check status anytime: rig-spec status"
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
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec validate${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

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
  else
    echo -e "  ${RED}${BOLD}$failed sensor(s) failed${RESET}: ${errors[*]}"
    echo ""
    echo "  Fix the failures above, then re-run: rig-spec validate"
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
  echo "  1. Open $context_file"
  echo "  2. Copy the full content"
  echo "  3. Paste into your AI agent (Claude, Gemini, GPT, etc.)"
  echo "  4. After the agent completes the task, run:"
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
  local feature="$1"
  local from_file=""

  # Parse --from flag
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_file="$2"; shift 2 ;;
      *)      feature="$*"; break ;;
    esac
  done

  if [ -z "$feature" ]; then
    echo ""
    print_err "Usage: rig-spec shape <feature-name> [--from <file>]"
    echo ""
    exit 1
  fi

  local slug
  slug=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
  local spec_file="$RIG_DIR/feedforward/specs/${slug}.spec.md"

  cp "$RIG_DIR/feedforward/specs/_TEMPLATE.spec.md" "$spec_file"
  # Replace template title with feature name
  if command -v sed &>/dev/null; then
    sed -i "s/\[Feature Name\]/$feature/g" "$spec_file"
  fi

  echo ""
  print_ok "Spec file created: $spec_file"
  echo ""

  # Assemble context for the AI agent
  local context_file="$RIG_DIR/context-shape-${slug}.md"
  {
    echo "# Shape Spec: $feature"
    echo ""
    echo "> Read everything below, then write a complete spec for: $feature"
    echo ""
    echo "---"
    echo ""
    echo "## Project Overview"
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
      echo "## Input Document"
      echo ""
      cat "$from_file"
      echo ""
      echo "---"
      echo ""
    fi

    echo "## Spec Template"
    echo ""
    cat "$RIG_DIR/feedforward/specs/_TEMPLATE.spec.md"
    echo ""
    echo "---"
    echo ""
    echo "## Instructions"
    echo ""
    echo "Write a complete spec for: **$feature**"
    echo ""
    echo "Fill in every section of the template above."
    echo "Be specific in Acceptance Criteria — each must be testable."
    echo "Define Approved Fixtures BEFORE any agent writes tests."
    echo ""
    echo "Output the filled spec to: $spec_file"

  } > "$context_file"

  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Copy the context below and paste into your AI agent:"
  echo ""
  echo "     cat $context_file"
  echo ""
  echo "  2. Paste the agent's spec output into: $spec_file"
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
  echo "  init                 Initialize .rig/ in current project"
  echo "  init --retrofit      Initialize for existing project (rules as [DRAFT])"
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
