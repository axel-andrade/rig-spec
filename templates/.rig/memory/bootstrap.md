# Bootstrap — Context Reconstruction

> Read this at the start of every new session.
> Following this order reconstructs full project context with minimum tokens.
> Do not skip steps — each one answers a different question.

---

## Reading Order

### 1. Project Overview
→ Read `.rig/HARNESS.md`

**What it answers:** What is this project? What level is the harness at? What feature is active? What tools are available?

### 2. Current State
→ Read `.rig/memory/progress.md`

**What it answers:** What's done? What's in progress? What's next? Are there any blockers?

### 3. Architectural Decisions (when exists)
→ Read `.rig/memory/decisions.md`

**What it answers:** Why are things the way they are? Do not re-debate decided issues.

### 4. Research Findings (when relevant)
→ Read `.rig/memory/research/[relevant-topic].md`

**What it answers:** What was already investigated? Do not re-research what's already documented.

### 5. Active Feature Spec (when in progress)
→ Read the active spec: `.rig/feedforward/specs/[active-feature].spec.md`

**What it answers:** What are we building? What are the acceptance criteria? What are the approved fixtures?

### 6. Current Task (when in progress)
→ Read the next pending task in `.rig/feedforward/tasks/[feature]/`

**What it answers:** What exactly should be built next? What files are owned? What is the contract?

---

## After Reading

You are now fully context-aware. Proceed with the current task.

If something is unclear after reading all files, ask — do not assume.

If progress.md says no active feature, start with: creating a spec in `feedforward/specs/` using `_TEMPLATE.spec.md`.
