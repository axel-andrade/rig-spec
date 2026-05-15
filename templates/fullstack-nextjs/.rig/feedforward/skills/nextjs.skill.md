# Skill: Next.js (App Router)

> Load when working on pages, layouts, routing, or server-side logic.

---

## Context

This project uses Next.js 14+ with the App Router. Server Components are the default.
Data fetching happens server-side; client components handle interactivity only.

---

## Patterns to Follow

### Data fetching in Server Components
```tsx
// app/users/page.tsx
export default async function UsersPage() {
  const users = await userService.list()  // direct service call
  return <UserList users={users} />
}
```

### Server Actions for mutations
```tsx
// app/users/actions.ts
"use server"
export async function createUser(formData: FormData) {
  await userService.create({ name: formData.get("name") as string })
  revalidatePath("/users")
}
```

### Route handlers
```typescript
// app/api/users/route.ts
export async function GET() {
  const users = await userService.list()
  return Response.json({ data: users, error: null })
}
```

---

## Pitfalls to Avoid

- Do NOT add `"use client"` to components that do not need it.
- Do NOT import server modules into client components.
- Do NOT use `useEffect` for initial data fetching — use Server Components.

---

## Key Files

- `app/` — all routes and layouts
- `lib/` — server-side services and utilities
- `components/` — shared UI components
