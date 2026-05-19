#!/usr/bin/env bash
# update.sh — rig-spec harness updater
#
# Applies the latest framework improvements to an existing .rig/ installation.
# Safe: never overwrites your specs, tasks, rules, research, skills, or project context.
#
# Usage:
#   bash update.sh                        — local (run from rig-spec repo root)
#   bash /path/to/update.sh              — local (any path)
#   curl -fsSL <raw-url>/update.sh | bash — remote (downloads templates from GitHub)

set -e

REPO="https://raw.githubusercontent.com/axel-andrade/rig-spec/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIG_DIR=".rig"

# Detect source: local templates or GitHub
if [ -d "$SCRIPT_DIR/templates/.rig" ]; then
  TEMPLATES="$SCRIPT_DIR/templates/.rig"
  TEMPLATE_SOURCE="local"
else
  TEMPLATES=""
  TEMPLATE_SOURCE="github"
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RED='\033[0;31m'
RESET='\033[0m'

print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
print_skip() { echo -e "  ${DIM}–${RESET} $1"; }
print_step() { echo -e "\n${BOLD}$1${RESET}"; }

_updated=0
_created=0
_skipped=0

inc_updated() { ((_updated++)) || true; }
inc_created() { ((_created++)) || true; }
inc_skipped() { ((_skipped++)) || true; }

# Fetch a template file to a destination path.
# Uses local copy if available; downloads from GitHub otherwise.
fetch_template() {
  local rel="$1"   # e.g. "memory/bootstrap.md"
  local dst="$2"   # absolute destination path

  mkdir -p "$(dirname "$dst")"

  if [ "$TEMPLATE_SOURCE" = "local" ]; then
    local src="$TEMPLATES/$rel"
    if [ ! -f "$src" ]; then
      print_warn "$rel — not found in local templates"
      return 1
    fi
    cp "$src" "$dst"
  else
    local url="$REPO/templates/.rig/$rel"
    if ! curl -fsSL "$url" -o "$dst" 2>/dev/null; then
      print_warn "$rel — download failed ($url)"
      return 1
    fi
  fi
  return 0
}

# ─────────────────────────────────────────────
# Guards
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}rig-spec update${RESET}"
echo -e "${CYAN}──────────────────────────────────────${RESET}"

if [ ! -d "$RIG_DIR" ]; then
  echo ""
  echo -e "  ${RED}✗${RESET} No .rig/ found in the current directory."
  echo ""
  echo "  Run from your project root (where .rig/ lives)."
  echo "  Or initialize first: rig-spec init"
  echo ""
  exit 1
fi

if [ "$TEMPLATE_SOURCE" = "github" ]; then
  if ! command -v curl &>/dev/null; then
    echo ""
    echo -e "  ${RED}✗${RESET} curl not found. Install curl or run update.sh from the rig-spec repo."
    echo ""
    exit 1
  fi
  echo -e "  ${DIM}Source: GitHub ($REPO)${RESET}"
else
  echo -e "  ${DIM}Source: local ($TEMPLATES)${RESET}"
fi

# ─────────────────────────────────────────────
# 1. Pure framework files — replace completely
#    These contain no user content.
# ─────────────────────────────────────────────

print_step "1/5  Framework files (safe to replace)"

replace_framework_file() {
  local rel="$1"
  local dst="$RIG_DIR/$rel"

  if fetch_template "$rel" "$dst"; then
    print_ok "$rel"
    inc_updated
  else
    inc_skipped
  fi
}

replace_framework_file "memory/bootstrap.md"
replace_framework_file "orchestration/implementer.md"
replace_framework_file "orchestration/validator.md"
replace_framework_file "feedback/sensors/_TEMPLATE.sensor.md"
replace_framework_file "orchestration/contracts/_TEMPLATE.contract.md"

# ─────────────────────────────────────────────
# 2. New files — create only if absent
#    Skip if already exists (may have user content).
# ─────────────────────────────────────────────

print_step "2/5  New files (create if absent)"

create_if_absent() {
  local rel="$1"
  local dst="$RIG_DIR/$rel"

  if [ -f "$dst" ]; then
    print_skip "$rel — already exists, not touched"
    inc_skipped
  elif fetch_template "$rel" "$dst"; then
    print_ok "Created: $rel"
    inc_created
  else
    inc_skipped
  fi
}

