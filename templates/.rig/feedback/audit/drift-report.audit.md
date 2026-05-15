# Audit: Drift Report

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects gradual architectural degradation that doesn't show up in per-task sensors.

---

## What This Audit Checks

Drift happens between tasks, not within them. This audit looks for accumulation across the entire codebase.

### Architecture Drift
- Module boundary violations that slipped through
- New forbidden imports introduced
- Layer violations not caught by per-task arch sensor

### Standards Drift
- New files that don't follow naming conventions
- New folders outside the defined structure
- API endpoints that don't match the response envelope

### Coverage Drift
- Modules whose test coverage dropped below the minimum
- Files added without corresponding tests

### Complexity Drift
- Functions exceeding the complexity threshold
- Files exceeding the line limit

---

## Commands

```bash
# Architecture drift
npx depcruise src/ --config .dependency-cruiser.json

# Coverage drift
npm test -- --coverage

# Complexity (if configured)
npx complexity-report src/
```

## Report Format

Findings are saved to: `feedback/audit/report-[YYYY-MM-DD].md`

Use this format:

```markdown
# Drift Report — [YYYY-MM-DD]

## Architecture Drift
[CLEAN / VIOLATIONS FOUND]
- [violation description] → `[file]`

## Standards Drift
[CLEAN / VIOLATIONS FOUND]
- [violation description] → `[file]`

## Coverage Drift
[CLEAN / BELOW MINIMUM]
- `[module]`: [X]% (minimum: [Y]%)

## Trend
[Better / Stable / Degrading] vs previous report
```
