# Adapter: Claude Code

> Optional. Supplements HARNESS.md with Claude Code-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

When starting a session in this project, use the slash command:

```
/init
```

Or read manually:

```
Read .rig/HARNESS.md first, then follow the bootstrap sequence in .rig/memory/bootstrap.md
```

## Memory System

Claude Code's built-in memory (`.claude/`) stores user preferences. `.rig/memory/` stores project state. They are separate:

- `.claude/` — how you work with Claude across all projects
- `.rig/memory/` — the state of this specific project

## Recommended Permissions

For this project, Claude Code should be allowed to run the sensors defined in `feedback/sensors/` without prompting. Add them to `.claude/settings.local.json`:

```json
{
  "allowedTools": [
    "Bash(npx eslint*)",
    "Bash(npx tsc*)",
    "Bash(npm test*)"
  ]
}
```

## CLAUDE.md

If you use a `CLAUDE.md` file at the project root, add this line to it:

```
Read .rig/HARNESS.md at the start of every session.
```

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Open a new conversation for the implementer → load `orchestration/implementer.md`
2. Open a separate conversation for the validator → load `orchestration/validator.md`
3. Pass the signed contract between them

Claude Code Projects can maintain separate conversation threads for this.
