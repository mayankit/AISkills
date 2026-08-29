---
name: aiskills-skill-routing
description: Maps incoming work to the correct skill(s) in this package. Use at session start or when switching tasks to ensure the right discipline is applied — the index that answers "how does the agent know when to use what?" Consult first when unsure which skill applies.
---

# Skill Routing

**Loop stage:** Router — not a loop step; maps a task to the right skill and its loop stage.
Consult first when unsure which skill applies. The always-on brain (`brain/loop-contract.md`)
owns skill activation; this file is the detailed index beneath its Task Graph.

## How a skill gets activated (the mechanism)

Skills are progressive-disclosure: the agent normally sees only each skill's one-line
`description` and loads the full body only when a task matches — it does NOT load every skill up
front. The brain's Task Graph names the **primary** skill for a task type; this table refines
that choice and names the **supporting** skills that splice in as the plan reaches their stage.
Supporting skills load *alongside* the primary one, never instead of it.

**Layering (for consuming teams):** a team can add domain-specific overlay skills plus their own
router. An overlay carries project- or team-specific knowledge (module names, commands,
conventions); it declares no loops of its own and loads *alongside* whichever package skill owns
the loop it feeds — e.g. a team's "our-service conventions" overlay loads with
`aiskills-build-discipline` on a build task, never in place of it.

## The routing table — intent → skill

| The user's intent looks like | Primary | Supporting |
|---|---|---|
| "build / add / implement / fix / refactor / bug" | `aiskills-build-discipline` | `aiskills-agentic-loops` (always), `aiskills-design` (if shaping is nontrivial), `aiskills-doubt-driven-development` (VERIFY step) |
| "why does X keep failing / don't stop until it's green" | `aiskills-agentic-loops` | `aiskills-build-discipline` |
| "how should I structure this / which pattern / is this over-engineered" | `aiskills-design` | `aiskills-build-discipline` (records the ADR) |
| "choose the pattern first / expensive-to-reverse decision / write the design doc" | `aiskills-design` | `aiskills-api-design` (when the output is a contract) |
| "design this API / endpoint / message schema / RPC" | `aiskills-api-design` | `aiskills-design` |
| "is this change safe / security-sensitive / high-stakes / I'm not sure about this claim" | `aiskills-doubt-driven-development` | — |
| "review this diff / look at what someone else wrote" | `aiskills-code-review` | `aiskills-security-review` (security dimension) |
| "audit this for vulnerabilities / threat model / check the auth" | `aiskills-security-review` | `aiskills-code-review` (severity classification) |
| "stuck on this local build/test error for more than ~10 min" | `aiskills-debugging-recovery` | — |
| "production is down / users are seeing errors / an alarm fired" | `aiskills-incident-investigation` | `aiskills-observability` (telemetry gaps), `aiskills-debugging-recovery` (once localized) |
| "it's slow / latency spike / capacity planning / traffic growth" | `aiskills-performance-tuning` | `aiskills-observability` (measure first), `aiskills-build-discipline` (the change itself) |
| "add logging / metrics / alarms / make this debuggable" | `aiskills-observability` | `aiskills-build-discipline` (the change itself) |
| "split this into parallel work / delegate across agents" | `aiskills-multi-agent-patterns` | `aiskills-agentic-loops` (L3 owns the mechanics) |
| "long session / running out of context / same mistake twice" | `aiskills-session-control` | `aiskills-continuous-learning` (if a lesson should persist) |
| "we keep re-explaining this / create a skill or agent for X" | `aiskills-capability-creation` | `aiskills-continuous-learning` (durable lessons) |
| "which skill should I use for…" | `aiskills-skill-routing` (this file) | — |

## One build task — which skill fires when

For a typical "build a feature" task the whole cycle lives in **`aiskills-build-discipline`** —
its sections apply at *different phases*, so only one is the active lens at a time:

| Phase | Skill · section | Why it fires here |
|---|---|---|
| plan the loops | `aiskills-agentic-loops` · PLAN + loop catalog | forecast the loop tree, own the stop conditions |
| learn the project first | `aiskills-build-discipline` · Phase 0 | locate the target, identify the real gate, build a Convention Checklist |
| RED / GREEN | `aiskills-build-discipline` · TDD cycle | a failing test first, then the minimal code to pass it |
| REFACTOR | `aiskills-build-discipline` · simplification lens | reduce complexity of green code, behavior unchanged |
| VERIFY | `aiskills-build-discipline` · VERIFY | the command CI runs, self-review, coverage |
| VERIFY, high-stakes claims | `aiskills-doubt-driven-development` | CLAIM → … → STOP before any security-sensitive or irreversible act |
| record the decision | `aiskills-design` · ADR | only if an expensive-to-reverse choice was made |

The outer OODA loop that drives the whole thing, and owns the named STOP, is
`aiskills-agentic-loops`.

## Master map — every skill by loop stage

| Loop stage | Skill |
|---|---|
| Outer control loop · grammar · ledger | `aiskills-agentic-loops` |
| Phase 0 · Build → Refactor → Verify (spine) | `aiskills-build-discipline` |
| Design · patterns · ADR | `aiskills-design` |
| Design · contracts | `aiskills-api-design` |
| Build · self-correction (local) | `aiskills-debugging-recovery` |
| Build · instrument | `aiskills-observability` |
| Optimize (post-correctness) | `aiskills-performance-tuning` |
| Review · correctness & maintainability | `aiskills-code-review` |
| Review · security | `aiskills-security-review` |
| Review · high-stakes doubt | `aiskills-doubt-driven-development` |
| Fan-Out · orchestration | `aiskills-multi-agent-patterns` |
| Investigate (production) | `aiskills-incident-investigation` |
| Session control (cross-cutting) | `aiskills-session-control` |
| Capture (post-DONE lessons) | `aiskills-continuous-learning` |
| Capture (self-extension) | `aiskills-capability-creation` |
| Router | `aiskills-skill-routing` (this file) |

Nothing in `skills/` may be orphaned: every skill named here must exist as a file, every skill
file must be named here, and `tests/check.sh` enforces both directions.

## Routing rules

1. **The brain classifies first.** Task type → loop graph → skills (the Task Graph in
   `brain/loop-contract.md`). This router refines WITHIN a loop graph; it never overrides the
   Build row's mandatory `aiskills-build-discipline`.
2. **One primary at a time.** The dominant intent picks the primary; supporting skills splice in
   as the plan reaches their stage (a plan-version bump per the `aiskills-agentic-loops`
   composition rule).
3. **Task changes type mid-loop → re-route.** A review that finds a bug is a graph switch: CLOSE
   the current graph, re-classify, load the new row's skills.
4. **When two rows both apply,** prefer the one whose *output* the user asked for (a diff →
   Build; a finding report → Review; a decision → Design).
