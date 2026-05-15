# Testing Rules

> Loaded into every agent context before task execution.
> Defines test requirements, structure, coverage expectations, and the approved fixtures policy.
> DRAFT — fill in the rules for this project. Remove the [DRAFT] markers when reviewed.

---

## Coverage Requirements

- [Layer or module]: minimum [X]% coverage
- Critical paths (auth, payments, etc.): [X]% minimum
- [Add layer-specific requirements]

## Test Types and Location

- Unit tests: `[pattern]` — e.g., `*.spec.ts` next to source file
- Integration tests: `[path]` — e.g., `tests/integration/`
- E2E tests: `[path]` — e.g., `tests/e2e/`

## Approved Fixtures Policy

> This is the core of the Behavioural Harness pattern.

- Expected outputs are defined by humans in the spec's `Approved Fixtures` section BEFORE any agent writes tests.
- Agents must write tests that validate those exact outputs.
- Agents may **NOT** modify an approved fixture to make a failing test pass.
- If a fixture produces an unexpected result, the implementation is wrong — not the fixture.

## Rules

- Do NOT mock the database in integration tests
- Do NOT use `any` in test assertions
- Test names must describe behavior, not implementation: `"returns 404 when user not found"`, NOT `"calls findById"`
- Every task that creates a function must include at least one test
- [Add project-specific rules]

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
