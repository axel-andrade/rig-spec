# Audit: Dependency Health

> Level 3 — Continuous sensor. Runs on schedule, outside the task change cycle.
> Detects outdated dependencies, known vulnerabilities, and license issues.

---

## Commands

```bash
# Check for vulnerabilities
npm audit

# Check for outdated packages
npm outdated

# Or with a combined tool
npx depcheck
```

## What It Detects

- Dependencies with known CVEs
- Major version updates available (potential breaking changes)
- Unused dependencies in package.json
- Missing dependencies (used in code but not declared)

## Pass Condition

- Zero critical or high severity vulnerabilities
- No dependencies more than 2 major versions behind current
- No unused dependencies

## On Detection

1. For vulnerabilities: update immediately and test
2. For outdated packages: create a dependency upgrade task in the next sprint
3. For unused/missing: clean up package.json

## Report Format

Findings are saved to: `feedback/audit/report-[YYYY-MM-DD].md`
