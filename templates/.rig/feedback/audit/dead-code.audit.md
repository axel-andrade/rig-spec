# Audit: Dead Code

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects unused exports, unreachable code, and orphaned files.

---

## Command

```bash
# Node.js / TypeScript projects
npx ts-prune

# Or with knip (broader analysis)
npx knip
```

## What It Detects

- Exported functions/classes that are never imported
- Files that are never referenced
- Variables declared but never used (beyond what the linter catches)

## Pass Condition

Zero unused exports in `src/`. Exceptions must be explicitly documented below.

## Known Exceptions

[List any intentional dead exports — e.g., public API surface, future use]

- `[export name]` in `[file]` — reason: [why it's intentionally exported but unused]

## On Detection

1. Review each reported item — confirm it is genuinely unused (not a false positive)
2. Remove unused code or document why it must stay
3. Update Known Exceptions if keeping it is intentional

## Report Format

Findings are saved to: `feedback/audit/report-[YYYY-MM-DD].md`
