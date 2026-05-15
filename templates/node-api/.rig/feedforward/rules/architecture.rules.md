# Architecture Rules — Node.js (Layered)

---

## Layer Hierarchy

```
Controllers → Services → Repositories → Database
```

- `controllers/` handle HTTP: parse request, call service, return response. No business logic.
- `services/` contain all business logic. No HTTP concerns. No direct DB access.
- `repositories/` handle all database queries. Return domain objects, not raw rows.
- `shared/` utilities may be imported by any layer.

## Module Boundaries

- A controller may ONLY import from its own service.
- A service may ONLY import from repositories and shared/.
- A repository may NOT import from controllers or services.
- Cross-module imports go through interfaces, not concrete implementations.

## Forbidden Patterns

- Direct database access from a controller
- HTTP request/response objects inside a service
- Business logic inside a controller
- Raw SQL inside a service (use the repository)

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
