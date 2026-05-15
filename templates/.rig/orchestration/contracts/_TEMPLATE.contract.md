# Contract: [spec-name] / task-[XX]

> Agreement between the implementer and validator agents.
> Written during plan. Signed by implementer during run. Verified by validator.

---

## Implementer Commits To

> Check each item when complete. The validator will verify each one.
> Do not mark an item complete unless it is fully done and verifiable.

- [ ] [Specific deliverable — must be verifiable, not vague]
- [ ] [Specific deliverable — must be verifiable, not vague]
- [ ] [Specific deliverable — must be verifiable, not vague]
- [ ] Approved fixtures from spec produce expected outputs
- [ ] No files outside declared file ownership were modified

## File Ownership

Files created or modified by this task. No other task may touch these while this is in progress:

- `[file path]`
- `[file path]`

---

## Validator Must Check

> For each item above, the exact verification method.
> "Passed" only if every row is confirmed.

| Item | Verification method |
|---|---|
| [Deliverable 1] | Run: `[command]` — expect exit 0 |
| [Deliverable 2] | Manually verify: [what to look for] |
| [Deliverable 3] | Run test: `[test name or file]` |
| Approved fixtures pass | Run: `[test command]` — verify outputs match spec |
| No ownership violations | Run: `git diff --name-only` — no files outside ownership list |

---

## Sensor Results (filled by validator)

- [ ] lint: PASS / FAIL
- [ ] typecheck: PASS / FAIL
- [ ] tests: PASS / FAIL

## Verdict

- [ ] **PASSED** — all items verified, task complete, progress.md updated
- [ ] **FAILED** — see failures below

### Failures (if any)

[List specific failures with file + line references so the implementer can fix exactly what failed. No vague feedback.]
