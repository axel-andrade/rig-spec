# Skill: React

> Load when writing React components or hooks.

---

## Context

React 18+. Components are Server Components by default in Next.js App Router.
Add `"use client"` only when hooks or browser APIs are needed.

---

## Patterns to Follow

### Component structure
```tsx
interface UserCardProps {
  user: User
  onSelect?: (id: string) => void
}

export function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div onClick={() => onSelect?.(user.id)}>
      {user.name}
    </div>
  )
}
```

### Custom hooks
```tsx
// hooks/useUser.ts
export function useUser(id: string) {
  return useQuery({ queryKey: ["user", id], queryFn: () => fetchUser(id) })
}
```

---

## Pitfalls to Avoid

- Do NOT mutate state directly — always use `setState` or `useReducer`.
- Do NOT use `index` as a `key` in lists with dynamic items.
- Do NOT derive state in `useEffect` — derive it during render.

---

## Key Files

- `components/` — shared and domain components
