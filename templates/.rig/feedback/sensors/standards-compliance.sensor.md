# Sensor: Standards Compliance

> **Type:** Inferential (AI-based)
> **Timing:** After every task (after computational sensors pass)

---

## Purpose

Verify the implementation follows **all** project standards in `feedforward/rules/`, including patterns linters cannot detect: wrong layer for logic, components in wrong folders, API envelopes, test structure.

Read first: `.rig/STANDARDS.md` for the full index.

---

## Command

```bash
# No shell command — run via review agent.
# rig-spec validate includes instructions from:
#   feedback/review/code-review.review.md
#   feedback/sensors/standards-compliance.sensor.md (this file)
echo "INFERENTIAL: use review agent with feedforward/rules/"
```

## Pass Condition

Review agent returns `## Review Result: PASS` with **Standards Compliance: PASS**.

## On Failure

1. List each violated rule file and the specific pattern broken.
2. Fix only what the contract and rules require — no drive-by refactors.
3. Re-run `rig-spec validate <task-id>`.

## Review checklist (agent)

- [ ] Read every `feedforward/rules/*.rules.md` that applies to changed files
- [ ] Architecture layering matches `architecture.rules.md`
- [ ] Naming matches `naming.rules.md`
- [ ] New files live in paths allowed by `structure.rules.md`
- [ ] API handlers match `api.rules.md` (if applicable)
- [ ] Tests match `testing.rules.md`
- [ ] UI matches `component.rules.md` and `design-tokens.rules.md` (if applicable)
