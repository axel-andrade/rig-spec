# rig-spec — Vision

> An operational framework for AI-native development.
> Not a set of prompts. The environment that makes AI agents reliable.

---

## The Problem

Picture this: you give a prompt to an AI agent, asking for a complete feature with authentication, a dashboard, and payment integration. The agent works for 40 minutes. When it finishes, you open a diff of 3,000 changed lines. Half of it works. Half doesn't compile. There's duplicated logic. It overwrote tests. It declared everything done.

**This is not a bug in the model. Today's models are extremely capable.**

The problem is that nobody taught the agent how to work.

---

## What is Harness Engineering

The **model** is the LLM — Claude, GPT-5, Gemini, whatever.

The **harness** is everything else: the instructions, the repository structure, the linters, the tests, the progress files, the setup scripts. It is the operational environment that surrounds the model.

```
Agent = Model + Harness
```

Think of it this way: the model is a brilliant newly hired engineer. It can write anything. But if you drop it into a repository with no README, no documented architecture, no CI, no tests — it will make mistakes. Not because it's incapable. Because it has no context.

**The harness is that engineer's onboarding.**

It is what transforms a powerful model into a reliable agent.

---

## The 13 Agent Failure Patterns

`rig-spec` was designed to solve every documented failure pattern of agents running without a harness.

### Classic Patterns (from Anthropic)

#### 1. One Shot Hero
The agent tries to implement everything at once. It blows through the context window halfway through. Features are left incomplete. The next session finds a minefield.

**rig-spec solves it:** specs break work into tasks with a clear, bounded scope.

#### 2. Premature Victory
The agent looks at something incomplete and declares it "done." It gets lost in a huge context window and stops halfway.

**rig-spec solves it:** contracts define what "done" means. The validator checks every item against the contract.

#### 3. Session Amnesia
Every new session starts from zero. The agent doesn't know what was done, what failed, or what the current state is. Half of the tokens are wasted just figuring out where it left off.

**rig-spec solves it:** `memory/progress.md`, `decisions.md`, and `bootstrap.md` automatically reconstruct context at the start of every session.

#### 4. Untested Features
The agent runs a `curl`, sees a `200`, and moves on. The feature doesn't work end-to-end. Nobody forced a real test.

**rig-spec solves it:** sensors (linters, tests, type checkers) run automatically after every implementation. The agent doesn't decide when it's done — the system does.

#### 5. Single Process
An agent cannot objectively judge its own work. When asked to implement, it tries to implement — including deleting tests or "cheating" to make things pass.

**rig-spec solves it:** two agents in separate processes. One implements. One validates. Different missions, no self-evaluation bias.

#### 6. Accumulated Slope
The code compiles, but violates architecture rules. There's duplicated logic. Quality tests don't pass. Each session makes things slightly worse. After 20 features, the codebase is unrecognizable.

**rig-spec solves it:** continuous sensors detect architectural drift. The harness maintains consistent quality regardless of the number of iterations.

---

### Extended Patterns (from Harness Engineering research)

#### 7. Context Window Pollution
The research phase and the implementation phase share the same context window. By the time implementation starts, the window is full of irrelevant exploration, failed paths, and dead ends. The agent hallucinates more and costs more tokens.

**rig-spec solves it:** the RPI pattern (Research → Plan → Implement) enforces separate sessions. Research findings are saved to `memory/research/` as clean markdown files. Implementation starts in a fresh window with only what matters.

#### 8. Spec Drift
The implementation diverges silently from the original spec. The feature ships, but doesn't match what was specified. Nobody catches it because there's no automated check linking spec to code.

**rig-spec solves it:** a spec compliance sensor runs after each task, verifying that the implementation satisfies the spec's acceptance criteria.

#### 9. Architecture Fitness Violation
The code compiles and tests pass, but it creates forbidden dependencies between modules, breaks layering rules, or introduces coupling that will hurt later. Linters don't catch this — it requires structural analysis.

**rig-spec solves it:** computational sensors using dependency analysis tools (dependency-cruiser, ArchUnit, import linters) enforce architectural boundaries automatically.

