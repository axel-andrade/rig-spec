# Sensor: Lint (ESLint)

**Type:** Computational
**Timing:** After every task

## Command
```bash
npx eslint src/ --max-warnings 0
```

## Pass condition
Exit code 0. Zero warnings, zero errors.

## On failure
Fix all reported issues. Do not suppress rules.
