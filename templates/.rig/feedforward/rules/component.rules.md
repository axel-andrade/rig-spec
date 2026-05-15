# Component Rules

> Frontend only. Remove this file if this is a backend-only project.
> Loaded into every agent context before task execution.
> Defines component structure, responsibilities, and composition patterns.
> DRAFT — fill in the rules for this project. Remove the [DRAFT] markers when reviewed.

---

## Component Responsibilities

[Define the split between component types.]

- Presentational components: rendering only, no business logic, no data fetching
- Container components: data fetching and state management, no layout styling
- [Define any additional component types specific to this project]

## File Structure per Component

```
[ComponentName]/
├── index.ts               ← public exports only
├── [ComponentName].tsx    ← component implementation
├── [ComponentName].test.tsx
└── [ComponentName].module.css   ← if using CSS modules
```

## Props Rules

- All props must have explicit TypeScript interfaces — no `any`
- Optional props must have defined defaults
- [Add project-specific prop rules]

## State Rules

- Component state: only for local UI state (e.g., open/closed, hover)
- Shared state: use [context / zustand / redux — choose one]
- Server state: use [react-query / SWR / tRPC — choose one]

## Rules

- Do NOT put API calls directly in components — use [hooks / services / query layer]
- Do NOT use `any` type for props
- [Add project-specific component rules]

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3, inferential)