create_if_absent "memory/learnings.md"

# ─────────────────────────────────────────────
# 3. Patch HARNESS.md — non-destructive
#    Only adds missing sections. Never removes user content.
# ─────────────────────────────────────────────

print_step "3/5  HARNESS.md (non-destructive patch)"

HARNESS="$RIG_DIR/HARNESS.md"

if [ ! -f "$HARNESS" ]; then
  print_warn "HARNESS.md not found — skipping"
  inc_skipped
else
  # 3a. Add learnings.md to Key Files table if missing
  if grep -q "learnings\.md" "$HARNESS"; then
    print_skip "Key Files — learnings.md already listed"
    inc_skipped
  else
    # Insert after the decisions.md row
    sed -i "s|memory/decisions\.md\` | Architectural decisions ||\`memory/decisions.md\` | Architectural decisions |\n| \`memory/learnings.md\` | Implementation discoveries and gotchas |" "$HARNESS" 2>/dev/null || true
    # Fallback: if sed didn't match, append to the Key Files table (before the closing |)
    if ! grep -q "learnings\.md" "$HARNESS"; then
      sed -i "/| \`memory\/decisions\.md\`/a | \`memory\/learnings\.md\` | Implementation discoveries and gotchas |" "$HARNESS"
    fi
    if grep -q "learnings\.md" "$HARNESS"; then
      print_ok "Key Files — learnings.md added"
      inc_updated
    else
      print_warn "Key Files — could not add learnings.md automatically (add manually)"
      inc_skipped
    fi
  fi

  # 3b. Update Context Reconstruction order if it still has the old 5-step format
  # Check specifically for learnings.md inside the Context Reconstruction section
  _ctx_has_learnings=$(awk '/^## Context Reconstruction/{p=1} p && /memory\/learnings/{print "yes"; exit}' "$HARNESS")
  if [ "$_ctx_has_learnings" = "yes" ]; then
    print_skip "Context Reconstruction — already has learnings.md"
    inc_skipped
  else
    # Replace the old numbered list if it matches the old 5-step pattern
    old_ctx="1. This file (HARNESS.md)
2. \`memory/progress.md\` — what's done and what's next
3. \`memory/decisions.md\` — key decisions made (when exists)
4. The active spec in \`feedforward/specs/\`
5. The current task in \`feedforward/tasks/\`"

    new_ctx="1. This file (HARNESS.md)
2. \`memory/progress.md\` — what's done and what's next
3. \`memory/decisions.md\` — key decisions made (when exists)
4. \`memory/learnings.md\` — implementation discoveries (when exists)
5. The active spec in \`feedforward/specs/\`
6. The current task in \`feedforward/tasks/\`"

    # Use python3 for reliable multi-line replacement (awk gets messy with backticks)
    if command -v python3 &>/dev/null; then
      python3 - "$HARNESS" "$old_ctx" "$new_ctx" << 'PYEOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r') as f:
    content = f.read()
if old in content:
    with open(path, 'w') as f:
        f.write(content.replace(old, new, 1))
    print("updated")
else:
    print("not_matched")
PYEOF
      if grep -q "memory/learnings.md" "$HARNESS"; then
        print_ok "Context Reconstruction — learnings.md step added"
        inc_updated
      else
        print_skip "Context Reconstruction — pattern not matched (may already be custom)"
        inc_skipped
      fi
    else
      print_warn "Context Reconstruction — python3 not found, skipping (add learnings.md step manually)"
      inc_skipped
    fi
  fi

  # 3c. Append Git Workflow section if missing
  if grep -q "## Git Workflow" "$HARNESS"; then
    print_skip "Git Workflow section — already present"
    inc_skipped
  else
    cat >> "$HARNESS" << 'EOF'

## Git Workflow

**Branch per feature:** create a branch from `main` when starting a spec.

```
git checkout -b feat/[feature-name]
```

**Commit per task:** after `rig-spec validate` passes and the task is marked done, commit the work.

```
git add -p
git commit -m "feat([feature-name]): [task-id] — [one line summary]"
```

**Merge when the spec is complete:** all tasks done, all sensors green, audit clean.

```
git checkout main && git merge --no-ff feat/[feature-name]
```

> Agents must not commit on behalf of the human unless explicitly instructed. The commit step belongs to the human after `rig-spec done`.
EOF
    print_ok "Git Workflow section appended"
    inc_updated
  fi
fi

# ─────────────────────────────────────────────
# 4. Patch memory/progress.md — preserve user content
#    Updates: header comment + Template section at the bottom.
#    Preserves: Active Features, Completed Features, Last Session.
# ─────────────────────────────────────────────

print_step "4/5  memory/progress.md (preserve user content)"

PROGRESS="$RIG_DIR/memory/progress.md"

if [ ! -f "$PROGRESS" ]; then
  print_warn "memory/progress.md not found — skipping"
  inc_skipped
else
  # 4a. Update old header line
  if grep -q "Updated after every validated task\." "$PROGRESS"; then
    sed -i 's/> Updated after every validated task\./> Updated after EVERY contract item completed — not just after validate or done./' "$PROGRESS"
    print_ok "Header comment updated"
    inc_updated
  else
    print_skip "Header comment — already updated or customized"
    inc_skipped
  fi

  # 4b. Replace Template section if it has the old format (no [~] sub-list)
  if grep -q "task-02: ← NEXT" "$PROGRESS" && command -v python3 &>/dev/null; then
    python3 - "$PROGRESS" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Split at ## Template — preserve everything before it
marker = '\n## Template\n'
if marker not in content:
    print("no_marker")
    sys.exit(0)

before, _ = content.split(marker, 1)

new_template = '''
## Template

Use this format when updating:

```markdown
## [Feature Name]
### Status: in-progress | complete | blocked

