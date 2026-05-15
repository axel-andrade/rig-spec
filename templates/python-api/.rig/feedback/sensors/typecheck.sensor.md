# Sensor: Type Check (mypy)

**Type:** Computational
**Timing:** After every task

## Command
```bash
mypy .
```

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `type: ignore` without justification.
