# API Rules — REST / Node.js

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
- `GET    /[resource]/:id`     — single item
- `POST   /[resource]`         — create
- `PUT    /[resource]/:id`     — full replace
- `PATCH  /[resource]/:id`     — partial update
- `DELETE /[resource]/:id`     — delete

## Status Codes

- `200` OK (GET, PUT, PATCH)
- `201` Created (POST)
- `204` No Content (DELETE)
- `400` Bad Request (validation)
- `401` Unauthorized (missing/invalid token)
- `403` Forbidden (insufficient permissions)
- `404` Not Found
- `422` Unprocessable Entity (business rule violation)
- `500` Internal Server Error (unexpected)

## Validation

- Validate all inputs at the controller/route level using DTOs or schema validation.
- Never trust client-provided IDs without authorization checks.
- Return `400` for schema violations, `422` for business rule violations.

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3)
