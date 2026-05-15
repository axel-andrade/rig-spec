# API Rules — REST / FastAPI

---

## Response Envelope

All endpoints return the same envelope:

```json
{ "data": { ... }, "error": null }
```

On error:
```json
{ "data": null, "error": { "code": "ERROR_CODE", "message": "Human-readable message" } }
```

## HTTP Methods

- `GET    /[resource]`         — list (paginated)
- `GET    /[resource]/{id}`    — single item
- `POST   /[resource]`         — create
- `PUT    /[resource]/{id}`    — full replace
- `PATCH  /[resource]/{id}`    — partial update
- `DELETE /[resource]/{id}`    — delete

## Status Codes

- `200` OK
- `201` Created
- `204` No Content (DELETE)
- `400` Bad Request (validation)
- `401` Unauthorized
- `403` Forbidden
- `404` Not Found
- `422` Unprocessable Entity (FastAPI default for validation errors)
- `500` Internal Server Error

## Input Validation

- Use Pydantic schemas for all request bodies.
- Path and query parameters validated with type annotations.
- Never trust client input — validate before passing to service.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
