# Session Handoff — Save Progress & Start a New Agent

> Use when a chat session is getting long or the agent starts guessing.
> Goal: **zero lost work** — the next agent reads files, not chat history.

---

## When to hand off

Hand off (do not keep coding in the same chat) if:

- Context feels full, answers get vague, or the agent repeats mistakes
- One contract sub-item or file is done and more work remains on the same task
- The human runs `rig-spec handoff` or asks to "save progress and new session"

---

## What the agent must write before ending

### 1. `[CHECKPOINT]` inside `memory/progress.md`

Under the active feature section, add or replace:

```markdown
[CHECKPOINT] YYYY-MM-DD — task-id-or-name

**Stopped after:** [what was completed — files, contract items]
**Next action:** [single concrete next step — file + change]
**Do not redo:** [what is already done and must not be rebuilt]
**Open questions:** [decisions needed from human, or none]
**Files touched:** [paths]
```

Also update `[~]` task line with checked sub-items for everything finished.

### 2. `memory/learnings.md` (if anything non-obvious was discovered)

Short bullets only — patterns, gotchas, API quirks.

### 3. Task file checkboxes

Check every contract item that is truly done in the `.task.md` file (`- [ ]` → `- [x]`). Unchecked boxes after `rig-spec done` break the feedback loop.

### 4. HARNESS.md (same session or human runs `rig-spec sync`)

Set **Active Feature** and **Next Task** to match `progress.md` — not `none` while work is pending.

### 5. Session close ritual (end of feature or long session)

Before closing the chat:

- [ ] Contract items done → checked in the `.task.md`
- [ ] `progress.md` reflects reality (`[x]` / `[~]` / **Last Session**)
- [ ] `HARNESS.md` **Active Feature** + **Next Task** aligned (`rig-spec sync`)
- [ ] No stale CHECKPOINT unless you are mid-handoff

### 6. State check (before final line)

Human or agent runs from project root:

```bash
rig-spec sync
rig-spec check
```

CI / strict repos: `rig-spec check --strict`

### 7. Final chat line (exact)

```
HANDOFF SAVED — close this chat and run: rig-spec resume
```

---

## What the human does

1. Verify `memory/progress.md` has the `[CHECKPOINT]` block
2. **Close** the current chat (do not continue implementing there)
3. Open a **new** chat / new agent
4. Run `rig-spec resume` and paste the output — or in Cursor/Claude Code: read `.rig/memory/bootstrap.md` then progress + current task

---

## Resume checklist (new session)

1. `.rig/memory/bootstrap.md` reading order
2. `.rig/memory/progress.md` — find `[CHECKPOINT]`
3. Active task file — contract items still `[ ]`
4. Implement **only** "Next action" from the checkpoint first
