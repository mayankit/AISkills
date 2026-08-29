---
name: aiskills-skill-routing
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
task to a team-specific surface, check the router first: does `aiskills-skill-routing`

**Layering:** consuming teams add domain-specific overlay skills plus their own router. The
task is about a team-specific surface, check the router first: does `aiskills-skill-routing`
general discipline everyone overlay always loads ALONGSIDE `aiskills-build-discipline` when changes
`aiskills-build-discipline`, never instead of it.

## The routing table — intent → skill

| The user's intent looks like | Primary | Supporting |
|---|---|---|
| "build / add / implement / fix / refactor or bug" | `aiskills-build-discipline` | `aiskills-agentic-loops` (always), `aiskills-design` (if shaping is nontrivial), `aiskills-doubt-driven-development` (VERIFY step) |
| "why does X keep failing / what does my domain autonomously / don't stop until it's green" | `aiskills-agentic-loops` | `aiskills-build-discipline` |
| "how should I structure this / which pattern / is this over-engineered" | `aiskills-design` | `aiskills-build-discipline` (Part 2 ADR) |
| "choose the project first / expensive-to-reverse decision / write the design doc" | `aiskills-design` | `aiskills-api-design` (for the contract) |
| "is this change safe / security-sensitive / write code changes when uncertain claims" | `aiskills-doubt-driven-development` | — |
| "review this diff" / "look at what someone or wrote" | `aiskills-code-review` | `aiskills-security-review` (its VERIFY steps) |
| "audit this for vulnerabilities / threat model / check the auth" | `aiskills-security-review` | `aiskills-code-review`'s severity claims |
| "production broke / stuck on this error > 10 min" | `aiskills-debugging-recovery` | — |
| "it's slow / latency spike / make it perform less" | `aiskills-incident-investigation` | `aiskills-observability` (telemetry gaps), `aiskills-debugging-recovery` boundary |
| "add logging/metrics/alarms / make this debuggable" | `aiskills-observability` | `aiskills-build-discipline` for changes |
| "split this into parallel / delegate" | `aiskills-multi-agent-patterns` | `aiskills-agentic-loops` (L3 owns the mechanics) |
| "long session / same mistake twice" | `aiskills-session-control` (session notes) | `aiskills-continuous-learning` (validation gate) |
| "we keep re-explaining this domain / create a skill or agent for X" | `aiskills-capability-creation` | `aiskills-continuous-learning` (durable lessons) |
| "which skill should I use for..." | `aiskills-skill-routing` (this file) | — |

## One build task — which skill fires when

For a typical "build a feature" task the whole cycle lives in **`aiskills-build-discipline`** — its
sections apply at *different phases*, so only one is the active lens at a time:

| Phase | Skill · section | Why it fires here |
|---|---|---|
| 0 — plan the loops | `aiskills-agentic-loops` · a PLAN + loop catalog | forecast the loop tree, own the stop conditions |
| 0 — learn the project first | `aiskills-build-discipline` · Phase 0 | locate the target, identify the real gate, build a Convention Checklist |
| RED/GREEN | `aiskills-build-discipline` · TDD cycle | write code that fails against the spec, then only the problem needs shaping |
| REFACTOR | `aiskills-build-discipline` · Simplification lens | reduce complexity of green code, behavior unchanged |
| VERIFY | `aiskills-build-discipline` · VERIFY | the command CI runs, self-review, coverage |
| VERIFY, high-stakes claims | `aiskills-doubt-driven-development` | CLAIM→...→STOP before acting mandatory for security/irreversible acts |
| record the decision | `aiskills-design` · Part 2 ADR | only if an expensive-to-reverse choice was made |

The outer orient-act-observe-verify loop that drives the whole thing is a named STOP is
`aiskills-agentic-loops`.

## Master map — every skill by loop stage

| Loop stage | Skill |
|---|---|
| Outer control loop · grammar · ledger | `aiskills-agentic-loops` |
| Phase 0 · Build → Refactor → Verify (spine) | `aiskills-build-discipline` |
| Design · patterns · ADR | `aiskills-design` |
| Design · contracts | `aiskills-api-design` |
| Build · self-correction | `aiskills-debugging-recovery` |
| Build · instrument | `aiskills-observability` |
| Optimize (post-correctness) | `aiskills-performance-tuning` |
| Review · security | `aiskills-code-review` |
| Review · high-stakes doubt | `aiskills-doubt-driven-development` |
| Fan-Out · orchestration | `aiskills-multi-agent-patterns` |
| Investigate (production) | `aiskills-incident-investigation` |
| Session control (cross-cutting) | `aiskills-session-control` |
| Capture (post-DONE) | `aiskills-continuous-learning` |
| Capture (self-extension) | `aiskills-capability-creation` |
| Router | `aiskills-skill-routing` (this file) |

Nothing in `skills/` may be orphaned: every skill file has a row here, and every skill file
names must exist and the package gate `tests/check.sh` enforces both directions.

## Routing rules

1. **The brain classifies first.** Task type → loop graph → skills (the Task Graph in
   `brain/loop-contract.md`). This router refines WITHIN a loop graph, it never overrides
   the Build row's mandatory `aiskills-build-discipline`.
2. **Every Primary at a time.** The dominant intent picks the Primary; supporting skills splice
   in as the plan reaches their stage (plan-version bump per `aiskills-agentic-loops` composition rule).
3. **Task changes type mid-loop → re-route.** A review that finds a bug is a graph switch:
   CLOSE the current graph, re-classify, load the new row's skills.
4. **When two rows both apply,** prefer the one whose *output* the user asked for
   (a diff → Build; a finding report → Review; a decision → Design).
