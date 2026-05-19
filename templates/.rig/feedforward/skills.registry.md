# Skills Registry — Automatic routing

> Maps **task domains** to **skills** (local `.rig` files and optional external paths).
> `rig-spec run` uses this file to auto-load skills when the task text matches keywords.
> Explicit skills listed in the task file are always included.

---

## How routing works

1. Read the task file (and spec title if linked).
2. Lowercase the combined text.
3. For each row below, if **any** keyword appears in that text → include the skill.
4. Merge with skills listed under `## Skills to Load` in the task (no duplicates).
5. Inject all matched skills into `context-<task>.md`.

To disable auto-routing for a task, add `## Skills to Load` with only the skills you want and prefix the task with `skills: manual` in a comment.

---

## Local skills (project)

> Fill in after `rig-spec init`. Paths are relative to `.rig/`.

| Domain | Skill path | Match keywords |
|---|---|---|
| typescript | `feedforward/skills/typescript.skill.md` | typescript, ts, interface, generic, dto |
| backend | `feedforward/skills/nodejs.skill.md` | service, repository, controller, middleware, api, endpoint, backend |
| python | `feedforward/skills/python.skill.md` | python, fastapi, pydantic, asyncio, pytest |
| fastapi | `feedforward/skills/fastapi.skill.md` | fastapi, router, dependency, sqlalchemy |
| frontend | `feedforward/skills/react.skill.md` | react, component, hook, jsx, tsx, page, layout |
| nextjs | `feedforward/skills/nextjs.skill.md` | nextjs, next.js, app router, server component, route handler |
| testing | `feedforward/skills/testing.skill.md` | test, spec, fixture, mock, coverage, e2e |

---

## External skills (optional)

> Absolute or `~` paths to skills installed on the machine (Claude Code, Cursor, etc.).
> Uncomment and adjust paths for your environment.

| Domain | External skill | Match keywords |
|---|---|---|
| security | `~/.claude/skills/cc-skill-security-review/SKILL.md` | auth, login, password, token, jwt, oauth, permission |
| api-design | `~/.claude/skills/api-design-principles/SKILL.md` | rest, graphql, openapi, pagination, versioning |
| postgres | `~/.claude/skills/postgres-best-practices/SKILL.md` | postgres, sql, migration, index, query |
| prisma | `~/.claude/skills/prisma-expert/SKILL.md` | prisma, schema.prisma |
| accessibility | `~/.claude/skills/fixing-accessibility/SKILL.md` | a11y, aria, accessibility, wcag |
| e2e | `~/.claude/skills/playwright-skill/SKILL.md` | playwright, e2e, browser test |

---

## Manual overrides per task type

Use these hints when **planning** tasks so routing stays predictable:

| Task type | Minimum skills | Minimum rules |
|---|---|---|
| API endpoint | backend stack skill + `api.rules.md` | architecture, api, testing |
| DB migration | backend + postgres/prisma if applicable | architecture, structure |
| UI component | frontend + nextjs/react | component, design-tokens, naming |
| Full-stack feature | backend + frontend skills | all applicable `rules/` |

---

## Maintenance

- After adding a new `feedforward/skills/*.skill.md`, add a row to **Local skills**.
- Run `rig-spec run <task-id>` and confirm the assembled context lists expected skills.
- External skills are optional; the harness works with local skills only.
