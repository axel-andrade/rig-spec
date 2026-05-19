# Validation Matrix — Review protocol

> Used by `rig-spec validate` after computational sensors run.
> Ensures every validation dimension is checked, including **standards** and **review skill** output.

---

## Your role

You are the **validation reviewer**. Computational sensors already ran. You complete the matrix below and produce the structured report saved to `feedback/reports/`.

Read in order:

1. Task file and contract checklist
2. `.rig/STANDARDS.md` — which rule files apply
3. All applicable `feedforward/rules/*.rules.md`
4. Linked spec (`feedforward/specs/`)
5. `feedback/review/code-review.review.md` — detailed review criteria

---

## Validation matrix (fill every row)

| Dimension | Source | Method | Result |
|---|---|---|---|
| Lint / format | `lint.sensor.md` | CLI exit 0 | PASS / FAIL |
| Types | `typecheck.sensor.md` | CLI exit 0 | PASS / FAIL / N/A |
| Tests | `test.sensor.md` | CLI exit 0 | PASS / FAIL |
| API smoke | `endpoint.sensor.md` | CLI exit 0 | PASS / FAIL / N/A |
| Architecture | `arch.sensor.md` | CLI exit 0 | PASS / FAIL / N/A |
| Spec compliance | `spec-compliance.sensor.md` | This review | PASS / FAIL |
| Standards compliance | `standards-compliance.sensor.md` | This review + `rules/` | PASS / FAIL |
| Contract items | Task `## Contract` | Item-by-item | PASS / FAIL |
| Approved fixtures | Spec | Tests / trace | PASS / FAIL / N/A |
| File ownership | Task | `git diff --name-only` | PASS / FAIL |

**Overall:** PASS only if every row is PASS or N/A.

---

## Output format (required)

Copy this block into the validation report file:

```markdown
## Validation Matrix

| Dimension | Result | Notes |
|---|---|---|
| Lint | PASS | |
| Types | PASS | |
| Tests | PASS | |
| API smoke | N/A | |
| Spec compliance | PASS | |
| Standards compliance | PASS | |
| Contract | PASS | 6/6 items |
| Fixtures | PASS | |
| File ownership | PASS | |

## Overall: PASS | FAIL

### Failures (if any)
- [Dimension] — [specific fix required]

### Standards violations (if any)
- Rule file: `feedforward/rules/....md` — [violation]
```

Do not mark PASS if any contract checkbox is unchecked or any computational sensor failed.
