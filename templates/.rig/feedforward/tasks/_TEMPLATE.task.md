# Task [XX] — [Task Name]

---

## Spec Reference

→ `feedforward/specs/[spec-name].spec.md`

---

## What to Build

[Clear description of what this task produces. 2-4 sentences. Be specific — the implementer should know exactly what to write without reading anything else.]

---

## Where to Build It

[List every file to create or modify.]

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
> The implementer signs each item when complete.

- [ ] [Deliverable 1] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 2] ← verified by: [test / typecheck / validator]
- [ ] [Deliverable 3] ← verified by: [test / typecheck / validator]
- [ ] Approved fixtures from spec pass ← verified by: validator
- [ ] No files outside file ownership were modified ← verified by: validator
