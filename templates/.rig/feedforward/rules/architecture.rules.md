# Architecture Rules

> Loaded into every agent context before task execution.
> Defines module boundaries, layering constraints, and dependency direction.
> DRAFT — fill in the rules for this project. Remove the [DRAFT] markers when reviewed.

---

## Module Boundaries

[Define which modules can import from which. Be explicit about what is forbidden.]

- `[module-a]` may NOT import directly from `[module-b]`
- `[shared]` may be imported by any module
- [Add all boundary rules]

## Layering Rules

[Define the allowed dependency direction between architectural layers.]

- [Layer A] → [Layer B] → [Layer C] (allowed direction)
- A layer may only depend on the layer directly below it
- [e.g., Controllers → Services → Repositories → Database]

## Forbidden Patterns

[Patterns that must never appear in this codebase.]

- [e.g., Direct database access from controllers]
- [e.g., Business logic in infrastructure layer]

---

## Sensor

Enforced by: `feedback/sensors/arch.sensor.md` (Level 3)
Tool: dependency-cruiser or equivalent
