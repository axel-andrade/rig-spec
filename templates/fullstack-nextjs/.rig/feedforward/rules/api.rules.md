# API Rules — Next.js API Routes

---

## Response Envelope

```typescript
{ data: T | null, error: { code: string; message: string } | null }
```

## Route Handler Pattern

```typescript
// app/api/[resource]/route.ts
export async function GET(request: Request) {
  try {
    const data = await service.list()
    return Response.json({ data, error: null })
  } catch (err) {
    return Response.json({ data: null, error: { code: 'INTERNAL', message: 'Unexpected error' } }, { status: 500 })
  }
}
```

## HTTP Methods

- `GET`    — read (list or single)
- `POST`   — create
- `PUT`    — full replace
- `PATCH`  — partial update
- `DELETE` — delete

## Server Actions vs API Routes

- Prefer Server Actions for form mutations — no extra route needed.
- Use API Routes for: external webhooks, mobile clients, public APIs.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
