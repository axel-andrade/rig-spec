# Skill: Node.js

> Load when working on server-side code, modules, or runtime behavior.

---

## Context

This is a Node.js server application. All async operations use `async/await`.
Error handling follows the layered pattern — errors bubble up to the controller/route handler.

---

## Patterns to Follow

### Async/await
- Always `await` promises. Never leave floating promises.
- Wrap async route handlers to catch unhandled rejections.

### Error handling
- Services throw typed errors (e.g., `UserNotFoundError extends Error`).
- Controllers/route handlers catch and convert to HTTP responses.
- Never swallow errors silently — log or rethrow.

### Environment config
- All config from environment variables, validated at startup.
- Never hardcode secrets, URLs, or credentials.
- Use a config module/object — not `process.env` scattered through the codebase.

---

## Pitfalls to Avoid

- Do NOT use `require()` — use ES module `import`.
- Do NOT use `process.exit()` in library code.
- Do NOT block the event loop with synchronous I/O.

---

## Key Files

- `package.json` — scripts and dependencies
