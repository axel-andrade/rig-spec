# Skill: FastAPI

> Load when writing FastAPI routers, dependencies, or middleware.

---

## Context

This project uses FastAPI for the HTTP layer. Routes are organized by domain in `routers/`.
Dependency injection is used for services, database sessions, and authentication.

---

## Patterns to Follow

### Router organization
```python
router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, service: UserService = Depends(get_user_service)):
    return await service.get_by_id(user_id)
```

### Dependency injection
- Database sessions injected via `Depends(get_db)`.
- Services injected via `Depends(get_[name]_service)`.
- Authentication via `Depends(get_current_user)`.

### Error handling
- Raise `HTTPException` in routers for HTTP-layer errors.
- Services raise domain exceptions (e.g., `UserNotFoundError`).
- A middleware or exception handler converts domain errors to HTTP responses.

---

## Pitfalls to Avoid

- Do NOT put business logic in router functions.
- Do NOT use global state for the database session.
- Do NOT return raw SQLAlchemy model objects — use Pydantic schemas.

---

## Key Files

- `main.py` — app creation and router registration
- `dependencies.py` — shared FastAPI dependencies
