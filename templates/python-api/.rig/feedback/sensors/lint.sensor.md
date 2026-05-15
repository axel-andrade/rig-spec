# Sensor: Lint (Ruff)

**Type:** Computational
**Timing:** After every task

## Command
```bash
ruff check .
```

## Pass condition
Exit code 0. Zero violations.

## On failure
Fix all reported issues. Do not add noqa suppressions without justification.
