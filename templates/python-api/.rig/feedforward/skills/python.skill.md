# Skill: Python

> Load when writing any Python code in this project.

---

## Context

Python 3.11+. All async I/O uses `async/await`. Type hints required on all function signatures.

---

## Patterns to Follow

### Type hints
```python
def get_user(user_id: int) -> UserResponse:
    ...

async def create_order(data: CreateOrderDto) -> Order:
    ...
```

### Error handling
- Define custom exception classes for domain errors.
- Never catch bare `except:` — always catch a specific exception type.
- Log errors before re-raising or converting.

### Async
- All I/O-bound operations are `async`.
- Never call blocking I/O inside an async function — use async libraries.

---

## Pitfalls to Avoid

- Do NOT use mutable default arguments: `def f(items=[])` is a bug.
- Do NOT ignore return values of functions that signal errors.
- Do NOT use `print()` for logging — use the `logging` module.

---

## Key Files

- `pyproject.toml` — project config, dependencies, tool settings
