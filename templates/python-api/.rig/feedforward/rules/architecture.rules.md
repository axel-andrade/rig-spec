# Architecture Rules — Python (Layered)

---

## Layer Hierarchy

```
Routers → Services → Repositories → Database
```

- `routers/` handle HTTP: parse request, call service, return response. No business logic.
- `services/` contain all business logic. No HTTP concerns. No direct DB access.
- `repositories/` handle all database queries. Return domain models, not raw rows.
- `core/` or `shared/` utilities may be imported by any layer.

## Module Boundaries

- A router may ONLY import from its own service.
- A service may ONLY import from repositories and shared/core.
- A repository may NOT import from routers or services.

## Forbidden Patterns

- Direct database session access from a router/endpoint
- HTTP request objects inside a service
- Business logic inside a router function
- Raw SQL inside a service (use the repository)

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
