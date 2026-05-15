# Adapter: Antigravity

> Optional. Supplements HARNESS.md with Antigravity-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

At the start of every session, use:

```
/init .rig/HARNESS.md
```

Or include in your first message:

```
Read .rig/HARNESS.md first, then .rig/memory/bootstrap.md before proceeding.
```

## Skills Integration

Antigravity's skill system maps directly to the rig-spec skills:

- Local skills in `.rig/feedforward/skills/` → load as Antigravity skills per task
- External skills referenced in `HARNESS.md` → load from your skill library

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Configure two separate Antigravity agents with different profiles
2. Implementer agent: load `orchestration/implementer.md` as the agent profile
3. Validator agent: load `orchestration/validator.md` as the agent profile
4. Use Antigravity's multi-agent handoff to pass the signed contract

## Sensor Hooks

Configure Antigravity hooks to auto-run sensors after each task:

```yaml
on_task_complete:
  - run: sensors/lint.sensor.md
  - run: sensors/typecheck.sensor.md
  - run: sensors/test.sensor.md
```
