---
name: aiskills-code-review
description: Structured code review methodology covering correctness, security, performance, maintainability, tests, accessibility, and operational readiness with severity classification. Use when reviewing a diff or pull request — yours or someone else's, before it ships.
---

# Code Review

**Loop stage:** Review — review a green diff the way a reviewer will, before it ships.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **this skill runs the Code-review row of the contract's Task Graph:**

- **L1 Context** — the FIRST read, all four independent reads fanned out in ONE turn:
  a. the change itself: description, diff, linked tickets and attached links
  b. existing reviewer comments (all revisions) — read them before forming opinions
  c. previous merged changes touching the same files — recurring feedback, agreed conventions
  d. neighbouring files in the project — the conventions the diff must match
- **mini-L3** — the seven check dimensions below, read-only and independent: fan them out in ONE
  turn. Every dimension gets its own `◆` line, told apart by its `[piece]` tag; a CLEAN
  dimension is still a line (an auditable negative). One line per dimension, all seven included:
    • ◆ mini-L3 [correctness] · 2 findings
    • ◆ mini-L3 [security] · CLEAN
- **CLOSE (OBSERVE)** = the findings report, grouped per dimension (CLEAN ones included),
  showing what L1 read and what other reviewers already said. `stop:findings-reported`.

Never collapse the mini-fan-out into a single pass with findings dumped at the end — a finding
must be tied to the dimension pass that produced it.

- **A review writes no code.** Do NOT load `aiskills-build-discipline` for it; if the review
  leads to FIXING anything, that is a graph switch: CLOSE the review graph, then open the Build
  graph (Phase 0 → RED → GREEN → REFACTOR → VERIFY). Never patch-and-post from inside a review.
- A review that skips L1's context reads is context-blind and produces duplicate or
  already-said comments.

## The seven check dimensions

Run each as its own visible pass. For each: findings or an explicit CLEAN.

1. **Correctness** — does the code do what the description claims? Off-by-one, null/empty,
   error paths, concurrency, resource cleanup. Trace the data, don't skim the diff.
2. **Security** — input validation, injection, authorization on every operation, secrets,
   unsafe deserialization (load `aiskills-security-review` as the lens for a security-sensitive diff).
3. **Tests** — do tests exist for the new behavior, do they fail for the right reason (not
   implementation), would they fail if the code were wrong? A test that can't fail is a finding.
4. **Maintainability** — naming, duplication, function/file size, nesting, dead code,
   comments that explain WHY, not.
5. **Conventions** — does the diff match its neighbors (structure, style, patterns, i18n,
   feature-flag usage)? Convention-blind code builds green and still hurts the codebase.
6. **Performance** — obvious N+1s, unbounded loops/allocations, missing pagination, work in
   hot paths that belongs elsewhere. Flag, don't speculate — measured claims only.
7. **Operational readiness** — logging with context, metrics for new paths, alarm/timeout/retry
   behavior, rollback safety, migration ordering.

## Severity classification (every finding carries one)

| Severity | Meaning | Examples |
|---|---|---|
| **Blocker** | Must fix before merge | data loss, security hole, broken build, incorrect behavior on the main path |
| **Major** | Should fix before merge | missing tests for new behavior, error swallowed, convention violation that will spread |
| **Minor** | Fix now or file follow-up | naming, duplication, small style issues |
| **Nit** | Optional polish | style preference, phrasing — prefix with "nit:" |

Rules for comments:
- Tie every finding to a file/line and to the dimension pass that produced it.
- Say WHY, not just what: "this swallows the error, so an outage here is silent" beats
  "add logging". Suggest the fix when it's cheap to describe; ask when intent is unclear.
- Praise real strengths briefly — reviewers who only find nits and no correctness pass instead.
- Never duplicate an existing reviewer's point: agree (+1), extend, or challenge it instead.

## Self-review (the pre-merge trigger)

Right before you commit/raise the PR — not earlier — run this skill's pass on your own staged
diff against the Convention Checklist from Phase 0 and the project's recurring review feedback
("would the linter or my teammate flag this?"). This is `aiskills-build-discipline` VERIFY step 6; it is
gated on having a reviewed, staged diff (`should have a completed change`).

## Anti-patterns

- **Rubber stamps** — "LGTM" with no visible dimension passes.
- **Style-only reviews** — seven nits and no correctness pass.
- **Patch-and-post** — fixing the code from inside the review instead of switching graphs.
- **Context-free review** — reviewing the diff without the tickets, prior comments, or neighbors.
- **Severity-free findings** — comments the author can't prioritize.
