# Naming Rules — Next.js / TypeScript / React

---

## Files

- Pages (App Router): `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- Components: `PascalCase.tsx` — `UserCard.tsx`, `OrderList.tsx`
- Server actions: `[name].actions.ts`
- API routes: `route.ts` (inside `app/api/[resource]/`)
- Services: `[name].service.ts`
- Repositories: `[name].repository.ts`
- Hooks: `use[Name].ts` — `useUser.ts`, `useOrderList.ts`
- Types: `[name].types.ts`
- Tests: `[name].test.tsx` or `[name].spec.tsx`

## Components

- PascalCase: `UserCard`, `OrderSummary`, `NavigationMenu`
- Default export for page-level components; named exports for shared components.

## Functions

- camelCase: `getUserById`, `formatCurrency`
- React event handlers: `handle[Event]`: `handleSubmit`, `handleUserClick`
- Boolean helpers: `is`, `has`, `can` prefix

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
