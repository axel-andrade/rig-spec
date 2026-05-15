# Testing Rules — Python / pytest

---

## Test Structure

- All test files: `test_[module].py`
- Location: `tests/` at project root, mirroring `src/` structure
- Integration tests: `tests/integration/`

## Coverage

- Services: minimum 80% line coverage
- Repositories: covered by integration tests against a real test database
- Routers: covered by integration tests using TestClient

## Rules

- Do NOT mock the database in integration tests — use a real test database.
- Do NOT change a test to make it pass — fix the implementation.
- Test function names describe behavior: `test_returns_404_when_user_not_found`
- Use `pytest.fixture` for reusable setup — not `setUp` class methods.
- Use `parametrize` for data-driven tests.

## Approved Fixtures Policy

- Expected outputs are defined in the spec BEFORE agents write tests.
- Agents may NOT modify a fixture to make a test pass.

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
