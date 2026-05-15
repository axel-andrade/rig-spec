# Skill: TypeScript

> Load when writing any TypeScript code in this project.

---

## Context

This project uses TypeScript throughout. All new code must be typed.
Strict mode is enabled — no implicit `any`.

---

## Patterns to Follow

### Strict typing
- Never use `any`. Use `unknown` when the type is truly unknown, then narrow it.
- Prefer interfaces for object shapes; types for unions and utility types.
- Use `readonly` for properties that should not be mutated.

### Null safety
- Avoid `!` (non-null assertion). Handle `null`/`undefined` explicitly.
- Use optional chaining `?.` and nullish coalescing `??`.

### Generics
- Use generics when a function works with multiple types.
- Name generic params descriptively: `TEntity`, `TResult` over `T`.

---

## Pitfalls to Avoid

- Do NOT use `any` to silence type errors — fix the type.
- Do NOT use `@ts-ignore` without a comment explaining why.
- Do NOT cast with `as` unless you have verified the shape at runtime.

---

## Key Files

- `tsconfig.json` — compiler options
