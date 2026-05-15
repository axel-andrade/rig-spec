# Sensor: Type Check (TypeScript)

**Type:** Computational
**Timing:** After every task

## Command
```bash
npx tsc --noEmit
```

## Pass condition
Exit code 0. Zero type errors.

## On failure
Fix all type errors. Do not use `any` or `@ts-ignore`.
