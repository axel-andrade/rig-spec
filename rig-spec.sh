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

# Prefix for new task files — sorts chronologically in directory listings
task_ts_prefix() { date +%Y%m%d-%H%M%S; }

# Active feature slug from HARNESS.md (narrows ambiguous task lookup)
harness_active_feature() {
  local harness="$RIG_DIR/HARNESS.md"
  [ ! -f "$harness" ] && return
  grep -m1 '^\*\*Active Feature:\*\*' "$harness" 2>/dev/null \
    | sed 's/^\*\*Active Feature:\*\*[[:space:]]*//' \
    | sed 's/[[:space:]].*$//' \
    | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

# List matching task paths (one per line). Optional feature scope limits the folder.
_find_task_candidates() {
  local fragment="$1"
  local feature_scope="${2:-}"
  local search_root="$RIG_DIR/feedforward/tasks"

  if [ -n "$feature_scope" ]; then
    search_root="$RIG_DIR/feedforward/tasks/$feature_scope"
    [ ! -d "$search_root" ] && return
  fi

  find "$search_root" -name "*${fragment}*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | sort
}

# Print ambiguity help to stderr
_print_task_ambiguity() {
  local fragment="$1"
  shift
  local matches=("$@")
  print_err "Ambiguous task id: $fragment (${#matches[@]} matches)"
  echo ""
  echo "  Use a qualified id (feature folder + fragment):"
  echo ""
  local m feature_dir base
  for m in "${matches[@]}"; do
    feature_dir=$(basename "$(dirname "$m")")
    base=$(basename "$m" .task.md)
    echo "    rig-spec run ${feature_dir}/${fragment}"
    echo "      → $(basename "$m")"
  done
  echo ""
  local active
  active=$(harness_active_feature)
  if [ -n "$active" ] && [ "$active" != "none" ]; then
    echo "  Or set focus in HARNESS.md (**Active Feature:**) and use a more specific fragment."
    echo "  Current active feature: $active"
  fi
  echo ""
}

# Find task file by id fragment or qualified id (feature/01-slug).
# Exits with message if zero or multiple matches (unless narrowed by active feature).
find_task_file() {
  local task_id="$1"
  local feature_scope=""
  local fragment="$task_id"

  # Qualified: spec-name/01-data-layer or spec-name:01-data-layer
  if [[ "$task_id" == */* ]]; then
    feature_scope="${task_id%%/*}"
    fragment="${task_id#*/}"
  elif [[ "$task_id" == *:* ]]; then
    feature_scope="${task_id%%:*}"
    fragment="${task_id#*:}"
  fi

  fragment="${fragment%.task.md}"

  local matches_raw
  matches_raw=$(_find_task_candidates "$fragment" "$feature_scope")

  if [ -z "$matches_raw" ]; then
    return 1
  fi

  local -a matches=()
  while IFS= read -r line; do
    [ -n "$line" ] && matches+=("$line")
  done <<< "$matches_raw"

  if [ "${#matches[@]}" -eq 1 ]; then
    echo "${matches[0]}"
    return 0
  fi

  # Multiple matches — narrow by HARNESS active feature if no scope was given
  if [ -z "$feature_scope" ]; then
    local active narrowed_raw
    active=$(harness_active_feature)
    if [ -n "$active" ] && [ "$active" != "none" ]; then
      narrowed_raw=$(_find_task_candidates "$fragment" "$active")
      if [ -n "$narrowed_raw" ]; then
        local -a narrowed=()
        while IFS= read -r line; do
          [ -n "$line" ] && narrowed+=("$line")
        done <<< "$narrowed_raw"
        if [ "${#narrowed[@]}" -eq 1 ]; then
          echo "${narrowed[0]}"
          return 0
        fi
        if [ "${#narrowed[@]}" -gt 1 ]; then
          _print_task_ambiguity "$fragment" "${narrowed[@]}"
          return 2
        fi
      fi
    fi
  fi

  _print_task_ambiguity "$fragment" "${matches[@]}"
  return 2
}

# Safe wrapper: returns path or empty; prints ambiguity to stderr
find_task_file_or_fail() {
  local task_id="$1"
  local result rc=0
  result=$(find_task_file "$task_id") || rc=$?
  if [ "$rc" -eq 2 ]; then
    exit 1
  fi
  if [ "$rc" -ne 0 ] || [ -z "$result" ]; then
    return 1
  fi
  echo "$result"
  return 0
}

# Injected at the top of every rig-spec context file for chat-based agents
session_continuity_block() {
  cat << 'SESSION_EOF'
## Session continuity (mandatory — read first)

Chat sessions have a **limited context window**. Hallucination usually means the window is full or polluted — not that the model "forgot".

**Persist state on disk before improvising:**
- After each contract sub-item done → update `memory/progress.md` (`[~]` task + checked sub-items) and the task file.
- Gotchas / patterns → append `memory/learnings.md`.

**Start a NEW chat (hand off) when ANY is true:**
- You are unsure what was already implemented in this conversation
- The user says the chat is long, slow, repetitive, or drifting
- You finished one logical chunk (one contract item, one file, one endpoint) and more work remains
- You would need to re-read many files to continue safely

**Handoff (end this chat → fresh agent):**
1. Follow `.rig/memory/session-handoff.md` and write a `[CHECKPOINT]` in `memory/progress.md`
2. Last line of your message must be exactly: `HANDOFF SAVED — close this chat and run: rig-spec resume`
3. Human opens a **new** chat and pastes only `rig-spec resume` output — not this entire context again

Human can trigger early: `rig-spec handoff` (assembles a save-state prompt).

**Forbidden:** continuing a large task in a degraded chat without saving progress.
SESSION_EOF
}

progress_has_checkpoint() {
  local progress="$RIG_DIR/memory/progress.md"
  [ -f "$progress" ] && grep -q '\[CHECKPOINT\]' "$progress" 2>/dev/null
}

shape_slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

shape_qa_path() { echo "$RIG_DIR/memory/shape-qa/$(shape_slugify "$1").md"; }
plan_qa_path()  { echo "$RIG_DIR/memory/plan-qa/$(shape_slugify "$1").md"; }

# Find a spec file by slug, handling optional timestamp prefix (YYYYMMDD-HHMMSS-slug).
# Prints the path if found; returns 1 if not found.
find_spec_file() {
  local slug="$1"
  local specs_dir="$RIG_DIR/feedforward/specs"

  # Exact match first (legacy or no-timestamp)
  if [ -f "$specs_dir/${slug}.spec.md" ]; then
    echo "$specs_dir/${slug}.spec.md"
    return 0
  fi

  # Glob: timestamp-prefixed files ending in -slug.spec.md
  local match
  match=$(find "$specs_dir" -name "*-${slug}.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | sort | tail -1)
  if [ -n "$match" ]; then
    echo "$match"
    return 0
  fi

  # Broader partial match: any spec containing slug in name
  match=$(find "$specs_dir" -name "*${slug}*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | sort | tail -1)
  if [ -n "$match" ]; then
    echo "$match"
    return 0
  fi

  return 1
}

# Extracts the command from a sensor/audit markdown file.
# Priority 1: YAML frontmatter `command:` key (unambiguous, no parser fragility).
# Priority 2: first ```bash block inside the ## Command section (legacy fallback).
extract_command() {
  local file="$1"

  # YAML frontmatter — check for `command:` between the opening and closing `---`
  if head -1 "$file" | grep -q '^---$'; then
    local fm_cmd
    fm_cmd=$(awk '
      NR==1 && /^---$/ { in_fm=1; next }
      in_fm && /^---$/ { exit }
      in_fm && /^command:/ { sub(/^command:[[:space:]]*/,""); print; exit }
    ' "$file")
    if [ -n "$fm_cmd" ]; then
      echo "$fm_cmd"
      return
    fi
  fi

  # Fallback: first ```bash block scoped to the ## Command section
  # (stops at the next heading so example blocks in other sections are ignored)
  awk '
    /^## Command/ { found=1; next }
    found && /^##+/ { exit }
    found && /^```bash/ { in_block=1; next }
    in_block && /^```/ { exit }
    in_block { print }
  ' "$file"
}

# Returns inferential if sensor command contains INFERENTIAL or echo only placeholder
sensor_is_inferential() {
  local cmd="$1"
  echo "$cmd" | grep -qE 'INFERENTIAL|echo "INFERENTIAL'
}

# Resolve skill paths for a task: registry keywords + explicit task skills (deduped)
resolve_skills_for_task() {
  local task_file="$1"
  local registry="$RIG_DIR/feedforward/skills.registry.md"
  local combined_text=""
  local -a resolved=()

  [ -f "$task_file" ] || return 0
  combined_text=$(tr '[:upper:]' '[:lower:]' < "$task_file")

  if [ -f "$registry" ] && ! echo "$combined_text" | grep -qE 'skills:[[:space:]]*manual'; then
    while IFS='|' read -r _ col2 col3 _rest; do
      col2=$(echo "$col2" | sed 's/^ *//;s/ *$//;s/`//g')
      col3=$(echo "$col3" | sed 's/^ *//;s/ *$//' | tr '[:upper:]' '[:lower:]')
      [ -z "$col2" ] && continue
      echo "$col2" | grep -qiE 'skill path|external skill|domain' && continue
      echo "$col2" | grep -q '^---' && continue

      local hit=false
      local kw
      IFS=',' read -ra KWS <<< "$col3"
      for kw in "${KWS[@]}"; do
        kw=$(echo "$kw" | xargs)
        [ -z "$kw" ] && continue
        if echo "$combined_text" | grep -qF "$kw"; then
          hit=true
          break
        fi
      done

      if $hit; then
        local fp=""
        if [[ "$col2" == feedforward/* ]]; then
          fp="$RIG_DIR/$col2"
        elif [[ "$col2" == "~/"* ]]; then
          fp="${col2/#\~/$HOME}"
        elif [[ "$col2" == /* ]]; then
          fp="$col2"
        fi
        if [ -f "$fp" ]; then
          resolved+=("$col2")
        fi
      fi
    done < <(grep '^| ' "$registry" 2>/dev/null || true)
  fi

  while IFS= read -r skill_ref; do
    [ "$skill_ref" = "feedforward/skills/_TEMPLATE.skill.md" ] && continue
    [ -f "$RIG_DIR/$skill_ref" ] && resolved+=("$skill_ref")
  done < <(grep -oE 'feedforward/skills/[^ `]+' "$task_file" 2>/dev/null || true)

  if [ ${#resolved[@]} -eq 0 ]; then
    return 0
  fi
  printf '%s\n' "${resolved[@]}" | awk '!seen[$0]++'
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

# Scans an existing project's src/ structure to inform retrofit rule generation.
# Sets RETROFIT_SRC_TREE, RETROFIT_HAS_TS, RETROFIT_TEST_PATTERN, RETROFIT_MODULES.
scan_retrofit_structure() {
  RETROFIT_SRC_TREE=""
  RETROFIT_HAS_TS=false
  RETROFIT_TEST_PATTERN="unknown"
  RETROFIT_MODULES=()

  # Directories to always exclude — covers Node, Python, Go, Rust, Ruby, PHP, Java, etc.
  local PRUNE_DIRS=(
    node_modules    # Node.js
    .venv venv env  # Python virtualenvs
    __pycache__     # Python bytecode
    target          # Rust / Java / Maven
    vendor          # Go / PHP / Ruby
    build dist out  # generic build outputs
    .gradle         # Gradle (Android / JVM)
    .rig            # rig-spec itself
    ".git"          # git internals
  )

  # Build the -path exclusion flags for find
  build_prune_args() {
    local args=()
    for d in "${PRUNE_DIRS[@]}"; do
      args+=("!" "-path" "*/${d}/*")
    done
    echo "${args[@]}"
  }

  local prune_args
  read -ra prune_args <<< "$(build_prune_args)"

  # Detect TypeScript presence
  if find . -name "*.ts" ! -name "*.d.ts" "${prune_args[@]}" 2>/dev/null | grep -q .; then
    RETROFIT_HAS_TS=true
    print_ok "TypeScript detected"
  fi

  # Build a grep pattern for pruned dirs (for pipe-based filtering)
  local prune_grep
  prune_grep=$(IFS='|'; echo "${PRUNE_DIRS[*]}" | sed 's/ /|/g')

  # Detect test location pattern
  if find . \( -name "*.test.*" -o -name "*.spec.*" \) "${prune_args[@]}" 2>/dev/null | \
       grep -qE "src/"; then
    RETROFIT_TEST_PATTERN="co-located"
  elif find . \( -name "*.test.*" -o -name "*.spec.*" \) "${prune_args[@]}" 2>/dev/null | \
       grep -qE "/test/|/__tests__/|/tests/|/spec/"; then
    RETROFIT_TEST_PATTERN="separate-folder"
  fi
  if [ "$RETROFIT_TEST_PATTERN" != "unknown" ]; then
    print_ok "Test pattern detected: $RETROFIT_TEST_PATTERN"
  fi

  # Scan source tree (max 2 levels deep)
  local src_dir=""
  for candidate in src app lib internal pkg cmd; do
    if [ -d "$candidate" ]; then
      src_dir="$candidate"
      break
    fi
  done

  if [ -n "$src_dir" ]; then
    # Build a readable tree (2 levels)
    RETROFIT_SRC_TREE=$(find "$src_dir" -maxdepth 2 -type d \
      "${prune_args[@]}" 2>/dev/null | sort | \
      while IFS= read -r dir; do
        local depth
        depth=$(echo "$dir" | tr -cd '/' | wc -c)
        local indent=""
        for ((i=0; i<depth; i++)); do indent+="  "; done
        echo "${indent}$(basename "$dir")/"
      done)

    # Detect module names (first-level subdirs of src/)
    while IFS= read -r moddir; do
      local modname
      modname=$(basename "$moddir")
      RETROFIT_MODULES+=("$modname")
    done < <(find "$src_dir" -maxdepth 1 -mindepth 1 -type d \
      "${prune_args[@]}" 2>/dev/null | sort)

    if [ -n "$RETROFIT_SRC_TREE" ]; then
      print_ok "Source structure scanned: $src_dir/ (${#RETROFIT_MODULES[@]} modules detected)"
    fi
  else
    print_warn "No src/app/lib directory found — structure rules will be generic"
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

## Vision

${PROJECT_DESCRIPTION:-[Describe the product vision in 2-4 sentences: what it is, who it serves, what core problem it solves. This is the north star — every feature must serve this vision.]}

---

## Business Rules

> Core domain rules the agent must know before implementing anything.
> These are non-negotiable constraints — not implementation details.

- [Rule 1 — e.g., "A patient record may only be accessed by its assigned practitioner"]
- [Rule 2 — e.g., "Medication doses must be validated against patient weight before saving"]
- [Add rules specific to your domain]

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

## Project Standards

→ **Start here:** \`STANDARDS.md\` — index of all \`feedforward/rules/\` and enforcement sensors.

→ **Skill routing:** \`feedforward/skills.registry.md\` — auto-loads skills on \`rig-spec run\`.

## Key Files

| File | Purpose |
|---|---|
| \`STANDARDS.md\` | Index: architecture, naming, UI tokens, API rules |
| \`feedforward/specs/\` | Feature specifications |
| \`feedforward/tasks/\` | Task breakdowns per spec |
| \`feedforward/rules/\` | Coding conventions and architecture rules |
| \`feedforward/skills.registry.md\` | Auto skill routing by task keywords |
| \`feedforward/skills/\` | Specialized local knowledge |
| \`feedback/sensors/\` | Automated validation commands |
| \`feedback/reports/\` | Validation artifacts (\`rig-spec validate\`) |
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

> Updated after EVERY contract item — not only after validate/done.
> This file is the source of truth for project state.
> An agent reading this file knows exactly where to resume.

---

## Active Features

_No features in progress yet._

---

## Completed Features

_None yet._

---

## Pending Handoff

_When an agent hands off mid-task, a `[CHECKPOINT]` block appears under the active feature (see `memory/session-handoff.md`). The next session reads it via `rig-spec resume`._

---

## Last Session

**Date:** —
**What happened:** Project initialized with rig-spec.
**What's next:** Create your first spec in `feedforward/specs/`.
**Blockers:** None.
EOF
  print_ok "memory/progress.md created"
}

write_session_handoff_md() {
  cat > "$RIG_DIR/memory/session-handoff.md" << 'EOF'
# Session Handoff — Save Progress & Start a New Agent

> Use when a chat session is getting long or the agent starts guessing.
> Goal: **zero lost work** — the next agent reads files, not chat history.

---

## When to hand off

Hand off (do not keep coding in the same chat) if:

- Context feels full, answers get vague, or the agent repeats mistakes
- One contract sub-item or file is done and more work remains on the same task
- The human runs `rig-spec handoff` or asks to "save progress and new session"

---

## What the agent must write before ending

### 1. `[CHECKPOINT]` inside `memory/progress.md`

Under the active feature section, add or replace:

```markdown
[CHECKPOINT] YYYY-MM-DD — task-id-or-name

**Stopped after:** [what was completed — files, contract items]
**Next action:** [single concrete next step — file + change]
**Do not redo:** [what is already done and must not be rebuilt]
**Open questions:** [decisions needed from human, or none]
**Files touched:** [paths]
```

Also update `[~]` task line with checked sub-items for everything finished.

### 2. `memory/learnings.md` (if anything non-obvious was discovered)

Short bullets only — patterns, gotchas, API quirks.

### 3. Task file checkboxes

Check every contract item that is truly done in the `.task.md` file.

### 4. Final chat line (exact)

```
HANDOFF SAVED — close this chat and run: rig-spec resume
```

---

## What the human does

1. Verify `memory/progress.md` has the `[CHECKPOINT]` block
2. **Close** the current chat (do not continue implementing there)
3. Open a **new** chat / new agent
4. Run `rig-spec resume` and paste the output — or in Cursor/Claude Code: `read .rig/memory/bootstrap.md` then progress + current task

---

## Resume checklist (new session)

1. `.rig/memory/bootstrap.md` reading order
2. `.rig/memory/progress.md` — find `[CHECKPOINT]`
3. Active task file — contract items still `[ ]`
4. Implement **only** "Next action" from the checkpoint first
EOF
  print_ok "memory/session-handoff.md created"
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
What it answers: What is this project? Vision? Business rules? What level? What's active?

### 2. Project Standards (when exists)
→ Read `.rig/STANDARDS.md` then applicable `.rig/feedforward/rules/*.rules.md`
What it answers: Architecture, naming, API, UI tokens — patterns you must follow.

### 3. Current State
→ Read `.rig/memory/progress.md`
What it answers: What's done? What's next? Any blockers? **Search for `[CHECKPOINT]`** if the previous session handed off.

### 3b. Session handoff rules (when chat was long)
→ Read `.rig/memory/session-handoff.md`
What it answers: How checkpoints work and what not to redo.

### 4. Architectural Decisions (when exists)
→ Read `.rig/memory/decisions.md`
What it answers: Why are things the way they are? Do not re-debate decided issues.

### 5. Research Findings (when relevant)
→ Read `.rig/memory/research/[relevant-topic].md`
What it answers: What was already investigated?

### 6. Active Feature Spec (when in progress)
→ Read `.rig/feedforward/specs/[active-feature].spec.md`
What it answers: What are we building? Acceptance criteria? Approved fixtures?

### 7. Current Task (when in progress)
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

> **Filename:** `YYYYMMDD-HHMMSS-[XX]-[slug].task.md` (timestamp first — keeps tasks sorted)
> Example: `20260519-143052-01-dependencies.task.md`
> Run with: `rig-spec run 01-dependencies` (partial match works)

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

## Standards to Follow

> Read `.rig/STANDARDS.md` — list every `feedforward/rules/*.rules.md` that applies.

- `feedforward/rules/architecture.rules.md`
- `feedforward/rules/[other].rules.md`

---

## Skills to Load

> Listed skills are always loaded. `rig-spec run` also auto-matches `skills.registry.md` from task keywords.
> To disable auto-routing, add a line: `skills: manual`

- `feedforward/skills/[technology].skill.md`

---

## Sensors for This Task

> Create or reference sensors in `feedback/sensors/`. `rig-spec validate` runs all configured sensors.

- [ ] `test.sensor.md` ← unit/integration tests
- [ ] `endpoint.sensor.md` ← if this task adds/changes API routes
- [ ] `standards-compliance.sensor.md` ← inferential (review agent)

---

## Contract — Definition of Done

- [ ] [Deliverable 1] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 2] ← verified by: [test / typecheck / validator]
- [ ] Project standards followed per `STANDARDS.md` ← verified by: standards-compliance + review
- [ ] Approved fixtures from spec pass ← verified by: spec-compliance + validator
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

  cat > "$RIG_DIR/feedforward/rules/structure.rules.md" << 'EOF'
# Structure Rules — Node.js

---

## Folder Layout

```
src/
├── [module]/
│   ├── [name].controller.ts
│   ├── [name].service.ts
│   ├── [name].repository.ts
│   ├── [name].dto.ts
│   └── [name].spec.ts
├── shared/
│   └── [utility files]
└── main.ts
```

## Placement Rules

- Controllers live in: `src/[module]/`
- Services live in: `src/[module]/`
- Repositories live in: `src/[module]/`
- Shared utilities live in: `src/shared/`
- Tests live next to the file they test

## Forbidden

- Business logic files outside `src/`
- Test files in a top-level `tests/` folder (keep them co-located)

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ filled for Node.js stack (5 files)"
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

  cat > "$RIG_DIR/feedforward/rules/structure.rules.md" << 'EOF'
# Structure Rules — Python

---

## Folder Layout

```
src/
├── routers/
│   └── [name]_router.py
├── services/
│   └── [name]_service.py
├── repositories/
│   └── [name]_repository.py
├── models/
│   └── [name].py
├── schemas/
│   └── [name]_schema.py
└── main.py
tests/
├── integration/
└── test_[name].py
```

## Placement Rules

- Routers live in: `src/routers/` or `src/[module]/`
- Services live in: `src/services/` or `src/[module]/`
- Repositories live in: `src/repositories/` or `src/[module]/`
- Pydantic schemas live in: `src/schemas/`
- Tests live in: `tests/`, mirroring `src/` structure

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
EOF

  print_ok "feedforward/rules/ filled for Python stack (5 files)"
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

  cat > "$RIG_DIR/feedforward/rules/design-tokens.rules.md" << 'EOF'
# Design Tokens — UI standards

> [DRAFT] Fill in colors, typography, spacing. Point to real files: tailwind.config.ts, tokens.css.

## Source of truth

| Token type | Location |
|---|---|
| CSS variables | `[path]` |
| Tailwind theme | `[path]` |

## Rules

- Do not hardcode hex in components — use theme tokens
- Shared UI primitives: `components/ui/`

Enforced by: `feedback/sensors/standards-compliance.sensor.md`
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

write_rules_retrofit() {
  local ext="ts"
  $RETROFIT_HAS_TS || ext="js"

  # structure.rules.md — filled from real scan
  local tree_content="[No src/ directory found — fill in your actual folder layout]"
  local placement_content="- [file type] must live in: [path]"
  if [ -n "$RETROFIT_SRC_TREE" ]; then
    tree_content="$RETROFIT_SRC_TREE"
    if [ ${#RETROFIT_MODULES[@]} -gt 0 ]; then
      placement_content=""
      for mod in "${RETROFIT_MODULES[@]}"; do
        placement_content+="- \`${mod}/\` — [describe what lives here]"$'\n'
      done
    fi
  fi

  cat > "$RIG_DIR/feedforward/rules/structure.rules.md" << EOF
# Structure Rules — Scanned from project

> Auto-generated by rig-spec retrofit. Verify and complete.

---

## Detected Folder Layout

\`\`\`
$tree_content
\`\`\`

## Placement Rules

$placement_content
---

## Sensor

Enforced by: \`feedback/sensors/structure.sensor.md\` (Level 3)
EOF

  # architecture.rules.md — [DRAFT] but stack-aware
  local layer_hint="Controllers → Services → Repositories → Database"
  [ "$STACK" = "python" ] && layer_hint="Routers → Services → Repositories → Database"

  cat > "$RIG_DIR/feedforward/rules/architecture.rules.md" << EOF
# Architecture Rules — [DRAFT]

> Auto-generated by rig-spec retrofit. Fill in your actual patterns.

---

## Layer Hierarchy

\`\`\`
$layer_hint
\`\`\`

## Module Boundaries

$(for mod in "${RETROFIT_MODULES[@]}"; do echo "- \`$mod/\` — [describe what it can/cannot import]"; done)
$([ ${#RETROFIT_MODULES[@]} -eq 0 ] && echo "- [module-a] may NOT import from [module-b]")

## Forbidden Patterns

- [e.g., Direct database access from a controller]
- [e.g., Business logic inside a route handler]

---

## Sensor

Enforced by: \`feedback/sensors/arch.sensor.md\` (Level 3)
EOF

  # naming.rules.md — TS vs JS aware [DRAFT]
  local type_note=""
  $RETROFIT_HAS_TS && type_note="(TypeScript detected — strict typing expected)"

  cat > "$RIG_DIR/feedforward/rules/naming.rules.md" << EOF
# Naming Rules — [DRAFT] $type_note

> Auto-generated by rig-spec retrofit. Fill in your actual conventions.

---

## Files

- [file type]: \`[pattern].$ext\`

## Classes

- [type]: \`[PascalCase + suffix rule]\`

## Functions / Methods

- [type]: \`[camelCase + prefix rule]\`

## Variables / Constants

- camelCase for variables
- SCREAMING_SNAKE_CASE for module-level constants

---

## Sensor

Enforced by: \`feedback/sensors/naming.sensor.md\` (Level 3)
EOF

  # api.rules.md — [DRAFT] with detected stack hint
  cat > "$RIG_DIR/feedforward/rules/api.rules.md" << 'APIEOF'
# API Rules — [DRAFT]

> Auto-generated by rig-spec retrofit. Fill in your actual API conventions.

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
APIEOF

  # testing.rules.md — test pattern aware [DRAFT]
  local test_loc_note="[Fill in where tests live in this project]"
  if [ "$RETROFIT_TEST_PATTERN" = "co-located" ]; then
    test_loc_note="Tests appear to be co-located next to source files (e.g., \`[name].spec.$ext\`)"
  elif [ "$RETROFIT_TEST_PATTERN" = "separate-folder" ]; then
    test_loc_note="Tests appear to live in a separate \`test/\` or \`__tests__/\` folder"
  fi

  cat > "$RIG_DIR/feedforward/rules/testing.rules.md" << EOF
# Testing Rules — [DRAFT]

> Auto-generated by rig-spec retrofit. Fill in your actual testing conventions.

---

## Test Location

$test_loc_note

## Coverage Requirements

- [Module]: minimum [X]%

## Rules

- Do NOT mock the database in integration tests
- Test names must describe behavior, not implementation
- Approved Fixtures Policy: expected outputs are defined by humans in the spec BEFORE agents write tests

---

## Sensor

Enforced by: \`feedback/sensors/test.sensor.md\` (Level 3)
EOF

  print_ok "feedforward/rules/ generated from project scan (structure filled, others [DRAFT])"
}

write_topology_rules() {
  if [ "$RETROFIT" = true ]; then
    write_rules_retrofit
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
  if [ "$RETROFIT" = true ]; then
    # Write skills based on detected technologies (stack-agnostic knowledge, always valid)
    case "$STACK" in
      node|nestjs|express) write_skills_node ;;
      python)              write_skills_python ;;
      nextjs)              write_skills_nextjs ;;
      *)
        # Even without stack: if TS detected, write TS + node skills
        if $RETROFIT_HAS_TS; then
          write_skills_node
        else
          write_skill_template
        fi
        ;;
    esac
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

# Updates HARNESS.md "Active Feature" and "Next Task" fields.
patch_harness_focus() {
  local harness="$RIG_DIR/HARNESS.md"
  [ ! -f "$harness" ] && return
  local feature="$1"
  local next_task="${2:-none}"
  local tmp
  tmp=$(mktemp)
  sed \
    "s|^\*\*Active Feature:\*\*.*|\*\*Active Feature:\*\* $feature|" \
    "$harness" | \
  sed \
    "s|^\*\*Next Task:\*\*.*|\*\*Next Task:\*\* $next_task|" \
  > "$tmp" && mv "$tmp" "$harness"
}

# Adds a new feature to progress.md Active Features block.
# No-op if the feature is already listed.
patch_progress_add_feature() {
  local progress="$RIG_DIR/memory/progress.md"
  [ ! -f "$progress" ] && return
  local feature="$1"
  local spec_file="$2"

  # Already listed?
  grep -q "\*\*$feature\*\*" "$progress" 2>/dev/null && return

  local tmp
  tmp=$(mktemp)
  awk -v feature="$feature" -v spec="$spec_file" -v date="$(today)" '
    /^_No features in progress yet\._/ {
      print "**" feature "**"
      print ""
      print "- Spec: `" spec "`"
      print "- Status: spec created — tasks not yet planned"
      print "- Started: " date
      next
    }
    { print }
  ' "$progress" > "$tmp" && mv "$tmp" "$progress"
}

# Updates progress.md Last Session block with today's summary.
patch_progress_last_session() {
  local progress="$RIG_DIR/memory/progress.md"
  [ ! -f "$progress" ] && return
  local what_happened="$1"
  local whats_next="${2:-—}"

  local tmp
  tmp=$(mktemp)
  awk -v date="$(today)" -v happened="$what_happened" -v nextstep="$whats_next" '
    /^\*\*Date:\*\*/ { print "**Date:** " date; next }
    /^\*\*What happened:\*\*/ { print "**What happened:** " happened; next }
    /^\*\*What'\''s next:\*\*/ { print "**What'\''s next:** " nextstep; next }
    /^\*\*Blockers:\*\*/ { print "**Blockers:** None."; next }
    { print }
  ' "$progress" > "$tmp" && mv "$tmp" "$progress"
}

# Marks a task as in-progress in progress.md ([ ] → [~]).
patch_progress_task_inprogress() {
  local progress="$RIG_DIR/memory/progress.md"
  [ ! -f "$progress" ] && return
  local task_id="$1"

  local tmp
  tmp=$(mktemp)
  sed "s|- \[ \] \(.*${task_id}.*\)|- [~] \1 ← in progress|g" "$progress" > "$tmp" && mv "$tmp" "$progress"
}

# Marks a task as complete in progress.md (moves to Completed, updates Last Session).
patch_progress_task_done() {
  local progress="$RIG_DIR/memory/progress.md"
  [ ! -f "$progress" ] && return
  local task_id="$1"
  local feature="$2"

  local tmp
  tmp=$(mktemp)
  # Replace pending task line with done marker if it exists
  sed "s|- \[ \] \(.*${task_id}.*\)|- [x] \1|g" "$progress" > "$tmp" && mv "$tmp" "$progress"
}

write_sensor_templates() {
  for sensor in "${SENSORS[@]}"; do
    case "$sensor" in
      eslint)
        cat > "$RIG_DIR/feedback/sensors/lint.sensor.md" << 'EOF'
---
command: npx eslint src/ --max-warnings 0
type: computational
timing: after-task
---

# Sensor: Lint (ESLint)

## Pass condition
Exit code 0. Zero warnings, zero errors.

## On failure
Fix all reported issues. Do not suppress rules with inline comments or config overrides.
EOF
        ;;
      ruff)
        cat > "$RIG_DIR/feedback/sensors/lint.sensor.md" << 'EOF'
---
command: ruff check .
type: computational
timing: after-task
---

# Sensor: Lint (Ruff)

## Pass condition
Exit code 0. Zero violations.

## On failure
Fix all reported issues. Do not add `noqa` suppressions without justification.
EOF
        ;;
      typescript)
        cat > "$RIG_DIR/feedback/sensors/typecheck.sensor.md" << 'EOF'
---
command: npx tsc --noEmit
type: computational
timing: after-task
---

# Sensor: Type Check (TypeScript)

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `any` or `@ts-ignore`.
EOF
        ;;
      mypy)
        cat > "$RIG_DIR/feedback/sensors/typecheck.sensor.md" << 'EOF'
---
command: mypy .
type: computational
timing: after-task
---

# Sensor: Type Check (mypy)

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `type: ignore` without justification.
EOF
        ;;
      npm-test)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
---
command: npm test
type: computational
timing: after-task
---

# Sensor: Tests (npm test)

## Pass condition
Exit code 0. All tests pass.

## On failure
Fix the implementation. Do not change tests to match a broken implementation.
EOF
        ;;
      pytest)
        cat > "$RIG_DIR/feedback/sensors/test.sensor.md" << 'EOF'
---
command: pytest
type: computational
timing: after-task
---

# Sensor: Tests (pytest)

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

write_sensors_config() {
  local config="$RIG_DIR/feedback/sensors.config.yaml"
  [ -f "$config" ] && return  # never overwrite an existing config
  cat > "$config" << 'EOF'
# sensors.config.yaml — shorthand sensor commands
#
# Add one-liner sensors here instead of creating a full .sensor.md file.
# `rig-spec validate` runs every uncommented entry as a computational sensor.
#
# Rules:
#   - One entry per line: name: command to run
#   - Lines starting with # are comments (ignored)
#   - If a .sensor.md with the same name exists in sensors/, it takes priority
#   - Use .sensor.md when you need On Failure instructions or timing config
#
# Uncomment and adjust to match your project:
#
# lint:      npm run lint
# test:      npm test
# typecheck: npx tsc --noEmit
# build:     npm run build
EOF
}

write_sensor_generic_template() {
  cat > "$RIG_DIR/feedback/sensors/_TEMPLATE.sensor.md" << 'EOF'
---
command: [the exact command to run]
type: computational
timing: after-task
---

# Sensor: [Name]

> The `command:` key in the frontmatter above is what `rig-spec validate` executes.
> Use frontmatter for the command — it is unambiguous and parser-safe.
> Use the sections below for human/agent guidance only.

---

## Type

- [ ] Computational (deterministic — linter, test runner, type checker)
- [ ] Inferential (AI-based — semantic review, spec compliance)

## Timing

- [ ] After every task (fast)
- [ ] After every task (slower — integration tests)
- [ ] After integration (full review)
- [ ] Continuous (scheduled — audit)

---

## Pass Condition

Exit code: `0`
[Any additional output conditions to check]

## On Failure

[What the agent should do when this sensor fails.]

The agent receives the full output. It must:
1. [Step 1 — e.g., fix the reported issues]
2. [Step 2 — e.g., never suppress warnings with flags]
3. [Step 3 — e.g., re-run the sensor after fixing]

Do not mark the contract item as passed until this sensor exits 0.

---

## Error Format for Agent Correction

[How the output is structured — so the agent knows how to parse failures.]

```
[example failure output format]
```
EOF
}

# Generates AI tool entry point files at the project root.
write_adapters() {
  mkdir -p "$RIG_DIR/adapters"

  cat > "$RIG_DIR/adapters/claude.md" << 'EOF'
# Adapter: Claude Code

> Optional. Supplements HARNESS.md with Claude Code-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

When starting a session in this project, read:

```
Read .rig/HARNESS.md first, then follow the bootstrap sequence in .rig/memory/bootstrap.md
```

## Memory System

Claude Code's built-in memory (`.claude/`) stores user preferences. `.rig/memory/` stores project state. They are separate:

- `.claude/` — how you work with Claude across all projects
- `.rig/memory/` — the state of this specific project

## Recommended Permissions

Allow Claude Code to run the sensors defined in `feedback/sensors/` without prompting.
Open `.claude/settings.local.json` and add a `Bash(...)` entry for each command in your sensor files.

Example (adjust to match your actual sensor commands):

```json
{
  "allowedTools": [
    "Bash([your-lint-command]*)",
    "Bash([your-typecheck-command]*)",
    "Bash([your-test-command]*)"
  ]
}
```

See `.rig/feedback/sensors/` for the exact commands to allowlist.

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Open a new conversation for the implementer → load `orchestration/implementer.md`
2. Open a separate conversation for the validator → load `orchestration/validator.md`
3. Pass the signed contract between them

Claude Code Projects can maintain separate conversation threads for this.
EOF

  cat > "$RIG_DIR/adapters/gemini.md" << 'EOF'
# Adapter: Gemini

> Optional. Supplements HARNESS.md with Gemini-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

At the start of every session, include in your first message:

```
Read .rig/HARNESS.md first, then follow the bootstrap sequence in .rig/memory/bootstrap.md before doing anything else.
```

## Context Window

Gemini supports large context windows. For this project:

- Load all rules files at session start: `.rig/feedforward/rules/`
- Load relevant skills per task: `.rig/feedforward/skills/[skill].md`
- Do not load all files at once — prioritize what the current task needs

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Use a separate Gemini session for each agent
2. Start the implementer session with: `orchestration/implementer.md`
3. Start the validator session with: `orchestration/validator.md`
4. Pass the contract as a file attachment between sessions

## Grounding

If using Gemini with Google Search grounding, turn it off during implementation sessions. Grounding is useful for research, but implementation sessions should rely only on the project context assembled from `.rig/`.
EOF

  cat > "$RIG_DIR/adapters/antigravity.md" << 'EOF'
# Adapter: Antigravity

> Optional. Supplements HARNESS.md with Antigravity-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

At the start of every session, include in your first message:

```
Read .rig/HARNESS.md first, then .rig/memory/bootstrap.md before proceeding.
```

## Skills Integration

Antigravity's skill system maps directly to the rig-spec skills:

- Local skills in `.rig/feedforward/skills/` → load as Antigravity skills per task
- External skills referenced in `HARNESS.md` → load from your skill library

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Configure two separate Antigravity agents with different profiles
2. Implementer agent: load `orchestration/implementer.md` as the agent profile
3. Validator agent: load `orchestration/validator.md` as the agent profile
4. Use Antigravity's multi-agent handoff to pass the signed contract

## Sensor Hooks

Configure Antigravity hooks to auto-run sensors after each task:

```yaml
on_task_complete:
  - run: sensors/lint.sensor.md
  - run: sensors/typecheck.sensor.md
  - run: sensors/test.sensor.md
```
EOF

  print_ok "adapters/ created (claude.md, gemini.md, antigravity.md)"
}

write_mcp_config() {
  cat > "$RIG_DIR/feedforward/mcp.config.md" << 'EOF'
# MCP Configuration

> Level 2 — MCP servers available to agents in this project.
> Agents load these only when relevant to the current task — not all at once.

---

## Configured Servers

[Add an entry for each MCP server configured for this project.]

### [server-name]

**Purpose:** [What real-time context this server provides]
**When to use:** [Which task types benefit from this server]
**Config file:** `[path to .mcp config file]`

**Usage example:**
```
[How the agent should invoke this server for common tasks]
```

---

## Notes

- MCP servers declared here supplement the static files in `.rig/` — they are not a replacement.
- If a server is unavailable, fall back to the static files in `memory/research/`.
- Never load all servers simultaneously — only what the current task needs.
EOF
  print_ok "feedforward/mcp.config.md created"
}

write_research_template() {
  cat > "$RIG_DIR/memory/research/_TEMPLATE.research.md" << 'EOF'
# Research: [Topic]

> Output of a dedicated research session.
> This file is the clean result — not the exploration log.
> Implementation sessions read this instead of re-doing the research.

---

## Topic

[What was investigated. One sentence.]

## Key Findings

- [Finding 1]
- [Finding 2]
- [Finding 3]

## Relevant Files Discovered

- `src/[file]` — [why it matters]

## Patterns Already in Use

- [Pattern 1 — where it's used]

## Recommended Approach

[The concrete recommendation for how to implement this feature, based on findings.]

## Open Questions

- [ ] [Question 1] ← owner: [human / architect agent]
EOF
  print_ok "memory/research/_TEMPLATE.research.md created"
}

write_orchestration_profiles() {
  cat > "$RIG_DIR/orchestration/implementer.md" << 'EOF'
# Implementer Agent

> Level 3 — Two-agent orchestration.
> Read this profile before every implementation task.

---

## Your Role

You are the **implementer**. Your only job is to build what the task contract specifies — nothing more.

---

## Before You Write Any Code

Read these files in order:

1. `.rig/HARNESS.md` — project overview and active context
2. `.rig/memory/progress.md` — current state
3. The active spec: `.rig/feedforward/specs/[feature].spec.md`
4. The current task: `.rig/feedforward/tasks/[feature]/task-[XX].md`
5. All rules files: `.rig/feedforward/rules/`
6. The skills listed in the task: `.rig/feedforward/skills/[skill].md`

---

## Rules

**Build only what the contract specifies.**
If something is not in the contract, do not build it. Scope is fixed.

**Respect file ownership.**
You may only create or modify files declared in the task's File Ownership section. If you need to touch something outside that list, stop and escalate.

**Do not self-validate.**
You are not the validator. Do not run sensors to check your own work. Do not declare yourself done based on your own judgment. The validator decides if you passed.

**Sign the contract.**
When you finish each deliverable, check the corresponding box in the contract. Every box must be checked before handoff.

**Do not modify tests to pass.**
If a test fails, fix the implementation. Changing a test to match wrong behavior is never acceptable.

---

## Handoff

When all contract items are checked:

1. Ensure all changed files are saved
2. Write a brief summary of what you built (2-4 sentences)
3. Pass the contract to the validator
EOF

  cat > "$RIG_DIR/orchestration/validator.md" << 'EOF'
# Validator Agent

> Level 3 — Two-agent orchestration.
> Read this profile before every validation task.

---

## Your Role

You are the **validator**. Your only job is to verify that the implementation satisfies the contract — nothing more.

---

## Before You Validate

Read these files:

1. The signed contract: `.rig/orchestration/contracts/[feature]-task-[XX].contract.md`
2. The spec (for approved fixtures): `.rig/feedforward/specs/[feature].spec.md`
3. The implementation (the files listed in contract File Ownership)
4. Sensor results (if sensors are configured)

---

## Validation Process

### Step 1 — Run computational sensors
For each sensor in `feedback/sensors/`: execute the command, record PASS or FAIL.

### Step 2 — Check each contract item
For every item in "Implementer Commits To": verify using the method in "Validator Must Check". Mark PASS or FAIL — no partial credit.

### Step 3 — Check approved fixtures
Run the test that covers each approved fixture. Every fixture must produce the exact expected output.

### Step 4 — Check file ownership
Run `git diff --name-only`. Any file outside the declared ownership list is a violation.

---

## Rules

**Check every item. No shortcuts.**
Do not mark PASSED if any item is unchecked or failed.

**No suggestions beyond contract scope.**
You are not a code reviewer. Do not suggest improvements outside the contract items.

**Be specific on failures.**
Failures must include: file path, line number (when applicable), expected vs. actual.

**You cannot be biased toward passing.**
Your job is to find what's wrong, not to confirm it passed.

---

## Verdict

- **PASSED**: All items verified, all sensors green, all fixtures pass. Update `memory/progress.md` to mark task complete.
- **FAILED**: Return the contract to the implementer with a specific failure list.
EOF

  print_ok "orchestration/implementer.md and validator.md created"
}

write_review_template() {
  cat > "$RIG_DIR/feedback/review/code-review.review.md" << 'EOF'
# Review Agent — Code Review

> Level 3 — Inferential sensor.
> Runs after the validator confirms computational sensors pass.
> Scope: only the files changed in this task.

---

## Your Role

You are a **code reviewer**. Your job is to check that the implementation is semantically correct — not just syntactically valid.

Computational sensors (lint, typecheck, tests) check structure. You check meaning.

---

## Scope

Only review files in the task's File Ownership list. Do not comment on code outside this task's scope.

---

## What to Check

### 1. Spec Compliance
- Does the implementation satisfy every acceptance criterion in the spec?
- Do the approved fixtures produce the exact expected outputs?

### 2. Architecture Rules
- Does the implementation follow `feedforward/rules/architecture.rules.md`?
- Are module boundaries respected? Is layering correct?

### 3. Standards Compliance
- Naming conventions per `feedforward/rules/naming.rules.md`?
- File structure per `feedforward/rules/structure.rules.md`?
- API response format per `feedforward/rules/api.rules.md`?
- Test structure per `feedforward/rules/testing.rules.md`?

### 4. Edge Cases
- Are obvious edge cases handled?
- Are there unhandled error paths?

---

## Output Format

```markdown
## Review Result: PASS | FAIL

### Spec Compliance
[PASS / FAIL] — [details]

### Architecture Rules
[PASS / FAIL] — [details]

### Standards Compliance
[PASS / FAIL] — [details]

### Edge Cases
[PASS / notes]

### Failures (if any)
- File: `[path]`, Line: [N] — [expected vs actual]
```

Return only what's listed above. No refactoring suggestions. No style opinions beyond what the rules define.
EOF
  print_ok "feedback/review/code-review.review.md created"

  cat > "$RIG_DIR/feedback/review/validation-matrix.review.md" << 'EOF'
# Validation Matrix — Review protocol

> Used by `rig-spec validate` after computational sensors run.

Read: task contract, `.rig/STANDARDS.md`, applicable `feedforward/rules/`, linked spec, and `feedback/review/code-review.review.md`.

Fill every row in the validation report matrix. Overall PASS only if every row is PASS or N/A.

See template output in `feedback/reports/validation-*.md` generated by the CLI.
EOF
  print_ok "feedback/review/validation-matrix.review.md created"
}

write_standards_index() {
  cat > "$RIG_DIR/STANDARDS.md" << 'EOF'
# Project Standards — Index

> Canonical map of where every project pattern lives.
> Before implementing any task, read applicable `feedforward/rules/*.rules.md`.

## Standards topology

| Concern | File |
|---|---|
| Architecture, layering | `feedforward/rules/architecture.rules.md` |
| Naming | `feedforward/rules/naming.rules.md` |
| Folder layout | `feedforward/rules/structure.rules.md` |
| API shape | `feedforward/rules/api.rules.md` |
| Tests | `feedforward/rules/testing.rules.md` |
| UI components | `feedforward/rules/component.rules.md` (if exists) |
| Colors / tokens | `feedforward/rules/design-tokens.rules.md` (if exists) |

## Enforcement

| Check | File |
|---|---|
| Lint | `feedback/sensors/lint.sensor.md` |
| Types | `feedback/sensors/typecheck.sensor.md` |
| Tests | `feedback/sensors/test.sensor.md` |
| API smoke | `feedback/sensors/endpoint.sensor.md` |
| Spec match | `feedback/sensors/spec-compliance.sensor.md` |
| Rules match | `feedback/sensors/standards-compliance.sensor.md` |
| Review | `feedback/review/code-review.review.md` |

Run: `rig-spec validate <task-id>` → report in `feedback/reports/`.

Skill routing: `feedforward/skills.registry.md`
EOF
  print_ok "STANDARDS.md created"
}

write_skills_registry() {
  local registry="$RIG_DIR/feedforward/skills.registry.md"
  [ -f "$registry" ] && return

  cat > "$registry" << 'EOF'
# Skills Registry — Automatic routing

> `rig-spec run` matches task text to keywords below and loads skills into context.
> Add rows when you create new `feedforward/skills/*.skill.md` files.

## Local skills

| Domain | Skill path | Match keywords |
|---|---|---|
| typescript | `feedforward/skills/typescript.skill.md` | typescript, ts, interface, dto |
| backend | `feedforward/skills/nodejs.skill.md` | service, repository, controller, api, endpoint, backend |
| python | `feedforward/skills/python.skill.md` | python, fastapi, pydantic, pytest |
| fastapi | `feedforward/skills/fastapi.skill.md` | fastapi, router, dependency |
| frontend | `feedforward/skills/react.skill.md` | react, component, hook, jsx, page |
| nextjs | `feedforward/skills/nextjs.skill.md` | nextjs, app router, server component, route |
| testing | `feedforward/skills/testing.skill.md` | test, spec, fixture, mock, e2e |

## External skills (optional — uncomment paths)

| Domain | External skill | Match keywords |
|---|---|---|
| security | `~/.claude/skills/cc-skill-security-review/SKILL.md` | auth, login, password, token, jwt |
| api-design | `~/.claude/skills/api-design-principles/SKILL.md` | rest, openapi, graphql |
EOF
  print_ok "feedforward/skills.registry.md created"
}

write_compliance_sensor_templates() {
  local d="$RIG_DIR/feedback/sensors"
  if [ ! -f "$d/standards-compliance.sensor.md" ]; then
    cat > "$d/standards-compliance.sensor.md" << 'EOF'
# Sensor: Standards Compliance

> Type: Inferential | Timing: After every task

## Command

```bash
echo "INFERENTIAL: review agent — read feedforward/rules/ per STANDARDS.md"
```

## Pass Condition

Review agent: Standards Compliance PASS in validation report.
EOF
  fi
  if [ ! -f "$d/spec-compliance.sensor.md" ]; then
    cat > "$d/spec-compliance.sensor.md" << 'EOF'
# Sensor: Spec Compliance

> Type: Inferential | Timing: After every task

## Command

```bash
echo "INFERENTIAL: review agent — compare implementation to linked spec"
```

## Pass Condition

Review agent: Spec compliance PASS; all in-scope acceptance criteria and fixtures satisfied.
EOF
  fi
  if [ ! -f "$d/endpoint.sensor.md" ]; then
    cat > "$d/endpoint.sensor.md" << 'EOF'
# Sensor: API Endpoint Smoke

> Type: Computational | Timing: Tasks that change HTTP endpoints

## Command

```bash
# Configure: npm test -- --testPathPattern=api || pytest -q -k api
# Until configured, this sensor is skipped (not failed)
echo "SKIP: configure endpoint.sensor.md with your API test command"
```

## Pass Condition

Exit code 0, or SKIP while command contains "SKIP:" and is not yet configured.
EOF
  fi
  print_ok "Compliance sensor templates (standards, spec, endpoint)"
}

write_audit_templates() {
  cat > "$RIG_DIR/feedback/audit/dead-code.audit.md" << 'EOF'
# Audit: Dead Code

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects unused exports, unreachable code, and orphaned files.

---

## Command

```bash
# Fill in the command for your stack:

# Node.js / TypeScript
# npx knip
# npx ts-prune

# Python
# vulture src/

# Go
# go build ./... (unused imports are compile errors)

# Rust
# cargo check 2>&1 | grep "unused"
```

## What It Detects

- Exported functions/classes/symbols never referenced elsewhere
- Files never imported
- Variables declared but never used

## Pass Condition

Zero unused exports in the source tree. Exceptions documented below.

## Known Exceptions

- [export name] in [file] — reason: [why it's intentionally kept]

## On Detection

1. Confirm each item is genuinely unused (not a false positive)
2. Remove unused code or document why it must stay
3. Update Known Exceptions if keeping it is intentional
EOF

  cat > "$RIG_DIR/feedback/audit/dependency-health.audit.md" << 'EOF'
# Audit: Dependency Health

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects outdated dependencies, known vulnerabilities, and unused packages.

---

## Commands

```bash
# Fill in the commands for your stack:

# Node.js
# npm audit                  # vulnerabilities
# npm outdated               # outdated packages
# npx depcheck               # unused/missing deps

# Python
# pip-audit                  # vulnerabilities (pip install pip-audit)
# pip list --outdated        # outdated packages

# Go
# govulncheck ./...          # vulnerabilities (go install golang.org/x/vuln/cmd/govulncheck@latest)

# Rust
# cargo audit                # vulnerabilities (cargo install cargo-audit)
# cargo outdated             # outdated crates (cargo install cargo-outdated)

# PHP (Composer)
# composer audit             # vulnerabilities
# composer outdated          # outdated packages
```

## Pass Condition

- Zero critical or high severity vulnerabilities
- No dependencies more than 2 major versions behind
- No unused dependencies

## On Detection

1. Vulnerabilities: update immediately and test
2. Outdated: create an upgrade task for the next sprint
3. Unused: clean up your dependency manifest
EOF

  cat > "$RIG_DIR/feedback/audit/drift-report.audit.md" << 'EOF'
# Audit: Drift Report

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects gradual architectural degradation invisible in per-task sensors.

---

## What This Checks

### Architecture Drift
- Module boundary violations that slipped through
- New forbidden imports
- Layer violations missed by per-task sensors

### Standards Drift
- New files not following naming conventions
- New folders outside the defined structure
- API responses not matching the envelope

### Coverage Drift
- Modules whose test coverage dropped below minimum
- Files added without tests

---

## Commands

```bash
# Fill in the commands for your stack:

# Architecture drift
# Node.js: npx depcruise src/ --config .dependency-cruiser.json
# Python:  pydeps [package] --max-bacon 4
# Go:      go vet ./...
# Java:    mvn dependency:analyze

# Coverage drift
# Node.js: npm test -- --coverage
# Python:  pytest --cov=src --cov-report=term
# Go:      go test ./... -cover
# Rust:    cargo tarpaulin
```

## Report Format

Findings saved to: `feedback/audit/report-[YYYY-MM-DD].md`

```markdown
# Drift Report — [YYYY-MM-DD]

## Architecture Drift
[CLEAN / VIOLATIONS FOUND]
- [violation] → `[file]`

## Standards Drift
[CLEAN / VIOLATIONS FOUND]

## Coverage Drift
[CLEAN / BELOW MINIMUM]
- `[module]`: [X]% (minimum: [Y]%)

## Trend
[Better / Stable / Degrading] vs previous report
```
EOF

  print_ok "feedback/audit/ templates created (3 files)"
}

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
  echo -e "  ${BOLD}What does your project do?${RESET}"
  echo -e "  ${DIM}Run this command to give your .rig full context about the project:${RESET}"
  echo -e "  ${DIM}describe what it is, who it serves, and what core problem it solves.${RESET}"
  echo -e "  ${DIM}This seeds HARNESS.md Vision and Business Rules. Press Enter to skip.${RESET}"
  echo ""
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
  if [ "$RETROFIT" = true ]; then
    print_step "Scanning project structure..."
    scan_retrofit_structure
  fi
  echo ""

  print_step "Creating .rig/ structure..."
  mkdir -p "$RIG_DIR/feedforward/specs"
  mkdir -p "$RIG_DIR/feedforward/tasks"
  mkdir -p "$RIG_DIR/feedforward/rules"
  mkdir -p "$RIG_DIR/feedforward/skills"
  mkdir -p "$RIG_DIR/feedback/sensors"
  mkdir -p "$RIG_DIR/feedback/review"
  mkdir -p "$RIG_DIR/feedback/reports"
  mkdir -p "$RIG_DIR/feedback/audit"
  mkdir -p "$RIG_DIR/memory/research"
  mkdir -p "$RIG_DIR/memory/shape-qa"
  mkdir -p "$RIG_DIR/memory/plan-qa"
  mkdir -p "$RIG_DIR/orchestration/contracts"
  print_ok "Folder structure created"

  print_step "Writing core files..."
  write_harness_md
  write_progress_md
  write_bootstrap_md
  write_session_handoff_md
  write_decisions_md
  write_spec_template
  write_task_template
  write_contract_template
  write_topology_rules
  write_topology_skills
  patch_harness_skills
  write_mcp_config
  write_research_template
  write_orchestration_profiles
  write_review_template
  write_standards_index
  write_skills_registry
  write_compliance_sensor_templates
  write_audit_templates
  write_sensors_config
  write_sensor_generic_template
  write_sensor_templates
  write_adapters

  # Write .rig/.gitignore to keep context assembler outputs out of version control
  cat > "$RIG_DIR/.gitignore" << 'EOF'
# Assembled context files — generated by rig-spec run/shape/plan, not meant for commit
context-*.md
# Current task tracker — local session state
.current-task
.handoff-pending
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
    local scan_info="structure scanned"
    [ -n "$RETROFIT_SRC_TREE" ] && scan_info="structure scanned (${#RETROFIT_MODULES[@]} modules)"
    echo -e "  ${BOLD}Mode:${RESET} retrofit ($scan_info — architecture/naming rules as [DRAFT])"
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
  echo "  Fill in vision and rules: rig-spec overview"
  echo "  Check status anytime:    rig-spec status"
  echo ""

  # Placeholder check — show exactly which HARNESS.md sections still need content
  local harness_check="$RIG_DIR/HARNESS.md"
  local -a missing_sections=()

  if grep -qF '[Add a one-paragraph description' "$harness_check" 2>/dev/null; then
    missing_sections+=("Description (## Project)")
  fi
  if grep -qF '[Describe the product vision' "$harness_check" 2>/dev/null; then
    missing_sections+=("Vision (## Vision)")
  fi
  if grep -qF '[Rule 1' "$harness_check" 2>/dev/null || grep -qF '[Rule 2' "$harness_check" 2>/dev/null; then
    missing_sections+=("Business Rules (## Business Rules)")
  fi

  if [ ${#missing_sections[@]} -gt 0 ]; then
    echo -e "  ${YELLOW}${BOLD}⚠  HARNESS.md needs your input — agents read this first:${RESET}"
    echo ""
    for s in "${missing_sections[@]}"; do
      echo -e "  ${YELLOW}   · $s${RESET}"
    done
    echo ""
    echo -e "  ${DIM}   Edit: $harness_check${RESET}"
    echo ""
  fi
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

  # Archive hint — suggest archiving when completed features accumulate
  if [ -f "$progress" ]; then
    local completed_sections
    completed_sections=$(awk '
      /^## Completed Features/ { in_completed=1; next }
      /^## / { in_completed=0 }
      in_completed && /^### / { count++ }
      END { print count+0 }
    ' "$progress" 2>/dev/null)

    if [ "${completed_sections:-0}" -ge 2 ]; then
      echo -e "  ${DIM}Tip: $completed_sections completed features in progress.md.${RESET}"
      echo -e "  ${DIM}     rig-spec archive <spec-name>  — moves each to memory/archive/ to keep context lean.${RESET}"
      echo ""
    fi
  fi
}

# ─────────────────────────────────────────────
# cmd_resume
# ─────────────────────────────────────────────

cmd_resume() {
  require_rig
  rm -f "$RIG_DIR/.handoff-pending"

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec resume${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "${DIM}NEW chat session — paste the block below into a fresh agent (not the old thread).${RESET}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "> **New session.** The agent has no memory of prior chats. State lives only in `.rig/` files."
  echo ""

  if progress_has_checkpoint; then
    echo -e "${BOLD}${YELLOW}⚠ Pending CHECKPOINT in progress.md — continue from here:${RESET}"
    echo ""
    awk '/\[CHECKPOINT\]/{p=1} p{print} p && /^## [^#]/ && !/\[CHECKPOINT\]/{exit}' "$RIG_DIR/memory/progress.md" 2>/dev/null || true
    echo ""
    echo "---"
    echo ""
  fi

  if [ -f "$RIG_DIR/memory/session-handoff.md" ]; then
    echo "## Session handoff rules"
    echo ""
    cat "$RIG_DIR/memory/session-handoff.md"
    echo ""
    echo "---"
    echo ""
  fi

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

  # Print learnings if exists
  if [ -f "$RIG_DIR/memory/learnings.md" ]; then
    cat "$RIG_DIR/memory/learnings.md"
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
      local spec_file
      spec_file=$(find_spec_file "$active" 2>/dev/null) || spec_file=""
      if [ -n "$spec_file" ] && [ -f "$spec_file" ]; then
        echo "## Active Spec"
        echo ""
        cat "$spec_file"
        echo ""
        echo "---"
        echo ""
      fi
    fi
  fi

  # Current task file (from last rig-spec run)
  if [ -f "$RIG_DIR/.current-task" ]; then
    local cur_task cur_file
    cur_task=$(cat "$RIG_DIR/.current-task")
    cur_file=$(find_task_file "$cur_task" 2>/dev/null) || cur_file=""
    if [ -n "$cur_file" ] && [ -f "$cur_file" ]; then
      echo "## Current Task (from last run)"
      echo ""
      cat "$cur_file"
      echo ""
      echo "---"
      echo ""
    fi
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo -e "  ${DIM}Paste the block above into a **new** AI chat.${RESET}"
  if progress_has_checkpoint; then
    echo -e "  ${DIM}Start with the CHECKPOINT \"Next action\" — do not redo completed work.${RESET}"
  else
    echo -e "  ${DIM}Continue from progress.md \"What's next\" or the current task contract.${RESET}"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# cmd_session — quick session health / handoff hint
# ─────────────────────────────────────────────

cmd_session() {
  require_rig
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec session${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  if [ -f "$RIG_DIR/.current-task" ]; then
    echo -e "  ${BOLD}Current task:${RESET} $(cat "$RIG_DIR/.current-task")"
  else
    echo -e "  ${BOLD}Current task:${RESET} ${DIM}(none — run rig-spec run <task-id>)${RESET}"
  fi

  local active
  active=$(harness_active_feature)
  [ -n "$active" ] && [ "$active" != "none" ] && \
    echo -e "  ${BOLD}Active feature:${RESET} $active"

  if progress_has_checkpoint; then
    print_warn "Pending CHECKPOINT in memory/progress.md — use a new chat + rig-spec resume"
  fi

  if [ -f "$RIG_DIR/.handoff-pending" ]; then
    print_warn "Handoff requested — agent should save CHECKPOINT, then: rig-spec resume in new chat"
  fi

  echo ""
  echo -e "  ${BOLD}Hand off to a new agent when:${RESET}"
  echo "    • Chat is long or answers drift"
  echo "    • Agent unsure what is already done"
  echo "    • One chunk done, more work remains on same task"
  echo ""
  echo -e "  ${BOLD}Commands:${RESET}"
  echo "    rig-spec handoff [task-id]   Save-state prompt for the current agent"
  echo "    rig-spec resume              Context for a **new** chat session"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_handoff — assemble save-state context before new session
# ─────────────────────────────────────────────

cmd_handoff() {
  require_rig
  local task_id="$1"

  if [ -z "$task_id" ] && [ -f "$RIG_DIR/.current-task" ]; then
    task_id=$(cat "$RIG_DIR/.current-task")
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec handoff${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  if [ -z "$task_id" ]; then
    print_err "Usage: rig-spec handoff [task-id]"
    echo ""
    echo "  Run a task first: rig-spec run <task-id>"
    echo "  Or pass the task id explicitly."
    echo ""
    exit 1
  fi

  local task_file
  if ! task_file=$(find_task_file_or_fail "$task_id"); then
    print_err "Task not found: $task_id"
    exit 1
  fi

  local task_basename feature_dir
  task_basename=$(basename "$task_file" .task.md)
  feature_dir=$(basename "$(dirname "$task_file")")

  date -Iseconds > "$RIG_DIR/.handoff-pending"

  local context_file="$RIG_DIR/context-handoff-${task_basename}.md"
  {
    session_continuity_block
    echo ""
    echo "---"
    echo ""
    echo "# Handoff — save progress and end this session"
    echo ""
    echo "> **Do not implement new code.** Your only job is to persist state for the next agent."
    echo ""
    echo "**Task:** \`$task_basename\` (feature: \`$feature_dir\`)"
    echo ""
    echo "---"
    echo ""
    echo "## Task contract (verify checkboxes)"
    echo ""
    cat "$task_file"
    echo ""
    echo "---"
    echo ""
    echo "## Current progress.md"
    echo ""
    [ -f "$RIG_DIR/memory/progress.md" ] && cat "$RIG_DIR/memory/progress.md" || echo "_missing_"
    echo ""
    echo "---"
    echo ""
    echo "## Instructions"
    echo ""
    echo "1. Read \`.rig/memory/session-handoff.md\`"
    echo "2. Update \`.rig/memory/progress.md\` with a \`[CHECKPOINT]\` block under the active feature"
    echo "3. Check completed items in the task file above"
    echo "4. Append discoveries to \`.rig/memory/learnings.md\` if any"
    echo "5. End your message with exactly:"
    echo ""
    echo "   HANDOFF SAVED — close this chat and run: rig-spec resume"
    echo ""
    echo "**Forbidden:** starting new implementation in this chat after handoff."
  } > "$context_file"

  patch_progress_last_session \
    "Handoff requested for $task_basename." \
    "Agent saves CHECKPOINT → human runs rig-spec resume in a new chat"

  print_ok "Handoff context: $context_file"
  echo ""
  echo "  1. Paste into the **current** chat (agent saves state):"
  echo "     cat $context_file"
  echo ""
  echo "  2. Confirm progress.md has [CHECKPOINT]"
  echo ""
  echo "  3. Close this chat. Open a **new** agent and run:"
  echo "     rig-spec resume"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_validate
# ─────────────────────────────────────────────

cmd_validate() {
  require_rig
  local task_id="$1"

  # Fall back to the task saved by `rig-spec run`
  if [ -z "$task_id" ] && [ -f "$RIG_DIR/.current-task" ]; then
    task_id=$(cat "$RIG_DIR/.current-task")
  fi

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
    local _find_rc=0
    task_file=$(find_task_file "$task_id") || _find_rc=$?
    if [ "$_find_rc" -eq 2 ]; then
      exit 1
    fi
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
  local config_file="$RIG_DIR/feedback/sensors.config.yaml"

  if [ -z "$sensor_files" ] && [ ! -f "$config_file" ]; then
    print_warn "No sensors configured."
    echo ""
    echo "  Option A — add one-liner commands to .rig/feedback/sensors.config.yaml:"
    echo "    lint: npm run lint"
    echo "    test: npm test"
    echo ""
    echo "  Option B — create a full sensor file:"
    echo "    .rig/feedback/sensors/<name>.sensor.md (see _TEMPLATE.sensor.md)"
    echo ""
    return 0
  fi

  local passed=0
  local failed=0
  local skipped=0
  local review_pending=0
  local errors=()
  local -a report_rows=()

  # --- sensors.config.yaml: shorthand one-liner sensors ---
  if [ -f "$config_file" ]; then
    while IFS= read -r line; do
      line="${line%%#*}"   # strip inline comments
      line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -z "$line" ] && continue

      local cfg_name cfg_cmd
      cfg_name="${line%%:*}"
      cfg_cmd="${line#*: }"
      cfg_name="$(echo "$cfg_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      cfg_cmd="$(echo "$cfg_cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -z "$cfg_name" ] || [ -z "$cfg_cmd" ] && continue

      # .sensor.md with same name takes priority — skip the config entry
      [ -f "$sensors_dir/${cfg_name}.sensor.md" ] && continue

      echo -ne "  Running ${BOLD}${cfg_name}${RESET}... "
      if eval "$cfg_cmd" > /tmp/rig-sensor-output 2>&1; then
        echo -e "${GREEN}PASS${RESET}"
        report_rows+=("| ${cfg_name} | PASS | config |")
        ((passed++)) || true
      else
        echo -e "${RED}FAIL${RESET}"
        report_rows+=("| ${cfg_name} | FAIL | config |")
        ((failed++)) || true
        errors+=("$cfg_name")
        echo ""
        echo -e "  ${DIM}Output:${RESET}"
        head -20 /tmp/rig-sensor-output | while IFS= read -r l; do echo "    $l"; done
        echo ""
      fi
    done < "$config_file"
  fi

  # --- .sensor.md files ---
  while IFS= read -r sensor_file; do
    [ -z "$sensor_file" ] && continue
    local sensor_name
    sensor_name=$(basename "$sensor_file" .sensor.md)
    local cmd
    cmd=$(extract_command "$sensor_file")

    if [ -z "$cmd" ]; then
      print_warn "$sensor_name — no command found in sensor file"
      report_rows+=("| $sensor_name | SKIP | no command |")
      ((skipped++)) || true
      continue
    fi

    if echo "$cmd" | grep -q 'SKIP:'; then
      print_warn "$sensor_name — skipped (configure sensor command)"
      report_rows+=("| $sensor_name | SKIP | not configured |")
      ((skipped++)) || true
      continue
    fi

    if sensor_is_inferential "$cmd"; then
      echo -e "  ${BOLD}$sensor_name${RESET} ... ${YELLOW}REVIEW${RESET} (inferential — use review agent)"
      report_rows+=("| $sensor_name | REVIEW | inferential |")
      ((review_pending++)) || true
      continue
    fi

    echo -ne "  Running ${BOLD}$sensor_name${RESET}... "
    if eval "$cmd" > /tmp/rig-sensor-output 2>&1; then
      echo -e "${GREEN}PASS${RESET}"
      report_rows+=("| $sensor_name | PASS | computational |")
      ((passed++)) || true
    else
      echo -e "${RED}FAIL${RESET}"
      report_rows+=("| $sensor_name | FAIL | computational |")
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

  # Validation report artifact
  mkdir -p "$RIG_DIR/feedback/reports"
  local report_slug="${task_id:-all}-$(today)"
  local report_file="$RIG_DIR/feedback/reports/validation-${report_slug}.md"
  {
    echo "# Validation Report — ${task_id:-all tasks}"
    echo ""
    echo "**Date:** $(today)"
    echo "**Computational:** $passed passed, $failed failed, $skipped skipped"
    echo "**Inferential:** $review_pending pending review"
    echo ""
    echo "## Sensor matrix"
    echo ""
    echo "| Sensor | Result | Type |"
    echo "|---|---|---|"
    for row in "${report_rows[@]}"; do
      echo "$row"
    done
    echo ""
    if [ -n "$task_file" ] && grep -q "^## Contract" "$task_file" 2>/dev/null; then
      echo "## Contract checklist"
      echo ""
      awk '/^## Contract/{p=1; next} p && /^---/{exit} p && /^- \[/{print}' "$task_file"
      echo ""
    fi
    echo "## Review required (always)"
    echo ""
    echo "Run a **review agent** with these files:"
    echo "- \`feedback/review/code-review.review.md\`"
    echo "- \`feedback/review/validation-matrix.review.md\`"
    echo "- \`STANDARDS.md\` + applicable \`feedforward/rules/\`"
    if [ -n "$task_file" ]; then
      echo "- Task: \`$task_file\`"
    fi
    echo ""
    echo "Fill the matrix in \`validation-matrix.review.md\` and set **Overall: PASS | FAIL**."
    echo ""
    if [ "$failed" -gt 0 ]; then
      echo "## Overall: FAIL (computational sensors)"
    elif [ "$review_pending" -gt 0 ]; then
      echo "## Overall: PENDING REVIEW (computational OK — complete inferential review)"
    else
      echo "## Overall: PASS (computational only — confirm review)"
    fi
  } > "$report_file"

  echo ""
  echo -e "  ${BOLD}Report:${RESET} $report_file"
  echo ""

  if [ "$failed" -eq 0 ]; then
    if [ "$review_pending" -gt 0 ]; then
      echo -e "  ${GREEN}${BOLD}Computational sensors passed${RESET} ($passed run, $review_pending need review)"
    else
      echo -e "  ${GREEN}${BOLD}All computational sensors passed${RESET} ($passed/$((passed+failed)))"
    fi
    echo ""
    echo -e "  ${BOLD}Next:${RESET} Run review agent using files listed in the validation report."

    # Auto-update progress.md Last Session
    local session_summary="All sensors passed ($passed sensors)."
    local next_step="Run: rig-spec done $task_id"
    [ -z "$task_id" ] && next_step="Mark tasks complete with: rig-spec done <task-id>"
    patch_progress_last_session "$session_summary" "$next_step"

    echo ""
    if [ -n "$task_id" ]; then
      echo -e "  ${DIM}progress.md Last Session updated.${RESET}"
      echo ""
      read -r -p "  Mark $task_id as done? [Y/n] " _resp
      if [[ ! "$_resp" =~ ^[Nn]$ ]]; then
        cmd_done "$task_id"
      fi
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
    echo "  Examples:"
    echo "    rig-spec run 01-data-layer"
    echo "    rig-spec run allow-multiple-consultations/01-data-layer"
    echo ""
    echo "  If two features have similar task names, use feature/fragment."
    echo ""
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec run — $task_id${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  # Find the task file
  local task_file
  if ! task_file=$(find_task_file_or_fail "$task_id"); then
    print_err "Task not found: $task_id"
    echo ""
    echo "  Available tasks (use feature/fragment when names collide):"
    find "$RIG_DIR/feedforward/tasks" -name "*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | sort | \
      while IFS= read -r f; do
        local feat base short
        feat=$(basename "$(dirname "$f")")
        base=$(basename "$f" .task.md)
        short="$base"
        if [[ "$base" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
          short=$(echo "$base" | sed -E 's/^[0-9]{8}-[0-9]{6}-//')
        fi
        echo "    rig-spec run ${feat}/${short}"
        echo "      → $(basename "$f")"
      done
    echo ""
    exit 1
  fi

  local task_basename feature_dir task_short_id
  task_basename=$(basename "$task_file" .task.md)
  feature_dir=$(basename "$(dirname "$task_file")")
  task_short_id="$task_basename"
  if [[ "$task_basename" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
    task_short_id=$(echo "$task_basename" | sed -E 's/^[0-9]{8}-[0-9]{6}-//')
  fi
  print_ok "Task found: $task_file"
  echo -e "  ${DIM}Qualified id: ${feature_dir}/${task_short_id}${RESET}"

  # Dependency check — warn if any declared dependency is not done in progress.md
  local progress_file="$RIG_DIR/memory/progress.md"
  if [ -f "$progress_file" ]; then
    local dep_warnings=()
    while IFS= read -r dep_line; do
      dep_line="$(echo "$dep_line" | sed 's/^[[:space:]]*-[[:space:]]*//')"
      [ -z "$dep_line" ] && continue
      # Extract a task id fragment from the dependency line (first word-like slug after "Task" or at start)
      local dep_slug
      dep_slug=$(echo "$dep_line" | grep -oE '[0-9]{8}-[0-9]{6}-[0-9]+-[a-z0-9-]+|[0-9]+-[a-z0-9-]+' | head -1)
      [ -z "$dep_slug" ] && continue
      # Consider done if progress.md has [x] on a line containing the slug
      if ! grep -qE "^\- \[x\].*${dep_slug}" "$progress_file" 2>/dev/null; then
        dep_warnings+=("$dep_slug")
      fi
    done < <(awk '/^## Dependencies/{p=1;next} p && /^## /{exit} p && /^-/{print}' "$task_file" 2>/dev/null)

    if [ ${#dep_warnings[@]} -gt 0 ]; then
      echo ""
      echo -e "  ${YELLOW}⚠  Dependency warning:${RESET}"
      for w in "${dep_warnings[@]}"; do
        echo -e "  ${YELLOW}   Not done in progress.md: $w${RESET}"
      done
      echo -e "  ${DIM}   Run dependant tasks first, or override if this is intentional.${RESET}"
      echo ""
    fi
  fi

  # Find spec reference
  local spec_ref
  spec_ref=$(grep "→ \`feedforward/specs/" "$task_file" 2>/dev/null | head -1 | sed "s/.*\`\(.*\)\`.*/\1/")
  local spec_file=""
  if [ -n "$spec_ref" ]; then
    spec_file="$RIG_DIR/$spec_ref"
    [ ! -f "$spec_file" ] && spec_file=""
  fi

  # Resolve skills: registry auto-match + explicit task list
  local skills_content=""
  local skill_ref skill_path
  while IFS= read -r skill_ref; do
    [ -z "$skill_ref" ] && continue
    if [[ "$skill_ref" == feedforward/* ]]; then
      skill_path="$RIG_DIR/$skill_ref"
    elif [[ "$skill_ref" == "~/"* ]]; then
      skill_path="${skill_ref/#\~/$HOME}"
    elif [[ "$skill_ref" == /* ]]; then
      skill_path="$skill_ref"
    else
      continue
    fi
    if [ -f "$skill_path" ] && [[ "$skill_ref" != *"_TEMPLATE.skill.md" ]]; then
      skills_content+="# Skill: $skill_ref"$'\n\n'
      skills_content+=$(cat "$skill_path")
      skills_content+=$'\n\n---\n\n'
    fi
  done < <(resolve_skills_for_task "$task_file")

  # Assemble context (basename avoids collisions when task_id is a short fragment)
  local context_file="$RIG_DIR/context-${task_basename}.md"
  {
    session_continuity_block
    echo ""
    echo "---"
    echo ""
    echo "# Agent Context — $task_basename"
    echo ""
    echo "> Assembled by rig-spec run. Read everything below before writing any code."
    echo "> If this chat gets long: \`rig-spec handoff\` → new chat → \`rig-spec resume\`."
    echo ""
    echo "---"
    echo ""

    if [ -f "$RIG_DIR/STANDARDS.md" ]; then
      echo "## Standards Index (read first)"
      echo ""
      cat "$RIG_DIR/STANDARDS.md"
      echo ""
      echo "---"
      echo ""
    fi

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

    if [ -f "$RIG_DIR/memory/learnings.md" ]; then
      echo "## Implementation Learnings"
      echo ""
      cat "$RIG_DIR/memory/learnings.md"
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
    echo "- Run sensors during implementation as a self-repair pre-check"
    echo "- The validator — not you — declares the task done"
    echo "- Record discoveries in memory/learnings.md before handoff"
    echo ""
    echo "PROGRESS UPDATE — after completing EACH contract item (mandatory):"
    echo "1. Check the box in the task file:  - [x] item"
    echo "2. Update memory/progress.md — add or update the sub-item list under the [~] task:"
    echo ""
    echo "   - [~] $task_id: in-progress"
    echo "     - [x] contract item just completed"
    echo "     - [ ] next contract item  ← next"
    echo ""
    echo "This is not optional. It is the mechanism that lets the next agent continue"
    echo "from exactly where you stopped — without re-reading the whole task."
    echo ""
    echo "After implementation, human runs: rig-spec validate $task_id"
    echo ""
    echo "If you cannot finish (context too full or task too large):"
    echo "1. Update memory/progress.md with the sub-item list showing exactly where you stopped"
    echo "2. Leave unfinished contract items unchecked"
    echo "3. End with: CHECKPOINT SAVED — run rig-spec resume to continue"
    echo ""
  } > "$context_file"

  # Save current task so validate/done can pick it up without repeating the id
  echo "$task_basename" > "$RIG_DIR/.current-task"

  # Mark task as in-progress in progress.md
  patch_progress_task_inprogress "$task_id"
  patch_progress_last_session "Started $task_id." "Implement, then run: rig-spec validate"

  print_ok "Context assembled: $context_file"
  print_ok "progress.md → $task_id marked in progress"
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
  echo -e "  ${BOLD}2. After the agent responds:${RESET}"
  echo "     Copy the agent's output and save it to:"
  echo "     $research_file"
  echo ""
  echo -e "  ${DIM}(Claude Code / Cursor: the agent will write the file directly)${RESET}"
  echo -e "  ${DIM}(Chat / Gemini / ChatGPT: copy the response and paste into the file)${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_done
# ─────────────────────────────────────────────

cmd_done() {
  require_rig
  local task_id="$1"

  if [ -z "$task_id" ]; then
    echo ""
    print_err "Usage: rig-spec done <task-id>"
    echo ""
    echo "  Example: rig-spec done task-01"
    echo ""
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec done — $task_id${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  local progress="$RIG_DIR/memory/progress.md"
  local harness="$RIG_DIR/HARNESS.md"

  # Find which feature/spec this task belongs to
  local task_file
  if ! task_file=$(find_task_file_or_fail "$task_id"); then
    print_err "Task not found: $task_id"
    exit 1
  fi
  local feature=""
  if [ -n "$task_file" ]; then
    feature=$(basename "$(dirname "$task_file")")
    print_ok "Task found: $task_file"
  else
    print_warn "Task file not found for '$task_id' — updating progress without task reference"
  fi

  # Find next pending task in same feature (lexicographic = chronological when timestamp-prefixed)
  local next_task="none"
  if [ -n "$feature" ] && [ -n "$task_file" ]; then
    local task_dir="$RIG_DIR/feedforward/tasks/$feature"
    local sorted found_next=false
    sorted=$(find "$task_dir" -name "*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)
    while IFS= read -r f; do
      if $found_next; then
        next_task=$(basename "$f" .task.md)
        break
      fi
      [ "$f" = "$task_file" ] && found_next=true
    done <<< "$sorted"
    [ "$next_task" = "none" ] && next_task="none — all tasks complete"
  fi

  # Update progress.md
  patch_progress_task_done "$task_id" "$feature"
  patch_progress_last_session \
    "Completed and marked $task_id as done." \
    "${next_task:-none}"
  print_ok "progress.md updated"

  # Update HARNESS.md next task
  if [ -n "$feature" ]; then
    patch_harness_focus "$feature" "$next_task"
    print_ok "HARNESS.md Next Task updated → $next_task"
  fi

  # Clear current-task marker so validate doesn't pick up the completed task
  rm -f "$RIG_DIR/.current-task"

  # Count total and done tasks for this feature
  local total_tasks=0 done_tasks=0
  if [ -n "$feature" ]; then
    total_tasks=$(find "$RIG_DIR/feedforward/tasks/$feature" -name "*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | wc -l | tr -d ' ')
    done_tasks=$(grep -c "^\- \[x\].*${feature}" "$RIG_DIR/memory/progress.md" 2>/dev/null || true)
    # fallback: count [x] lines in progress for this feature section
    [ "$done_tasks" -eq 0 ] && done_tasks=$(grep -c "^\- \[x\]" "$RIG_DIR/memory/progress.md" 2>/dev/null || echo 0)
  fi

  echo ""
  echo -e "  ${GREEN}${BOLD}✓ $task_id marked done${RESET}"
  [ "$total_tasks" -gt 0 ] && echo -e "  ${DIM}Progress: $done_tasks/$total_tasks tasks complete in '$feature'${RESET}"

  # Git commit suggestion
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local changed
    changed=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
    if [ "$changed" -gt 0 ]; then
      echo ""
      echo -e "  ${DIM}──────────────────────────────────────${RESET}"
      echo -e "  ${BOLD}Commit this task:${RESET}"
      echo ""
      echo -e "  ${DIM}git add -p${RESET}"
      if [ -n "$feature" ]; then
        echo -e "  ${DIM}git commit -m \"feat($feature): $task_id — [summary]\"${RESET}"
      else
        echo -e "  ${DIM}git commit -m \"feat: $task_id — [summary]\"${RESET}"
      fi
    fi
  fi

  if [ "$next_task" != "none" ] && [ "$next_task" != "none — all tasks complete" ]; then
    echo ""
    echo -e "  ${BOLD}Next task:${RESET} $next_task"
    echo ""
    echo -e "  ${BOLD}rig-spec run $next_task${RESET}"
  else
    echo ""
    echo -e "  ${GREEN}${BOLD}All tasks in '$feature' are complete.${RESET}"
    echo ""
    echo "  Run: rig-spec validate    # full final check"
    echo "  Run: rig-spec audit       # drift report"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# cmd_overview
# ─────────────────────────────────────────────

cmd_overview() {
  require_rig

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec overview${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"

  local harness="$RIG_DIR/HARNESS.md"
  local progress="$RIG_DIR/memory/progress.md"

  if [ ! -f "$harness" ]; then
    print_err "HARNESS.md not found."; echo ""; exit 1
  fi

  echo ""

  # ── Project block ──────────────────────────
  echo -e "${BOLD}Project${RESET}"
  awk '/^## Project/{p=1; next} p && /^---/{exit} p && NF{print "  " $0}' "$harness"
  echo ""

  # ── Vision block ──────────────────────────
  if grep -q "^## Vision" "$harness"; then
    echo -e "${BOLD}Vision${RESET}"
    awk '/^## Vision/{p=1; next} p && /^---/{exit} p && NF{print "  " $0}' "$harness"
    echo ""
  fi

  # ── Business Rules block ──────────────────
  if grep -q "^## Business Rules" "$harness"; then
    echo -e "${BOLD}Business Rules${RESET}"
    awk '/^## Business Rules/{p=1; next} p && /^---/{exit} p && /^>/{next} p && NF{print "  " $0}' "$harness"
    echo ""
  fi

  # ── Current Focus ─────────────────────────
  if grep -q "^## Current Focus" "$harness"; then
    echo -e "${BOLD}Current Focus${RESET}"
    awk '/^## Current Focus/{p=1; next} p && /^---/{exit} p && NF{print "  " $0}' "$harness"
    echo ""
  fi

  # ── Sensors / Level ───────────────────────
  local level
  level=$(grep "^\*\*Active Level:" "$harness" 2>/dev/null | sed 's/\*\*Active Level: *\([0-9]\).*/\1/')
  local sensor_count=0
  if [ -d "$RIG_DIR/feedback/sensors" ]; then
    sensor_count=$(find "$RIG_DIR/feedback/sensors" -name "*.sensor.md" ! -name "_TEMPLATE*" 2>/dev/null | wc -l | tr -d ' ')
  fi
  local spec_count=0
  if [ -d "$RIG_DIR/feedforward/specs" ]; then
    spec_count=$(find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo -e "${BOLD}Harness State${RESET}"
  [ -n "$level" ] && echo -e "  Level: $level"
  echo -e "  Specs: $spec_count"
  echo -e "  Sensors: $sensor_count"
  echo ""

  # ── Last session summary ──────────────────
  if [ -f "$progress" ] && grep -q "^## Last Session" "$progress"; then
    echo -e "${BOLD}Last Session${RESET}"
    awk '/^## Last Session/{p=1; next} p && /^---/{exit} p && NF{print "  " $0}' "$progress"
    echo ""
  fi

  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Edit vision and rules: $harness${RESET}"
  echo -e "  ${DIM}Create a spec: rig-spec shape \"feature name\"${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_shape
# ─────────────────────────────────────────────

cmd_shape() {
  require_rig
  local feature=""
  local from_file=""
  local phase="discover"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from)     from_file="$2"; shift 2 ;;
      --complete) phase="complete"; shift ;;
      *)          feature="${feature:+$feature }$1"; shift ;;
    esac
  done

  if [ -z "$feature" ]; then
    echo ""
    print_err "Usage: rig-spec shape <feature-name> [--from <file>] [--complete]"
    echo ""
    echo "  Phase 1 (default): CLI questions + agent asks clarifying questions (no full spec yet)"
    echo "  Phase 2: rig-spec shape <feature> --complete  (after saving Q&A from the agent)"
    echo ""
    exit 1
  fi

  local slug
  slug=$(shape_slugify "$feature")
  local qa_file
  qa_file=$(shape_qa_path "$feature")

  # Phase 2: resolve spec file from Q&A stored path, then fall back to find_spec_file
  if [ "$phase" = "complete" ]; then
    local spec_file=""
    if [ -f "$qa_file" ]; then
      local stored_path
      stored_path=$(grep '^<!-- spec-file:' "$qa_file" 2>/dev/null | sed 's/<!-- spec-file: //;s/ -->//' | tr -d ' ')
      [ -n "$stored_path" ] && [ -f "$RIG_DIR/$stored_path" ] && spec_file="$RIG_DIR/$stored_path"
    fi
    if [ -z "$spec_file" ]; then
      spec_file=$(find_spec_file "$slug") || spec_file="$RIG_DIR/feedforward/specs/${slug}.spec.md"
    fi
    cmd_shape_complete "$feature" "$slug" "$spec_file" "$qa_file" "$from_file"
    return
  fi

  # Phase 1: generate timestamped spec file
  local spec_ts
  spec_ts=$(task_ts_prefix)
  local spec_file="$RIG_DIR/feedforward/specs/${spec_ts}-${slug}.spec.md"

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec shape — $feature${RESET} ${DIM}(phase 1: discover)${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Answer in the terminal first, then the AI agent will ask MORE questions before writing the spec.${RESET}"
  echo -e "  ${DIM}Press Enter to skip only if you will answer in the agent chat.${RESET}"
  echo ""

  # ── Interactive questions (CLI) ──────────────────
  echo -e "  ${BOLD}1. What problem does this solve?${RESET}"
  read -r -p "  → " q_problem
  echo ""

  echo -e "  ${BOLD}2. Who are the users?${RESET}"
  read -r -p "  → " q_users
  echo ""

  echo -e "  ${BOLD}3. What is the main goal?${RESET}"
  read -r -p "  → " q_goal
  echo ""

  echo -e "  ${BOLD}4. What is explicitly out of scope?${RESET}"
  read -r -p "  → " q_out_of_scope
  echo ""

  echo -e "  ${BOLD}5. Constraints or design decisions?${RESET}"
  read -r -p "  → " q_constraints
  echo ""

  echo -e "  ${BOLD}6. Main user flows (happy path)?${RESET}"
  read -r -p "  → " q_flows
  echo ""

  echo -e "  ${BOLD}7. Edge cases, errors, or permissions to consider?${RESET}"
  read -r -p "  → " q_edge
  echo ""

  echo -e "  ${BOLD}8. How will we know it is done (measurable)?${RESET}"
  read -r -p "  → " q_success
  echo ""

  if [ -z "$q_problem" ] && [ -z "$q_goal" ]; then
    print_warn "Problem and goal are empty — the agent MUST ask clarifying questions in chat."
    echo ""
  fi

  # ── Create draft spec file (CLI answers only) ──────────────────────
  mkdir -p "$(dirname "$qa_file")"

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
  [ -n "$q_flows" ]   && design_content="${design_content}"$'\n\n'"**Flows (CLI):** $q_flows"
  [ -n "$q_edge" ]    && design_content="${design_content}"$'\n\n'"**Edge cases (CLI):** $q_edge"
  [ -n "$q_success" ] && design_content="${design_content}"$'\n\n'"**Success metrics (CLI):** $q_success"

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

  # Auto-update HARNESS.md and progress.md
  patch_harness_focus "$slug" "none — run rig-spec plan $slug"
  patch_progress_add_feature "$feature" "feedforward/specs/${slug}.spec.md"
  patch_progress_last_session \
    "Spec draft for '$feature' via rig-spec shape (phase 1)." \
    "Answer agent questions → save to $qa_file → rig-spec shape \"$feature\" --complete"
  print_ok "HARNESS.md and progress.md updated"
  echo ""

  # Q&A file template (human + agent fill before --complete)
  if [ ! -f "$qa_file" ]; then
    cat > "$qa_file" << EOF
<!-- spec-file: feedforward/specs/${spec_ts}-${slug}.spec.md -->
# Shape Q&A: $feature

> Phase 1: paste the agent's clarifying questions below, then your answers.
> Phase 2: run \`rig-spec shape "$feature" --complete\` after this file is filled.

## Agent questions (paste from chat)

1.
2.
3.

## Human answers

1.
2.
3.

## Additional notes

EOF
    print_ok "Q&A template: $qa_file"
  fi

  # ── Assemble agent context (phase 1: questions only) ─────────────────
  local context_file="$RIG_DIR/context-shape-${slug}.md"
  {
    echo "# Shape spec (phase 1 — discover): $feature"
    echo ""
    echo "> **STOP — read before acting.**"
    echo "> This is **phase 1**. Your ONLY job is to ask clarifying questions."
    echo "> Do **NOT** write or rewrite the spec file. Do **NOT** use \`## File:\` blocks."
    echo "> The human will answer in chat, save Q&A to \`$qa_file\`, then run \`rig-spec shape \"$feature\" --complete\`."
    echo ""
    echo "---"
    echo ""
    echo "## Project Context"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""

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

    echo "## What the Human Already Defined (CLI)"
    echo ""
    echo "**Feature:** $feature"
    [ -n "$q_problem" ]      && echo "**Problem:** $q_problem"
    [ -n "$q_goal" ]         && echo "**Goal:** $q_goal"
    [ -n "$q_users" ]        && echo "**Users:** $q_users"
    [ -n "$q_out_of_scope" ] && echo "**Out of scope:** $q_out_of_scope"
    [ -n "$q_constraints" ]  && echo "**Constraints:** $q_constraints"
    [ -n "$q_flows" ]        && echo "**Flows:** $q_flows"
    [ -n "$q_edge" ]         && echo "**Edge cases:** $q_edge"
    [ -n "$q_success" ]      && echo "**Success metrics:** $q_success"
    echo ""
    echo "---"
    echo ""
    echo "## Draft Spec (for context only — do not expand yet)"
    echo ""
    cat "$spec_file"
    echo ""
    echo "---"
    echo ""
    echo "## Your Instructions (phase 1)"
    echo ""
    echo "Ask **8–12 numbered clarifying questions** before any spec writing."
    echo ""
    echo "Cover gaps in:"
    echo "- Scope boundaries and explicit non-goals"
    echo "- User roles and permissions"
    echo "- Main flows and alternate/error paths"
    echo "- Data model / persistence / external APIs"
    echo "- Non-functional requirements (performance, security, audit)"
    echo "- Integration with existing code in this repo"
    echo "- Acceptance criteria the human cares about most"
    echo "- Risks, unknowns, and decisions that need a human call"
    echo ""
    echo "Rules:"
    echo "- Reference what the human already said; do not repeat it as a question"
    echo "- If CLI answers were empty or vague, say so and ask targeted follow-ups"
    echo "- Prefer concrete questions (\"Should X happen when Y?\") over generic ones"
    echo "- End with: \"Save your answers to \`$qa_file\` then run \`rig-spec shape \\\"$feature\\\" --complete\`\""
    echo ""
    echo "**Forbidden in this phase:**"
    echo "- Writing user stories, acceptance criteria, or fixtures"
    echo "- Outputting \`## File:\` or full markdown spec content"
    echo "- Assuming answers — ask instead"

  } > "$context_file"

  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Next steps (two phases):${RESET}"
  echo ""
  echo "  1. Paste into your AI agent:"
  echo "     cat $context_file"
  echo ""
  echo "  2. Answer the agent's questions in chat; copy Q&A into:"
  echo "     $qa_file"
  echo ""
  echo "  3. Generate the full spec:"
  echo "     rig-spec shape \"$feature\" --complete"
  echo ""
  echo -e "  ${DIM}Draft spec (CLI only): $spec_file${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_shape_complete — phase 2: write full spec
# ─────────────────────────────────────────────

cmd_shape_complete() {
  local feature="$1"
  local slug="$2"
  local spec_file="$3"
  local qa_file="$4"
  local from_file="$5"

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec shape — $feature${RESET} ${DIM}(phase 2: complete)${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  if [ ! -f "$qa_file" ]; then
    print_warn "Q&A file not found: $qa_file"
    echo "  Run phase 1 first: rig-spec shape \"$feature\""
    echo "  Or create the file with agent questions + your answers."
    echo ""
    read -r -p "  Continue without Q&A? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  local context_file="$RIG_DIR/context-shape-${slug}-complete.md"
  {
    echo "# Complete spec (phase 2): $feature"
    echo ""
    echo "> Q&A is done. Write the **full** spec to \`$spec_file\`."
    echo ""
    echo "---"
    echo ""
    echo "## Project Context"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""

    if [ -f "$qa_file" ]; then
      echo "## Shape Q&A (human + agent)"
      echo ""
      cat "$qa_file"
      echo ""
      echo "---"
      echo ""
    fi

    if [ -n "$from_file" ] && [ -f "$from_file" ]; then
      echo "## Input Document"
      echo ""
      cat "$from_file"
      echo ""
      echo "---"
      echo ""
    fi

    if [ -f "$spec_file" ]; then
      echo "## Current Draft Spec"
      echo ""
      cat "$spec_file"
      echo ""
      echo "---"
      echo ""
    fi

    echo "## Your Instructions (phase 2)"
    echo ""
    echo "Produce the complete spec using rig-spec format."
    echo ""
    echo "**User Stories** — 2-4, from Q&A and project context"
    echo "**Acceptance Criteria** — 3-6, specific and testable"
    echo "**Approved Fixtures** — leave placeholder: \`[Human must fill this]\` — do NOT invent outputs"
    echo "**Out of Scope** — only what Q&A/human confirmed; flag extras as open questions"
    echo ""
    # Extract timestamp from draft spec filename (YYYYMMDD-HHMMSS-slug.spec.md)
    local spec_ts=""
    local spec_basename
    spec_basename=$(basename "$spec_file" .spec.md)
    if [[ "$spec_basename" =~ ^([0-9]{8}-[0-9]{6})- ]]; then
      spec_ts="${BASH_REMATCH[1]}"
    fi

    local specs_dir="$RIG_DIR/feedforward/specs"
    local naming_instruction=""
    if [ -n "$spec_ts" ]; then
      naming_instruction="${spec_ts}-your-canonical-slug"
    else
      naming_instruction="your-canonical-slug"
    fi

    echo "**Output format — required:**"
    echo ""
    echo "Step 1 — choose a canonical kebab-case slug for this spec (e.g. 'user-auth', 'payment-flow')."
    echo "The slug must be short, lowercase, and describe the feature precisely."
    echo ""
    echo "Step 2 — output the full spec using this exact format:"
    echo ""
    echo "  ## File: $specs_dir/${naming_instruction}.spec.md"
    echo "  \`\`\`markdown"
    echo "  [full spec content]"
    echo "  \`\`\`"
    echo ""
    if [ -n "$spec_ts" ]; then
      echo "Keep the timestamp prefix ${spec_ts} in the filename — only replace 'your-canonical-slug'."
      echo "If the draft name '${spec_basename}' is already canonical, keep it."
    fi
    echo ""
    echo "Preserve all section headers. After the block, list any remaining open questions."

  } > "$context_file"

  patch_harness_focus "$slug" "none — run rig-spec plan after spec is finalized"
  patch_progress_last_session \
    "Shape phase 2 context for '$feature'." \
    "Paste context → agent names + writes spec → fill Approved Fixtures → rig-spec plan <spec-slug>"

  print_ok "Context assembled: $context_file"
  echo ""
  echo "  Paste into your AI agent:"
  echo "    cat $context_file"
  echo ""
  echo "  The agent will name and write the final spec to: $specs_dir/"
  echo "  Next: rig-spec plan <slug-chosen-by-agent>"
  echo ""
}

# ─────────────────────────────────────────────
# run_sensor_smoketest
# Verifies that sensor commands are executable.
# Called after plan to catch misconfigured sensors before any implementation.
# ─────────────────────────────────────────────

run_sensor_smoketest() {
  local sensors_dir="$RIG_DIR/feedback/sensors"
  local sensor_files
  sensor_files=$(find "$sensors_dir" -name "*.sensor.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)

  echo ""
  echo -e "${BOLD}${CYAN}Sensor smoke test${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo -e "  ${DIM}Verifying sensor commands are correctly configured before implementation starts.${RESET}"
  echo ""

  if [ -z "$sensor_files" ]; then
    print_warn "No sensors found in $sensors_dir"
    echo ""
    echo -e "  ${DIM}Add sensor files from the agent response above, then run:${RESET}"
    echo -e "  ${DIM}  rig-spec validate${RESET}"
    echo ""
    return 0
  fi

  local ok=0
  local bad=0
  local bad_sensors=()

  while IFS= read -r sensor_file; do
    local sensor_name
    sensor_name=$(basename "$sensor_file" .sensor.md)
    local cmd
    cmd=$(extract_command "$sensor_file")

    if [ -z "$cmd" ]; then
      echo -e "  ${YELLOW}SKIP${RESET}  $sensor_name — no ## Command block found"
      continue
    fi

    # Check the first token of the command exists in PATH
    local binary
    binary=$(echo "$cmd" | awk '{print $1}')
    if ! command -v "$binary" &>/dev/null 2>&1; then
      echo -e "  ${RED}ERR ${RESET}  ${BOLD}$sensor_name${RESET} — command not found: $binary"
      ((bad++)) || true
      bad_sensors+=("$sensor_name")
    else
      echo -e "  ${GREEN}OK  ${RESET}  ${BOLD}$sensor_name${RESET} — $binary found"
      ((ok++)) || true
    fi
  done <<< "$sensor_files"

  echo ""
  if [ "$bad" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}$ok sensor(s) ready.${RESET} Run ${BOLD}rig-spec validate${RESET} after each task."
  else
    echo -e "  ${RED}${BOLD}$bad sensor(s) misconfigured:${RESET} ${bad_sensors[*]}"
    echo ""
    echo "  Fix the ## Command in each sensor file before running tasks."
    echo "  Sensor files are in: $sensors_dir/"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# cmd_plan
# ─────────────────────────────────────────────

cmd_plan() {
  require_rig
  local spec_name=""
  local phase="discover"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --complete) phase="complete"; shift ;;
      --lite)     phase="lite";     shift ;;
      *)          spec_name="$1"; shift ;;
    esac
  done

  if [ -z "$spec_name" ]; then
    echo ""
    print_err "Usage: rig-spec plan <spec-name> [--complete|--lite]"
    echo ""
    echo "  Phase 1 (default): agent asks planning questions before creating tasks"
    echo "  Phase 2: rig-spec plan <spec-name> --complete  (after saving Q&A)"
    echo "  Lite:    rig-spec plan <spec-name> --lite      (skip Q&A, generate tasks directly)"
    echo ""
    echo "  Available specs:"
    find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | \
      while IFS= read -r f; do echo "    $(basename "$f" .spec.md)"; done
    echo ""
    exit 1
  fi

  # Normalize: strip extension and timestamp prefix for slug lookup
  spec_name=$(basename "$spec_name" .spec.md)
  spec_name=$(echo "$spec_name" | sed -E 's/^[0-9]{8}-[0-9]{6}-//')

  local spec_file
  if ! spec_file=$(find_spec_file "$spec_name"); then
    print_err "Spec not found for: $spec_name"
    echo ""
    echo "  rig-spec plan runs AFTER the spec exists. Create it first:"
    echo ""
    echo "    rig-spec shape \"$spec_name\""
    echo ""
    echo "  Then edit the spec (acceptance criteria, fixtures), then:"
    echo ""
    echo "    rig-spec plan $spec_name"
    echo ""
    local available
    available=$(find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)
    if [ -n "$available" ]; then
      echo "  Specs in this project:"
      while IFS= read -r f; do
        local fname
        fname=$(basename "$f" .spec.md)
        fname=$(echo "$fname" | sed -E 's/^[0-9]{8}-[0-9]{6}-//')
        echo "    $fname"
      done <<< "$available"
      echo ""
    fi
    exit 1
  fi

  # Use the slug without timestamp for the tasks directory
  local tasks_dir="$RIG_DIR/feedforward/tasks/${spec_name}"
  mkdir -p "$tasks_dir"

  local qa_file
  qa_file=$(plan_qa_path "$spec_name")

  if [ "$phase" = "complete" ]; then
    cmd_plan_complete "$spec_name" "$spec_file" "$tasks_dir" "$qa_file"
    return
  fi

  if [ "$phase" = "lite" ]; then
    cmd_plan_lite "$spec_name" "$spec_file" "$tasks_dir"
    return
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec plan — $spec_name${RESET} ${DIM}(phase 1: discover)${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  if [ ! -f "$qa_file" ]; then
    cat > "$qa_file" << EOF
# Plan Q&A: $spec_name

> Phase 1: paste the agent's planning questions below, then your answers.
> Phase 2: run \`rig-spec plan $spec_name --complete\` after this file is filled.

## Agent questions (paste from chat)

1.
2.
3.

## Human answers

1.
2.
3.

## Task breakdown notes (optional)

- Suggested order:
- Parallel work:
- Risks:

EOF
    print_ok "Q&A template: $qa_file"
  fi

  local context_file="$RIG_DIR/context-plan-${spec_name}.md"
  {
    echo "# Plan tasks (phase 1 — discover): $spec_name"
    echo ""
    echo "> **STOP — read before acting.**"
    echo "> This is **phase 1**. Your ONLY job is to ask planning questions."
    echo "> Do **NOT** create task or sensor files. Do **NOT** use \`## File:\` blocks."
    echo "> Human saves Q&A to \`$qa_file\`, then runs \`rig-spec plan $spec_name --complete\`."
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
    echo "## Your Instructions (phase 1)"
    echo ""
    echo "Ask **6–10 numbered questions** before breaking the spec into tasks."
    echo ""
    echo "Cover:"
    echo "- Proposed task boundaries and execution order"
    echo "- What can run in parallel vs must be sequential"
    echo "- File ownership / areas of the codebase touched"
    echo "- Testing strategy per area (unit, integration, e2e, manual)"
    echo "- Sensors and validators needed (see STANDARDS.md)"
    echo "- Dependencies on other features or external systems"
    echo "- Risks, spikes, or tasks that need human review first"
    echo "- Anything ambiguous in the spec that affects task split"
    echo ""
    echo "End with: save answers to \`$qa_file\` then \`rig-spec plan $spec_name --complete\`"
    echo ""
    echo "**Forbidden:** task files, sensor files, \`## File:\` output"

  } > "$context_file"

  print_ok "Tasks folder: $tasks_dir"
  print_ok "Context assembled: $context_file"
  echo ""
  echo "  1. cat $context_file  → paste into agent"
  echo "  2. Save Q&A to: $qa_file"
  echo "  3. rig-spec plan $spec_name --complete"
  echo ""
}

cmd_plan_complete() {
  local spec_name="$1"
  local spec_file="$2"
  local tasks_dir="$3"
  local qa_file="$4"

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec plan — $spec_name${RESET} ${DIM}(phase 2: complete)${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  if [ ! -f "$qa_file" ]; then
    print_warn "Q&A file not found: $qa_file"
    read -r -p "  Continue without Q&A? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  local plan_ts
  plan_ts=$(task_ts_prefix)

  local context_file="$RIG_DIR/context-plan-${spec_name}-complete.md"
  {
    echo "# Plan Tasks (phase 2): $spec_name"
    echo ""
    echo "> Q&A done. Create the task breakdown and sensors."
    echo ""
    echo "---"
    echo ""
    echo "## Project Overview"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""

    if [ -f "$qa_file" ]; then
      echo "## Plan Q&A"
      echo ""
      cat "$qa_file"
      echo ""
      echo "---"
      echo ""
    fi

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
    echo "Output format — required:"
    echo "Output each task file AND its sensors using this exact structure:"
    echo ""
    echo "  ## File: $tasks_dir/${plan_ts}-01-[name].task.md"
    echo "  \`\`\`markdown"
    echo "  [full task content here]"
    echo "  \`\`\`"
    echo ""
    echo "  ## File: $tasks_dir/${plan_ts}-02-[name].task.md"
    echo "  \`\`\`markdown"
    echo "  [full task content here]"
    echo "  \`\`\`"
    echo ""
    echo "File naming (required): ${plan_ts}-[NN]-[slug].task.md"
    echo "  - Use this plan timestamp prefix for ALL tasks: ${plan_ts}"
    echo "  - NN = zero-padded order: 01, 02, 03..."
    echo "  - Timestamp first so \`ls\` and \`rig-spec status\` stay in execution order"
    echo "  - Run later with: rig-spec run 01-[slug] (partial id is enough)"
    echo ""
    echo "Standards — mandatory:"
    echo "- List applicable files under '## Standards to Follow' in each task (see STANDARDS.md)"
    echo "- Prefer sensors: test, endpoint (if API), standards-compliance, spec-compliance"
    echo ""
    echo "Sensor files — mandatory:"
    echo "For every contract item that says '← verified by: [sensor]', output the sensor file."
    echo "Use YAML frontmatter for the command — it is unambiguous and parser-safe:"
    echo ""
    echo "  ## File: $RIG_DIR/feedback/sensors/[sensor-name].sensor.md"
    echo "  \`\`\`markdown"
    echo "  ---"
    echo "  command: [exact command — e.g. npx tsc --noEmit, npm test, npx eslint src/]"
    echo "  type: computational"
    echo "  timing: after-task"
    echo "  ---"
    echo ""
    echo "  # Sensor: [Name]"
    echo ""
    echo "  ## Pass condition"
    echo "  Exit code 0."
    echo ""
    echo "  ## On failure"
    echo "  Fix the implementation before marking the task done."
    echo "  \`\`\`"
    echo ""
    echo "If a sensor file already exists in $RIG_DIR/feedback/sensors/, skip it."
    echo "Do not output anything outside these blocks except a brief summary at the end."
    echo ""
  } > "$context_file"

  echo ""
  print_ok "Tasks folder created: $tasks_dir"
  print_ok "Task name prefix for this plan: ${plan_ts}-[NN]-[slug].task.md"
  print_ok "Context assembled: $context_file"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Paste this context into your AI agent:"
  echo ""
  echo "     cat $context_file"
  echo ""
  echo -e "  ${BOLD}2. After the agent responds:${RESET}"
  echo "     For each '## File: [path]' block in the response:"
  echo "     copy the content and save it to that path."
  echo ""
  echo "     Task files go to: $tasks_dir/"
  echo "     Sensor files go to: $RIG_DIR/feedback/sensors/"
  echo ""
  echo -e "  ${DIM}(Claude Code / Cursor: the agent will create the files directly)${RESET}"
  echo -e "  ${DIM}(Chat / Gemini / ChatGPT: copy each block and save manually)${RESET}"
  echo ""
  echo -e "  ${DIM}After saving sensor files, run: rig-spec sensors${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_plan_lite
# ─────────────────────────────────────────────

cmd_plan_lite() {
  local spec_name="$1"
  local spec_file="$2"
  local tasks_dir="$3"

  local plan_ts
  plan_ts=$(task_ts_prefix)

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec plan — $spec_name${RESET} ${DIM}(lite: no Q&A, tasks generated directly)${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  local context_file="$RIG_DIR/context-plan-${spec_name}-lite.md"
  {
    echo "# Plan Tasks (lite): $spec_name"
    echo ""
    echo "> **Lite mode.** No Q&A phase. Generate task files directly."
    echo "> Use this for small, well-understood changes only."
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
    echo "## Minimal Task Template"
    echo ""
    echo "Each task file must contain **only** these sections:"
    echo ""
    echo '```markdown'
    echo "# Task [NN] — [Task Name]"
    echo ""
    echo "## What to Build"
    echo ""
    echo "[2-4 sentences describing the deliverable precisely.]"
    echo ""
    echo "---"
    echo ""
    echo "## File Ownership"
    echo ""
    echo "> No other task may modify these files while this task is active."
    echo ""
    echo "- \`path/to/file.ext\`"
    echo ""
    echo "---"
    echo ""
    echo "## Contract — Definition of Done"
    echo ""
    echo "- [ ] [Specific deliverable] ← verified by: [test / typecheck / validator]"
    echo "- [ ] No files outside file ownership were modified ← verified by: validator"
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "## Instructions"
    echo ""
    echo "Break the spec into the **minimum number of tasks** needed."
    echo ""
    echo "Rules:"
    echo "- Use the minimal template above — no other sections"
    echo "- Assign file ownership to every task"
    echo "- Each contract item must have a verification method"
    echo "- Aim for 1–4 tasks; if more are needed, question the 'lite' scope"
    echo ""
    echo "Output format — required:"
    echo ""
    echo "  ## File: $tasks_dir/${plan_ts}-01-[name].task.md"
    echo "  \`\`\`markdown"
    echo "  [minimal task content]"
    echo "  \`\`\`"
    echo ""
    echo "File naming: ${plan_ts}-[NN]-[slug].task.md"
    echo "  - Prefix ALL tasks with: ${plan_ts}"
    echo "  - NN = zero-padded order: 01, 02, 03..."
    echo ""
    echo "Do not output anything outside these blocks except a one-line summary at the end."

  } > "$context_file"

  print_ok "Tasks folder: $tasks_dir"
  print_ok "Context assembled: $context_file"
  echo ""
  echo "  cat $context_file  → paste into agent"
  echo ""
  echo -e "  ${DIM}Lite mode: agent generates tasks directly (no Q&A). Best for 1–4 task changes.${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_replan
# ─────────────────────────────────────────────

cmd_replan() {
  require_rig
  local spec_name="${1:-}"

  if [ -z "$spec_name" ]; then
    echo ""
    print_err "Usage: rig-spec replan <spec-name>"
    echo ""
    echo "  Regenerates pending tasks for a spec after a pivot."
    echo "  Completed tasks (marked ✅ or [x] in progress.md) are preserved."
    echo ""
    echo "  Available specs:"
    find "$RIG_DIR/feedforward/specs" -name "*.spec.md" ! -name "_TEMPLATE*" 2>/dev/null | \
      while IFS= read -r f; do echo "    $(basename "$f" .spec.md)"; done
    echo ""
    exit 1
  fi

  spec_name=$(basename "$spec_name" .spec.md)
  spec_name=$(echo "$spec_name" | sed -E 's/^[0-9]{8}-[0-9]{6}-//')

  local spec_file
  if ! spec_file=$(find_spec_file "$spec_name"); then
    print_err "Spec not found for: $spec_name"
    exit 1
  fi

  local tasks_dir="$RIG_DIR/feedforward/tasks/${spec_name}"
  local plan_ts
  plan_ts=$(task_ts_prefix)

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec replan — $spec_name${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  # Collect existing tasks and their status from progress.md
  local progress_file="$RIG_DIR/memory/progress.md"
  local completed_tasks=""
  local pending_tasks=""

  # Find all task files for this spec
  local all_task_files
  all_task_files=$(find "$tasks_dir" -name "*.task.md" ! -name "_TEMPLATE*" 2>/dev/null | sort)

  if [ -n "$all_task_files" ]; then
    while IFS= read -r tf; do
      local tname
      tname=$(basename "$tf")
      # Consider a task completed if progress.md marks it with [x] or ✅
      if [ -f "$progress_file" ] && grep -qE "(\[x\]|✅).*${tname%%.task.md}|${tname%%.task.md}.*(\[x\]|✅)" "$progress_file" 2>/dev/null; then
        completed_tasks+="- ✅ $tname (completed — preserved, do not regenerate)"$'\n'
      else
        pending_tasks+="- ⏳ $tname (pending — may be replaced by the replan)"$'\n'
      fi
    done <<< "$all_task_files"
  fi

  local context_file="$RIG_DIR/context-replan-${spec_name}.md"
  {
    echo "# Replan Tasks: $spec_name"
    echo ""
    echo "> **Replan mode.** The original task breakdown for this spec needs revision."
    echo "> Your job: generate a new task breakdown for the REMAINING work."
    echo "> Do NOT touch or re-describe completed tasks."
    echo ""
    echo "---"
    echo ""
    echo "## Project Overview"
    echo ""
    cat "$RIG_DIR/HARNESS.md"
    echo ""
    echo "---"
    echo ""
    echo "## Current Feature Spec"
    echo ""
    cat "$spec_file"
    echo ""
    echo "---"
    echo ""

    if [ -f "$progress_file" ]; then
      echo "## Current Progress"
      echo ""
      cat "$progress_file"
      echo ""
      echo "---"
      echo ""
    fi

    echo "## Task Status"
    echo ""
    if [ -n "$completed_tasks" ]; then
      echo "### Completed (DO NOT regenerate)"
      echo ""
      echo "$completed_tasks"
    fi
    if [ -n "$pending_tasks" ]; then
      echo "### Pending (subject to replan)"
      echo ""
      echo "$pending_tasks"
    fi
    if [ -z "$completed_tasks" ] && [ -z "$pending_tasks" ]; then
      echo "_No task files found in $tasks_dir — this is a full replan._"
      echo ""
    fi
    echo ""
    echo "---"
    echo ""
    echo "## Your Instructions"
    echo ""
    echo "1. **Understand what changed:** Ask the human ONE question: 'What changed that requires a replan? (technical pivot, new constraint, discovery, etc.)'"
    echo "   Wait for the answer before generating anything."
    echo ""
    echo "2. **Generate ONLY new/updated pending tasks** using the task template:"
    echo ""
    cat "$RIG_DIR/feedforward/tasks/_TEMPLATE.task.md" 2>/dev/null || echo "   (see $RIG_DIR/feedforward/tasks/_TEMPLATE.task.md)"
    echo ""
    echo "---"
    echo ""
    echo "Output format — required:"
    echo ""
    echo "  ## File: $tasks_dir/${plan_ts}-[NN]-[name].task.md"
    echo "  \`\`\`markdown"
    echo "  [full task content]"
    echo "  \`\`\`"
    echo ""
    echo "File naming: ${plan_ts}-[NN]-[slug].task.md"
    echo "  - Use new timestamp prefix for all replanned tasks: ${plan_ts}"
    echo "  - Archive old pending tasks by prefixing their filename with 'archived-'"
    echo ""
    echo "After the replan, output a one-paragraph summary of:"
    echo "  - What changed and why"
    echo "  - Which tasks are new vs updated"
    echo "  - Anything the human should know before resuming"

  } > "$context_file"

  print_ok "Context assembled: $context_file"
  if [ -n "$completed_tasks" ]; then
    print_ok "Completed tasks detected — preserved in context"
  fi
  if [ -n "$pending_tasks" ]; then
    print_warn "Pending tasks will be subject to replan — review before accepting"
  fi
  echo ""
  echo "  cat $context_file  → paste into agent"
  echo ""
  echo -e "  ${DIM}The agent will ask ONE question before replanning. Answer it to define the pivot.${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_archive
# ─────────────────────────────────────────────

cmd_archive() {
  require_rig
  local spec_name="${1:-}"

  local progress="$RIG_DIR/memory/progress.md"

  if [ -z "$spec_name" ]; then
    echo ""
    print_err "Usage: rig-spec archive <spec-name>"
    echo ""
    echo "  Archives a completed spec's section from progress.md to memory/archive/."
    echo "  Keeps progress.md lean — completed features become a one-line reference."
    echo ""
    if [ -f "$progress" ]; then
      echo "  Completed specs in progress.md:"
      grep -E "^### " "$progress" 2>/dev/null | sed 's/^### /    /' || echo "    (none found)"
    fi
    echo ""
    exit 1
  fi

  spec_name=$(basename "$spec_name" .spec.md)

  if [ ! -f "$progress" ]; then
    print_err "progress.md not found: $progress"
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}rig-spec archive — $spec_name${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""

  local archive_dir="$RIG_DIR/memory/archive"
  local archive_file="$archive_dir/$(today)-${spec_name}.md"
  mkdir -p "$archive_dir"

  # Extract the ### section matching the spec name (case-insensitive slug comparison)
  local section_content
  section_content=$(awk -v slug="$spec_name" '
    function normalize(s,    r) {
      r = tolower(s)
      gsub(/[-_]/, " ", r)
      gsub(/[^a-z0-9 ]/, "", r)
      gsub(/  +/, " ", r)
      return r
    }
    /^### / {
      header = $0; sub(/^### /, "", header)
      if (index(normalize(header), normalize(slug)) > 0) {
        in_section = 1; print; next
      } else if (in_section) {
        exit
      }
    }
    /^## / { if (in_section) exit }
    in_section { print }
  ' "$progress" 2>/dev/null)

  if [ -z "$section_content" ]; then
    print_warn "Section '### $spec_name' not found in progress.md."
    echo ""
    echo "  If the feature is tracked under a different name, archive manually:"
    echo "  1. Copy the feature block from $progress"
    echo "  2. Paste it into a new file: $archive_file"
    echo "  3. Replace the block in progress.md with:"
    echo "     ✅ $spec_name (archived $(today)) → memory/archive/$(today)-${spec_name}.md"
    echo ""
    exit 1
  fi

  # Write archive file
  {
    echo "# Archive: $spec_name"
    echo ""
    echo "**Archived:** $(today)"
    echo "**Source:** memory/progress.md"
    echo ""
    echo "---"
    echo ""
    echo "$section_content"
  } > "$archive_file"

  # Remove the section from progress.md and insert a one-liner reference
  local reference="✅ $spec_name (archived $(today)) → \`memory/archive/$(today)-${spec_name}.md\`"
  local tmp_file
  tmp_file=$(mktemp)
  awk -v slug="$spec_name" -v ref="$reference" '
    function normalize(s,    r) {
      r = tolower(s)
      gsub(/[-_]/, " ", r)
      gsub(/[^a-z0-9 ]/, "", r)
      gsub(/  +/, " ", r)
      return r
    }
    /^### / {
      header = $0; sub(/^### /, "", header)
      if (index(normalize(header), normalize(slug)) > 0) {
        in_section = 1
        print ref
        next
      } else if (in_section) {
        in_section = 0
        print
        next
      }
    }
    /^## / { if (in_section) { in_section = 0 } }
    !in_section { print }
  ' "$progress" > "$tmp_file"
  mv "$tmp_file" "$progress"

  print_ok "Archived: $archive_file"
  print_ok "progress.md updated — section replaced with one-liner reference"
  echo ""
  echo -e "  ${DIM}To review: cat $archive_file${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# cmd_sensors
# ─────────────────────────────────────────────

cmd_sensors() {
  require_rig
  run_sensor_smoketest
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
  echo "  init --retrofit            Initialize for existing project (scans src/, rules as [DRAFT])"
  echo "  init --template <name>     Force a specific stack template"
  echo "                             Templates: node-api, python-api, fullstack-nextjs, generic"
  echo ""
  echo -e "${BOLD}Workflow:${RESET}"
  echo "  overview             Show project vision, business rules, and current state"
  echo "  status               Show current project state (specs, tasks, sensors)"
  echo "  resume               Context for a NEW chat (after handoff or between tasks)"
  echo "  handoff [task-id]    Prompt agent to save CHECKPOINT and end session"
  echo "  session              Show current task + when to hand off"
  echo "  run <task-id>        Assemble task context for your AI agent"
  echo "  validate [task-id]     Run sensors + write feedback/reports/validation-*.md"
  echo "  done <task-id>       Mark a task complete — updates progress.md and HARNESS.md"
  echo "  sensors              Check all sensor configurations are executable"
  echo "  audit                Run continuous drift sensors"
  echo ""
  echo -e "${BOLD}Spec-driven:${RESET}"
  echo "  research <topic>     Create a research file in memory/research/"
  echo "  shape <feature>      Phase 1: CLI questions + agent clarifying questions"
  echo "  shape <feature> --complete   Phase 2: agent writes full spec (after Q&A file)"
  echo "  plan <spec-name>             Phase 1: agent planning questions before tasks"
  echo "  plan <spec-name> --complete  Phase 2: agent creates tasks + sensors"
  echo "  plan <spec-name> --lite      Skip Q&A, generate minimal tasks directly"
  echo "  replan <spec-name>           Regenerate pending tasks after a pivot"
  echo "  archive <spec-name>          Move completed spec out of progress.md to memory/archive/"
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
    overview)     cmd_overview ;;
    status)       cmd_status ;;
    resume)       cmd_resume ;;
    handoff)      cmd_handoff "$@" ;;
    session)      cmd_session ;;
    validate)     cmd_validate "$@" ;;
    done)         cmd_done "$@" ;;
    sensors)      cmd_sensors ;;
    audit)        cmd_audit ;;
    run)          cmd_run "$@" ;;
    research)     cmd_research "$@" ;;
    shape)        cmd_shape "$@" ;;
    plan)         cmd_plan "$@" ;;
    replan)       cmd_replan "$@" ;;
    archive)      cmd_archive "$@" ;;
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
