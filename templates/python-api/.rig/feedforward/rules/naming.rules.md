# Naming Rules — Python

---

## Files and Modules

- All file names: `snake_case.py`
- Routers: `[name]_router.py` or `[name].py` in `routers/`
- Services: `[name]_service.py`
- Repositories: `[name]_repository.py`
- Models: `[name].py` in `models/`
- Schemas (Pydantic): `[name]_schema.py` or `[name].py` in `schemas/`
- Tests: `test_[name].py`

## Classes

- PascalCase: `UserService`, `OrderRepository`, `CreateUserSchema`
- Pydantic models: PascalCase with semantic suffix: `UserResponse`, `CreateUserRequest`

## Functions and Methods

- snake_case: `get_user_by_id`, `create_order`, `validate_email`
- Boolean helpers: `is_`, `has_`, `can_` prefix: `is_active`, `has_permission`

## Variables and Constants

- snake_case for variables: `user_id`, `order_total`
- SCREAMING_SNAKE_CASE for module-level constants: `MAX_RETRY_COUNT`
- Env vars: `SCREAMING_SNAKE_CASE`

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
