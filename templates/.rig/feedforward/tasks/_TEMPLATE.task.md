# Task [XX] — [Task Name]

> **Filename:** `YYYYMMDD-HHMMSS-[XX]-[slug].task.md` (timestamp first — keeps tasks sorted)
> Example: `20260519-143052-01-dependencies.task.md`
> Run with: `rig-spec run 01-dependencies` (partial match; if ambiguous use `feature-slug/01-dependencies`)

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

---

## Skills to Load

> `rig-spec run` also auto-matches `skills.registry.md`. Disable with `skills: manual` in this file.

- `feedforward/skills/[technology].skill.md`

---

## Sensors for This Task

- [ ] `test.sensor.md`
- [ ] `endpoint.sensor.md` (if API)
- [ ] `standards-compliance.sensor.md`

---

## Contract — Definition of Done

- [ ] [Deliverable 1] ← verified by: [test / typecheck / validator]
- [ ] Project standards per `STANDARDS.md` ← verified by: standards-compliance + review
- [ ] Approved fixtures from spec pass ← verified by: spec-compliance + validator
- [ ] No files outside file ownership were modified ← verified by: validator
