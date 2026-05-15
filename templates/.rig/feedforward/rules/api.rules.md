# API Rules

> Loaded into every agent context before task execution.
> Defines API design conventions, response formats, and error handling.
> DRAFT — fill in the conventions for this project. Remove the [DRAFT] markers when reviewed.

---

## Response Envelope

[Define the standard response format for all endpoints.]

```json
{
  "data": {},
  "error": null
}
```

## Error Format

[Define the standard error response.]

```json
{
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

## HTTP Status Codes

[Define which status codes are used and when.]

- `200` — successful operation
- `201` — resource created
- `400` — validation error (client mistake)
- `401` — not authenticated
- `403` — not authorized
- `404` — resource not found
- `500` — unexpected server error (never expose details)

## Endpoint Conventions

[Define URL patterns for each operation type.]

- List:   `GET    /[resource]`
- Single: `GET    /[resource]/:id`
- Create: `POST   /[resource]`
- Update: `PUT    /[resource]/:id`
- Delete: `DELETE /[resource]/:id`

## Rules

- IDs are [UUIDs / sequential integers — choose one] in public APIs
- Pagination: [cursor-based / offset — choose one]
- Dates: ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`)
- [Add project-specific rules]

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (Level 3, inferential)
