# Architecture Rules — Next.js (App Router)

---

## Layer Hierarchy

```
Pages/Components → Server Actions / API Routes → Services → Repositories → Database
```

- `app/` — Next.js App Router pages and layouts. No business logic.
- `components/` — React components. Receive data as props or via server components.
- `lib/` or `server/` — Server-side services and repositories. Never imported by client components.
- `api/` routes — thin HTTP handlers that call services.

## Client vs Server

- Server Components fetch data directly. Client Components receive data as props.
- Mark files `"use client"` only when browser APIs or interactivity is needed.
- Never import server-only modules (DB, secrets) in client components.

## Module Boundaries

- `components/` may NOT import from `lib/server/` or repositories.
- `app/` pages are thin — data fetching in Server Components, logic in lib/services.
- `lib/` services are framework-agnostic — no Next.js imports.

## Forbidden Patterns

- Direct database access inside a React component
- `"use client"` on a component that does not need it
- Environment secrets accessed on the client side
- Business logic inside API route handlers

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
