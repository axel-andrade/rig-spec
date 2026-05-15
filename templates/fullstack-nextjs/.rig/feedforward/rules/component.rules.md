# Component Rules — React / Next.js

---

## Component Types

### Server Components (default in App Router)
- Fetch data directly (database, API).
- Cannot use hooks, browser APIs, or event handlers.
- Pass data down to Client Components as props.

### Client Components (`"use client"`)
- Use only when hooks, state, or browser APIs are needed.
- Keep as small and leaf-level as possible.
- Never fetch directly from a database — receive data as props or via Server Actions.

## Props

- All props explicitly typed with TypeScript interfaces.
- No `any` in prop types.
- Optional props use `?` and have sensible defaults.

## State Management

- Local UI state: `useState`.
- Server state: React Query / SWR, or Server Components with revalidation.
- Avoid global state for data that belongs in the server layer.

## Composition

- Prefer composition over configuration — small focused components over large ones with many props.
- Extract reusable UI into `components/ui/`.
- Domain-specific components live in `components/[domain]/`.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
