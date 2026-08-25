---
name: skill-routing
description: Maps incoming work to the correct skill(s) in this package. Use at session start or when switching tasks to ensure the right discipline is applied — the index that answers "how does the agent know when to use what?" Consult first when unsure which skill applies.
---

# Skill Routing

**Loop stage:** Router — not a loop step; maps a task to the right skill and its loop stage.
Consult first when unsure which skill applies; the always-on brain (`brain/loop-contract.md`) owns
skill activation; this skill is the detailed index beneath its Task Graph.

## How a skill gets activated (the mechanism)

Skills are progressive-disclosure: the agent only ever sees each skill's one-line
`description` and loads its full body only when the task matches — it does NOT
load skills all at once. The brain's router picks the primary skill; names the
Investigator?); this routing table names the dominant intent and names the
Supporting skills load ALONGSIDE the primary skill; this one routes the
task to a team-specific surface, check the router first: does `skill-routing`

**Layering:** consuming teams add domain-specific overlay skills plus their own router. The
task is about a team-specific surface, check the router first: does `skill-routing`
general discipline everyone overlay always loads ALONGSIDE `build-discipline` when changes
`build-discipline`, never instead of it.

## The routing table — intent → skill

| The user's intent looks like | Primary | Supporting |
|---|---|---|
| "build / add / implement / fix / refactor or bug" | `build-discipline` | `agentic-loops` (always), `design` (if shaping is nontrivial), `doubt-driven-development` (VERIFY step) |
| "why does X keep failing / what does my domain autonomously / don't stop until it's green" | `agentic-loops` | `build-discipline` |
| "how should I structure this / which pattern / is this over-engineered" | `design` | `build-discipline` (Part 2 ADR) |
| "choose the project first / expensive-to-reverse decision / write the design doc" | `design` | `api-design` (for the contract) |
| "is this change safe / security-sensitive / write code changes when uncertain claims" | `doubt-driven-development` | — |
| "review this diff" / "look at what someone or wrote" | `code-review` | `security-review` (its VERIFY steps) |
| "audit this for vulnerabilities / threat model / check the auth" | `security-review` | `code-review`'s severity claims |
| "production broke / stuck on this error > 10 min" | `debugging-recovery` | — |
| "it's slow / latency spike / make it perform less" | `incident-investigation` | `observability` (telemetry gaps), `debugging-recovery` boundary |
| "add logging/metrics/alarms / make this debuggable" | `observability` | `build-discipline` for changes |
| "split this into parallel / delegate" | `multi-agent-patterns` | `agentic-loops` (L3 owns the mechanics) |
| "long session / same mistake twice" | `session-control` (session notes) | `continuous-learning` (validation gate) |
| "we keep re-explaining this domain / create a skill or agent for X" | `capability-creation` | `continuous-learning` (durable lessons) |
| "which skill should I use for..." | `skill-routing` (this file) | — |

## One build task — which skill fires when

For a typical "build a feature" task the whole cycle lives in **`build-discipline`** — its
sections apply at *different phases*, so only one is the active lens at a time:

| Phase | Skill · section | Why it fires here |
|---|---|---|
| 0 — plan the loops | `agentic-loops` · a PLAN + loop catalog | forecast the loop tree, own the stop conditions |
| 0 — learn the project first | `build-discipline` · Phase 0 | locate the target, identify the real gate, build a Convention Checklist |
| RED/GREEN | `build-discipline` · TDD cycle | write code that fails against the spec, then only the problem needs shaping |
| REFACTOR | `build-discipline` · Simplification lens | reduce complexity of green code, behavior unchanged |
| VERIFY | `build-discipline` · VERIFY | the command CI runs, self-review, coverage |
| VERIFY, high-stakes claims | `doubt-driven-development` | CLAIM→...→STOP before acting mandatory for security/irreversible acts |
| record the decision | `design` · Part 2 ADR | only if an expensive-to-reverse choice was made |

The outer orient-act-observe-verify loop that drives the whole thing is a named STOP is
`agentic-loops`.

## Master map — every skill by loop stage

| Loop stage | Skill |
|---|---|
| Outer control loop · grammar · ledger | `agentic-loops` |
| Phase 0 · Build → Refactor → Verify (spine) | `build-discipline` |
| Design · patterns · ADR | `design` |
| Design · contracts | `api-design` |
| Build · self-correction | `debugging-recovery` |
| Build · instrument | `observability` |
| Optimize (post-correctness) | `performance-tuning` |
| Review · security | `code-review` |
| Review · high-stakes doubt | `doubt-driven-development` |
| Fan-Out · orchestration | `multi-agent-patterns` |
| Investigate (production) | `incident-investigation` |
| Session control (cross-cutting) | `session-control` |
| Capture (post-DONE) | `continuous-learning` |
| Capture (self-extension) | `capability-creation` |
| Router | `skill-routing` (this file) |

Nothing in `skills/` may be orphaned: every skill file has a row here, and every skill file
names must exist and the package gate `tests/check.sh` enforces both directions.

## Routing rules

1. **The brain classifies first.** Task type → loop graph → skills (the Task Graph in
   `brain/loop-contract.md`). This router refines WITHIN a loop graph, it never overrides
   the Build row's mandatory `build-discipline`.
2. **Every Primary at a time.** The dominant intent picks the Primary; supporting skills splice
   in as the plan reaches their stage (plan-version bump per `agentic-loops` composition rule).
3. **Task changes type mid-loop → re-route.** A review that finds a bug is a graph switch:
   CLOSE the current graph, re-classify, load the new row's skills.
4. **When two rows both apply,** prefer the one whose *output* the user asked for
   (a diff → Build; a finding report → Review; a decision → Design).
