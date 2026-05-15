# Testing Rules — Next.js / Jest + Testing Library

---

## Test Structure

- Component tests: `[ComponentName].test.tsx` (next to the component)
- Service/util tests: `[name].test.ts`
- Integration tests: `tests/integration/`
- E2E tests: `tests/e2e/` (Playwright)

## Rules

- Test component behavior, not implementation.
- Use `@testing-library/react` — query by role/label, not class names.
- Do NOT test internal state directly.
- Server Components: use integration tests, not unit tests.
- Approved Fixtures define expected outputs — agents may NOT change them.

## Coverage

- Shared components: minimum 70% coverage
- Services: minimum 80% coverage

---

## Sensor

Enforced by: `feedback/sensors/test.sensor.md` (Level 3)
