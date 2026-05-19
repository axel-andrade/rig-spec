# Sensor: Spec Compliance

> **Type:** Inferential (AI-based)
> **Timing:** After every task (after computational sensors pass)

---

## Purpose

Verify the implementation satisfies the **feature spec**: acceptance criteria, user stories, and **approved fixtures** (expected inputs/outputs defined before coding).

---

## Command

```bash
# No shell command — run via review agent with the linked spec.
echo "INFERENTIAL: compare task + code against feedforward/specs/*.spec.md"
```

## Pass Condition

- Every acceptance criterion touched by this task is implemented.
- Every approved fixture in scope produces the documented expected output.
- Nothing in **Out of Scope** was built.

## On Failure

Return a table:

| Criterion / fixture | Expected | Actual | File |
|---|---|---|---|
| ... | ... | ... | ... |

## Review checklist (agent)

- [ ] Read spec referenced in task (`## Spec Reference`)
- [ ] Map each contract item to an acceptance criterion
- [ ] Run or trace tests that cover approved fixtures
- [ ] Confirm no out-of-scope functionality was added
