# Testing Rules — Node.js / Jest

---

## Test Structure

- Unit tests: `src/[module]/[name].spec.ts` (next to the file)
- Integration tests: `test/` or `src/__tests__/`
- E2E tests: `test/e2e/`

## Coverage

- Services: minimum 80% line coverage
- Repositories: covered by integration tests, not unit tests
- Controllers: covered by E2E or integration tests

## Rules

- Do NOT mock the database in integration tests — use a real test database.
- Do NOT change a test to make it pass — fix the implementation.
- Test names describe behavior: `"should return 404 when user is not found"`
- One assertion per test where possible.
- Use `beforeEach` for setup, `afterEach`/`afterAll` for cleanup.

## Approved Fixtures Policy

- Expected outputs are defined in the spec BEFORE agents write tests.
- Agents may NOT modify a fixture to make a test pass.
- If a fixture is wrong, raise it with the human — do not change it silently.

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
