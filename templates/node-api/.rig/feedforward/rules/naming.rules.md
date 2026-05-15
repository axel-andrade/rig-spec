# Naming Rules — Node.js / TypeScript

---

## Files

- Controllers: `[name].controller.ts`
- Services: `[name].service.ts`
- Repositories: `[name].repository.ts`
- DTOs (input): `[name].dto.ts`
- Interfaces: `[name].interface.ts`
- Types: `[name].types.ts`
- Tests: `[name].spec.ts` or `[name].test.ts`
- Modules (NestJS): `[name].module.ts`

## Classes

- PascalCase with suffix: `UserService`, `OrderRepository`, `CreateUserDto`

## Functions and Methods

- camelCase: `getUserById`, `createOrder`, `validateEmail`
- Boolean helpers: `is`, `has`, `can` prefix: `isActive`, `hasPermission`

## Variables and Constants

- camelCase for variables: `userId`, `orderTotal`
- SCREAMING_SNAKE_CASE for module-level constants: `MAX_RETRY_COUNT`
- Env vars: `SCREAMING_SNAKE_CASE`

## Interfaces vs Types

- Use `interface` for object shapes that may be extended
- Use `type` for unions, intersections, and utility types

---

## Sensor

Enforced by: `feedback/sensors/naming.sensor.md` (Level 3)
