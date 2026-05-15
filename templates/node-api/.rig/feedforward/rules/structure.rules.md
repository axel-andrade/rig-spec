# Structure Rules — Node.js

---

## Folder Layout

```
src/
├── [module]/
│   ├── [name].controller.ts
│   ├── [name].service.ts
│   ├── [name].repository.ts
│   ├── [name].dto.ts
│   └── [name].spec.ts
├── shared/
│   └── [utility files]
└── main.ts
```

## Placement Rules

- Controllers live in: `src/[module]/`
- Services live in: `src/[module]/`
- Repositories live in: `src/[module]/`
- Shared utilities live in: `src/shared/`
- Tests live next to the file they test

## Forbidden

- Business logic files outside `src/`
- Test files in a top-level `tests/` folder (keep them co-located)

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