- [x] task-01: [what was built] ([YYYY-MM-DD])
- [~] task-02: in-progress — [brief description]
  - [x] [contract item 1 completed]
  - [x] [contract item 2 completed]
  - [ ] [contract item 3] ← next
  - [ ] [contract item 4]
- [ ] task-03
- [ ] task-04

**Blocked by:** [blocker description, if any]
```

**Update rules:**
- `[ ]` — not started
- `[~]` — in progress (expand with contract item sub-list)
- `[x]` — complete (task-level, set by `rig-spec done`)

After each contract item: check its box in the task file AND add/update the sub-item under `[~]` in this file. The sub-list is what allows the next agent to continue without re-reading the whole task.
'''

with open(path, 'w') as f:
    f.write(before + new_template)

print("updated")
PYEOF
    if grep -q "\[~\]" "$PROGRESS"; then
      print_ok "Template section updated with sub-item format"
      inc_updated
    else
      print_warn "Template section — could not update (add manually from templates/.rig/memory/progress.md)"
      inc_skipped
    fi
  elif grep -q "\[~\]" "$PROGRESS"; then
    print_skip "Template section — already has sub-item format"
    inc_skipped
  elif ! command -v python3 &>/dev/null; then
    print_warn "Template section — python3 not found, skipping (update manually)"
    inc_skipped
  fi
fi

# ─────────────────────────────────────────────
# 5. mcp.config.md — update only if still default empty template
# ─────────────────────────────────────────────

print_step "5/5  feedforward/mcp.config.md (only if unchanged)"

MCP="$RIG_DIR/feedforward/mcp.config.md"

if [ ! -f "$MCP" ]; then
  print_skip "mcp.config.md not found"
  inc_skipped
elif grep -q "context7" "$MCP"; then
  print_skip "mcp.config.md — already has suggested servers, not touched"
  inc_skipped
elif grep -q "\[Add an entry for each MCP server" "$MCP"; then
  # Still the default placeholder — safe to replace
  if fetch_template "feedforward/mcp.config.md" "$MCP"; then
    print_ok "mcp.config.md updated with suggested servers (context7, brave-search, filesystem)"
    inc_updated
  else
    inc_skipped
  fi
else
  print_skip "mcp.config.md — has custom content, not touched"
  inc_skipped
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
echo -e "${CYAN}──────────────────────────────────────${RESET}"
echo ""
echo -e "  ${GREEN}${BOLD}Update complete${RESET}"
echo ""
printf "  %-10s %s\n" "Updated:" "$_updated files"
printf "  %-10s %s\n" "Created:" "$_created files"
printf "  %-10s %s\n" "Skipped:" "$_skipped items (user content preserved)"
echo ""
echo -e "  ${DIM}Untouched: specs/, tasks/, rules/, skills/, research/, sensors/, progress content${RESET}"
echo ""
