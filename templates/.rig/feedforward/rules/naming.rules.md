# Naming Rules

> Loaded into every agent context before task execution.
> Defines naming conventions for files, classes, functions, and variables.
> DRAFT — fill in the conventions for this project. Remove the [DRAFT] markers when reviewed.

---

## Files

- [file type]: `[pattern]` — e.g., services: `*.service.ts`
- [file type]: `[pattern]` — e.g., controllers: `*.controller.ts`
- [file type]: `[pattern]` — e.g., tests: `*.spec.ts`

## Classes / Components

- [type]: `[casing + suffix rule]` — e.g., services: `PascalCase` + `Service` suffix
- [type]: `[casing + suffix rule]`

## Functions / Methods

- [type]: `[casing + prefix rule]` — e.g., event handlers: `camelCase`, `on` prefix
- [type]: `[casing + prefix rule]`

## Variables / Constants

- [type]: `[casing rule]` — e.g., module-level constants: `UPPER_SNAKE_CASE`
- [type]: `[casing rule]` — e.g., local variables: `camelCase`

## Database

- Tables: `[casing rule]` — e.g., `snake_case`, plural
- Columns: `[casing rule]` — e.g., `snake_case`

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
Tool: ESLint custom rules generated from these conventions
