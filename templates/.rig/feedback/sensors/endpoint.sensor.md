# Sensor: API Endpoint Smoke

> **Type:** Computational
> **Timing:** After every task that adds or changes HTTP endpoints

---

## Purpose

Smoke-test API endpoints: server responds, status codes are correct, response shape matches `feedforward/rules/api.rules.md`.

---

## Command

```bash
# Configure for your stack — uncomment ONE block:

# Node / Express / Nest (dev server must be running)
# npm run test:api 2>/dev/null || npx jest --testPathPattern=api --passWithNoTests

# Next.js (integration test hitting route handlers)
# npm test -- --testPathPattern="api|route" --passWithNoTests

# Python FastAPI (pytest + httpx)
# pytest tests/api -q --tb=short 2>/dev/null || pytest -q -k api --tb=short

# curl smoke (replace URL and paths)
# curl -sf http://localhost:3000/api/health | grep -q '"data"'

# Placeholder until configured — fails intentionally so you wire a real command
false
```

## Pass Condition

Exit code: `0`

Additional checks (document in your test suite):
- `2xx` for happy path
- `4xx` for validation errors with structured error body
- Response envelope matches project API rules

## On Failure

1. Read test or curl output — fix handler, service, or auth first.
2. Do not change the API contract without updating `api.rules.md` and the spec.
3. Re-run this sensor.

## Setup guide

1. Add integration tests under `tests/api/` or `__tests__/api/` that hit real routes.
2. Replace the `false` command above with your test runner invocation.
3. For local smoke without tests, use `curl` against documented paths in the task contract.
