# Progress

> Updated after EVERY contract item completed — not just after validate or done.
> This file is the source of truth for project state.
> An agent reading this file knows exactly where to resume, down to the last completed step.

---

## Active Features

_No features in progress yet._

---

## Completed Features

_None yet._

---

## Last Session

**Date:** —
**What happened:** Project initialized with rig-spec harness.
**What's next:** Create your first spec in `feedforward/specs/`.
**Blockers:** None.

---

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
