# Adapter: Gemini

> Optional. Supplements HARNESS.md with Gemini-specific instructions.
> HARNESS.md is always the primary entry point — this file enhances the experience.

---

## Entry Point

At the start of every session, include this in your first message:

```
Read .rig/HARNESS.md first, then follow the bootstrap sequence in .rig/memory/bootstrap.md before doing anything else.
```

## Context Window

Gemini supports large context windows. For this project:

- Load all rules files at session start: `.rig/feedforward/rules/`
- Load relevant skills per task: `.rig/feedforward/skills/[skill].md`
- Do not load all files at once — prioritize what the current task needs

## Two-Agent Pattern

When running Level 3 (implementer + validator):

1. Use a separate Gemini session for each agent
2. Start the implementer session with: `orchestration/implementer.md`
3. Start the validator session with: `orchestration/validator.md`
4. Pass the contract as a file attachment between sessions

## Grounding

If using Gemini with Google Search grounding, turn it off during implementation sessions. Grounding is useful for research, but implementation sessions should rely only on the project context assembled from `.rig/`.