#### 10. Parallel Task Conflicts
When multiple tasks run in parallel, they may write to the same files or make conflicting decisions. Nobody declared ownership. The result is a merge conflict or silent overwrite.

**rig-spec solves it:** task contracts declare file ownership. Each task specifies which files it creates or modifies. Parallel tasks with overlapping ownership cannot run simultaneously.

#### 11. Spec Quality Gap
A spec with missing information, ambiguous user stories, or undefined edge cases leads directly to wrong implementations. The agent fills gaps with assumptions — and those assumptions are often wrong.

**rig-spec solves it:** an inferential sensor validates spec completeness before `plan` runs. It checks for required sections, vague language, and missing acceptance criteria.

#### 12. Behavioural Harness Gap
AI-generated tests often test the happy path and miss edge cases. The test suite is green, but the feature breaks in production. High test coverage doesn't mean the right things are being tested.

**rig-spec solves it:** the approved fixtures pattern — expected outputs are specified by humans before the agent writes tests. The agent's job is to make the code match the fixtures, not to invent what "correct" looks like.

#### 13. Continuous Drift
Technical debt accumulates outside the change lifecycle. Dead code grows. Dependencies go unpatched. Architecture degrades slowly. No single commit is the problem — it's the accumulation.

**rig-spec solves it:** `rig-spec audit` runs continuous drift sensors against the codebase on a schedule, outside the task cycle. It reports health trends over time.

---

## What rig-spec Is

`rig-spec` is an **operational framework for AI-native development**.

It is a layer you add to any project — new or existing — that structures how AI agents work within it.

### Two Types of Controls

**Feedforward (Guides)** — steers the agent BEFORE execution:
- Specs: what to build
- Tasks: how to divide the work
- Rules: coding conventions and architecture constraints
- Skills: specialized context and reusable patterns
- MCP configuration: real-time context injection

**Feedback (Sensors)** — observes and corrects AFTER execution:
- Linters: detect style and structural problems
- Tests: verify behavior
- Type checkers: enforce type contracts
- Architecture sensors: enforce module boundaries
- Review agents: semantic analysis by AI

```
Feedforward without Feedback = agent encodes rules but never knows if they worked
Feedback without Feedforward  = agent corrects errors but has no direction
rig-spec combines both
```

---

## What rig-spec Is NOT

- ❌ A collection of prompts
- ❌ A code boilerplate
- ❌ An LLM wrapper
- ❌ An IDE or visual interface
- ❌ A tool that only works with Claude Code
- ❌ A solution that requires reorganizing your existing project

---

## Philosophy

### 1. Agnostic by design
`rig-spec` works with any AI agent — Claude Code, Gemini, Antigravity, Cursor, whatever comes next. No lock-in. Files are Markdown and YAML. Any tool can read them.

### 2. Non-invasive
Lives in a `.rig/` folder at the project root. Does not touch code. Does not reorganize folders. Can be added to existing projects with zero modifications.

### 3. Progressive
You don't need to use everything at once. The framework has 3 levels. You start with the minimum and add complexity only when you need it.

### 4. Didactic by nature
The structure of `rig-spec` teaches Harness Engineering concepts as you use it. The `feedforward/` and `feedback/` folders are not just organization — they are a lesson.

### 5. The system decides, not the agent
Deterministic sensors (linters, tests) decide when an implementation is ready. The agent does not judge its own work.

---

## Who It's For

- Developers who use AI agents daily and want more reliable results
- Teams that want to standardize how AI works across their projects
- People learning Harness Engineering, Context Engineering, and AI-native development hands-on

---

## The Metaphor

**Rig** — the complete operational apparatus assembled for a specific job. A drilling rig has everything the drill bit needs to work: structure, support, controls, sensors, safety systems. The drill bit (the model) is powerful. The rig (the harness) is what makes it reliable and productive.

**Spec** — spec-driven development as the foundation. Nothing happens without a clear specification. The spec is the source of truth for the agent, for the validator, and for the human.

`rig-spec` = the complete apparatus, driven by specifications.
