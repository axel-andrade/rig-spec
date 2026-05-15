# Structure Rules — Python

---

## Folder Layout

```
src/
├── routers/
│   └── [name]_router.py
├── services/
│   └── [name]_service.py
├── repositories/
│   └── [name]_repository.py
├── models/
│   └── [name].py
├── schemas/
│   └── [name]_schema.py
└── main.py
tests/
├── integration/
└── test_[name].py
```

## Placement Rules

- Routers live in: `src/routers/` or `src/[module]/`
- Services live in: `src/services/` or `src/[module]/`
- Repositories live in: `src/repositories/` or `src/[module]/`
- Pydantic schemas live in: `src/schemas/`
- Tests live in: `tests/`, mirroring `src/` structure

---

## Sensor

Enforced by: `feedback/sensors/structure.sensor.md` (Level 3)
