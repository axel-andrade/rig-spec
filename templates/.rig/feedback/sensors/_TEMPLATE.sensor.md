# Sensor: [Sensor Name]

> Level 3 — Automated validation.
> This sensor runs after implementation to verify correctness.

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

## Command

```bash
[the exact command to run]
```

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
