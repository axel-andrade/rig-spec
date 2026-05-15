# Structure Rules

> Loaded into every agent context before task execution.
> Defines where each file type must live in the folder structure.
> DRAFT — fill in the structure for this project. Remove the [DRAFT] markers when reviewed.

---

## Folder Layout

```
[Draw your project's actual folder structure here]
src/
├── [module]/
│   ├── [what goes here — e.g., *.controller.ts]
│   ├── [what goes here — e.g., *.service.ts]
│   └── [what goes here — e.g., *.spec.ts]
└── shared/
    └── [what goes here]
```

## Placement Rules

[Where each file type must live. Be specific.]

- `*.controller.[ext]` must live in: `src/[module]/`
- `*.service.[ext]` must live in: `src/[module]/`
- `*.spec.[ext]` must live in: [next to source file / `__tests__/` — choose one]
- Shared utilities must live in: `src/shared/`
- [Add all rules]

## Forbidden Placements

[File types that must NOT appear in certain locations.]

- Business logic must NOT appear in `src/[infrastructure-layer]/`
- [Add all forbidden placements]

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
Tool: Custom script derived from these rules
