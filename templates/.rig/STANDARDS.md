# Project Standards — Index

> Canonical map of **where every project pattern lives**.
> Before implementing any task, read the rules that apply. After implementation, sensors and review verify compliance.

---

## How to use this file

1. **Implementer** — On `rig-spec run`, all applicable `feedforward/rules/*.rules.md` files are injected into context. Skim this index first, then read the files relevant to your task domain.
2. **Planner** — When writing tasks, reference which rule files the task must follow under `## Standards to follow`.
3. **Retrofit** — Run `rig-spec init --retrofit` to seed `structure.rules.md` from the real tree; fill other files and remove `[DRAFT]` when approved.
4. **Validator** — Use `feedback/review/code-review.review.md` plus the validation report from `rig-spec validate`.

---

## Standards topology

| Concern | File | When required |
|---|---|---|
| Module boundaries, layering, dependency direction | `feedforward/rules/architecture.rules.md` | Every backend / full-stack task |
| File, class, function, variable naming | `feedforward/rules/naming.rules.md` | Every code change |
| Folder layout, where each artifact lives | `feedforward/rules/structure.rules.md` | New files or modules |
| REST/GraphQL shape, errors, versioning | `feedforward/rules/api.rules.md` | Routes, controllers, handlers |
| Test location, coverage expectations, fixtures | `feedforward/rules/testing.rules.md` | Any task with tests |
| React/UI components, props, composition | `feedforward/rules/component.rules.md` | Frontend (if file exists) |
| Colors, spacing, typography tokens | `feedforward/rules/design-tokens.rules.md` | UI/styling (if file exists) |

**Rule:** If a `*.rules.md` file exists in `feedforward/rules/`, agents must read and follow it for tasks in that domain. Missing files mean no convention is defined yet — add one before scaling the team.

---

## Frontend-specific standards

When the project has a UI layer, keep visual and structural rules separate:

| Topic | File | Examples |
|---|---|---|
| Design tokens | `feedforward/rules/design-tokens.rules.md` | CSS variables, Tailwind theme, color palette, spacing scale |
| Components | `feedforward/rules/component.rules.md` | Server vs client, folder layout, prop typing |
| Global styles | Document in `design-tokens.rules.md` or `component.rules.md` | Reset, fonts, dark mode |

Point agents at real sources of truth in the repo when they exist, e.g. `src/styles/tokens.css`, `tailwind.config.ts`, `components/ui/`.

---

## Enforcement (feedback layer)

| Check | Sensor / review | Type |
|---|---|---|
| Lint / format | `feedback/sensors/lint.sensor.md` | Computational |
| Types | `feedback/sensors/typecheck.sensor.md` | Computational |
| Unit / integration tests | `feedback/sensors/test.sensor.md` | Computational |
| API smoke / contract | `feedback/sensors/endpoint.sensor.md` | Computational |
| Module boundaries | `feedback/sensors/arch.sensor.md` | Computational |
| Matches spec AC + fixtures | `feedback/sensors/spec-compliance.sensor.md` | Inferential |
| Matches all `rules/` semantically | `feedback/sensors/standards-compliance.sensor.md` | Inferential |
| Deep review | `feedback/review/code-review.review.md` | Inferential (always on validate) |

Run everything with:

```bash
rig-spec validate <task-id>
```

This produces a **validation report** under `feedback/reports/` with a pass/fail matrix and review checklist.

---

## Adding or changing a standard

1. Edit the relevant `feedforward/rules/*.rules.md` file.
2. If enforcement should be automatic, add or update a sensor in `feedback/sensors/`.
3. Note the change in `memory/decisions.md` when it is an architectural decision.
4. Remove `[DRAFT]` markers only after human review.

---

## Related

- Skill routing (which expertise to load per task): `feedforward/skills.registry.md`
- Harness entry point: `HARNESS.md`
- Task contract template: `feedforward/tasks/_TEMPLATE.task.md`
