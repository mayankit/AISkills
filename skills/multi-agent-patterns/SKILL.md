---
name: multi-agent-patterns
description: Orchestration patterns for splitting complex work across multiple agents — specialist delegation, contract-first decomposition, same-turn parallel dispatch, and the integrative join. Use when a task fans out across independent modules or benefits from distinct roles (implementer, reviewer, architect, investigator).
---

# Multi-Agent Patterns

**Loop stage:** Fan-Out — orchestration patterns that split coding work across the right agent
roles, run them in true parallel, and integrate (Loop 3). This skill is the orchestration VIEW of that loop; the loop taxonomy
entry conditions, and stop reasons live here.

**Loop subgraph** (grammar in `agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **Fan-Out orchestration: the L3 dispatch/join mechanics.**

## Overview

How to decompose a large task, delegate pieces to the right agent roles, run them in true
parallel, and join the results. The orchestrator owns decomposition, integration, and the
final combined verification; delegates own only their piece. Every rule here exists to
protect one invariant: **each delegated piece is independent and composes against an agreed
interface contract.**

## Usage

Use this skill when:
- A task is too large for one session or spans modules needing different expertise
- Independent work streams could run in parallel
- A change benefits from separate perspectives (implementation, review, architecture)

## Pattern 1: Specialist Delegation

Route each sub-task to the role best suited for it:

| Task Type | Delegate To | Why |
|---|---|---|
| Implementation | `builder-dev` | Full context, TDD per `build-discipline` |
| Code quality | `code-reviewer` | Fresh eyes, standards focus (`code-review`) |
| Architecture | `architect` | Broad system thinking, trade-offs (`design`) |
| Security | Security reviewer | Threat-model depth (`security-review`) |
| Debugging | Investigator | Log analysis, root-cause discipline (`debugging-recovery`) |
| Research | Read-only investigator | Context exploration without polluting the main session |

Delegate when the sub-task needs expertise you don't have loaded, or when a quality check
benefits from fresh eyes, not just your own current context.

## Pattern 2: Decompose Contract-First

Agree on the interface contracts BEFORE splitting the work:
- Define every piece's true boundaries: function signatures, data shapes, error semantics.
- No two pieces touch the same file (shared mutable state cannot be parallelized).
- Each piece builds and tests in isolation.
- Each piece is verified against the contract, not against another piece's internals.

If two pieces can't be separated by a contract, they are one piece. Don't split them.

## Pattern 3: Same-Turn Parallel Dispatch

Delegating to N agents only runs concurrently if you emit all N dispatch calls in a single
message. The serialization bug: dispatch one, await its result, dispatch the next — that
"uses subagents" but executes them serially with zero speedup. For 5 independent pieces,
issue 5 dispatches in ONE message. Only sequence a piece that genuinely consumes an earlier
piece's output. (Canonical mechanics: `agentic-loops`, Loop 3.)

## Pattern 4: The Join

The orchestrator — never the delegates — owns integration:
- Collect every piece; check each against its contract before merging.
- Integrate into one working tree; run parallel checkouts (isolated until now).
- Run ONE serial combined verification — full build plus tests across the merged result.
- A green combined verification proves nothing about the composition; only the join proves it.

Stop condition for `agentic-loops`'s every piece integrated and the combined verification green.

## Pattern 5: The Handoff Prompt

A delegated prompt must be self-sufficient — the delegate has none of your context. Include:
- **Goal** — the outcome, in one sentence, plus acceptance criteria
- **Contract** — the exact interface this piece must implement or consume
- **Files** — which files to read for context and which to modify
- **Non-conditions** — the command that must pass before the delegate reports back
- **What NOT to touch** — files owned by other pieces or the orchestrator

A vague handoff produces a piece that fails the join. Time spent on the prompt is cheaper
than time spent re-integrating.

## The Two-Strike Rule for Delegation

If a piece comes back wrong twice, stop re-delegating it. Either pull it into the main
session and do it yourself, or re-scope it — the recurring failure means the decomposition
or the contract was wrong, not the delegate. Re-sending the same prompt a third time is
delegation patching.

## When NOT to Fan Out

Coordination cost must beat the speedup. Skip orchestration when:
- The task is small — subagent overhead exceeds the work itself
- Pieces share mutable files — serialize instead
- The contract can't be defined up front — do it in one session, iteratively
- Delegates would need most of your context anyway — the handoff duplicates more than it saves

Prefer fewer, focused delegates over many tiny ones; inter-agent communication is paid in
context tokens.

## Anti-patterns

- **Serial "parallelism"** — dispatch → await → dispatch. All independent pieces go in one message.
- **Splitting before the contract** — pieces built against no interface guarantee a merge conflict.
- **Shared-file fan-out** — two delegates editing one file guarantees a merge conflict.
- **Skipping the join** — trusting per-piece checkouts without the combined verification.
- **Third-strike re-delegation** — re-sending a failed prompt instead of re-scoping (two-strike).
- **Context-free handoffs** — a goal with no contract, files, or done-condition.
- **Fan-out as a reflex** — orchestrating a task a single session finishes faster.
