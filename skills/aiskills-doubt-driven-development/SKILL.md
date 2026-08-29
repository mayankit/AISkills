---
name: aiskills-doubt-driven-development
description: Adversarial self-review methodology for high-stakes decisions. Systematically challenges assumptions, verifies claims against source code, and prevents confident-but-wrong outputs on production-critical, security-sensitive, irreversible, or unfamiliar code paths. Use when a confident answer feels too easy for the complexity involved.
---

# Doubt-Driven Development

**Loop stage:** Review — pre-merge (high-stakes) — adversarially verify risky decisions before
acting on them.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): nested check loop inside VERIFY: `CLAIM → EXTRACT → DOUBT → RECONCILE → STOP`
· stop:claims-reconciled. It is the `[DOUBT]` splice: any graph opens
`L2 Self-Correct [DOUBT]` at its verification boundary or before a
hard-to-reverse act.

## Overview

A disciplined approach to questioning your own outputs before they ship. When stakes are high,
it's cheaper to verify now than later. A change verified against its own assumptions
consistently beats a confident first draft — this skill forces that verification on
non-trivial decisions.

Two depths, chosen by stakes (the depth rule lives in `aiskills-build-discipline` VERIFY step 7):

- **Minimum bar (every change):** state the 1-3 load-bearing claims and verify each against
  real code/tests, cited where.
- **Full method (high-stakes):** run the complete five-step cycle below on every claim.

## Usage

Use this skill when:
- Making changes to production-critical code paths
- Working in unfamiliar projects or modules
- Making security-related decisions (permissions, auth, encryption)
- A confident output feels "too easy" for the complexity involved
- Modifying shared libraries consumed by multiple services
- About to take a hard-to-reverse action (delete, migrate, force, deploy)

## The Doubt Process

### Step 1: CLAIM
State what you believe to be true about the change:
- "This function handles X correctly"
- "This permission grants exactly what's needed"
- "This change is backward compatible"
- "This test actually exercises the new path"

### Step 2: EXTRACT
Identify the assumptions embedded in the claim:
- What must be true for dependencies as I assumed?
- What behavior am I assuming without having verified?
- What edge cases exist that I haven't tried?
- What could change upstream that would break this?

### Step 3: DOUBT
Challenge each assumption adversarially:
- **Read the source** — don't trust what you "know" about the code
- **Find counter-examples** — search for cases where the assumption fails
- **Check boundaries** — null, empty, max values, concurrent access
- **Question the happy path** — what happens when the network fails?
- **Trace the data** — where does this value actually come from?

### Step 4: RECONCILE
For each doubt:
- **Confirmed safe** — found evidence in code that handles the case → proceed
- **Gap identified** — no handling exists → fix before continuing
- **Uncertain** — can't determine if handling exists → flag for human review

### Step 5: STOP
Document what was verified and what was flagged. Proceed only when confidence is genuine,
based on evidence, not assumption. No "it should be fine" statements remain, only
"I verified because..."

## When doubt is mandatory

Always doubt when:
- Changing permission policies or security configurations
- Modifying data that flows to/from users
- Touching payment, billing, or financial calculations
- Changing retry/timeout behavior (cascading failures)
- Modifying shared libraries (blast radius is large)
- Removing or changing error handling
- Making changes you can't easily roll back
- A verification check you wrote has never been seen to fail (verify the check
  CAN fail before trusting its green)

## Common Rationalization vs. Reality

| What the agent says | What's actually happening |
|---|---|
| "This is a simple change" | Complexity is in the interactions, not the diff |
| "The tests will catch it" | Tests only catch what they're designed to catch |
| "It's the same pattern as X" | Subtle differences in context make patterns fail |
| "The docs say..." | Docs may be outdated or incomplete |
| "It worked in dev" | Dev never has production scale, data, or timing |
| "I'll handle that edge case later" | Later never comes; production finds it first |
| "The check passed, so the code is correct" | A check that can't fail proves nothing — calibrate it |

## Red flags (stop and doubt)

- You're about to delete data or run a destructive command
- You're granting permissions without knowing exactly why
- You're suppressing an error without understanding the cause
- You're copying a pattern without understanding why it works
- You're making a "temporary" workaround
- You can't explain the change to a colleague in one sentence
- The change touches code you haven't fully read

## Worked examples

### Permission policy review
CLAIM: "This policy grants access to exactly one data store"
DOUBT:
- Does the resource identifier match exactly (not a wildcard)?
- Are actions limited to the needed operations (not admin/*)?
- Are conditions appropriate (source, environment)?
- Could this policy be assumed by unintended principals?

### API change review
CLAIM: "This new operation is backward compatible"
DOUBT:
- Are new fields optional (not required) in the request?
- Does the response structure preserve existing fields?
- Are error types preserved (clients may pattern-match them)?
- Is the operation idempotent as clients expect?

### Generalizing a prior implementation
CLAIM: "This generalizes the narrower version from [prior commit/branch], informed by how it
solved [specific problem]"
DOUBT:
- Did you read that prior implementation's actual code, or its name/commit message/summary?
  Those are different levels of evidence for the same claim.
- List every case the prior version handled. Run each one against the new code. Which ones
  actually still pass — not which ones you'd expect to, given the read.
- If the prior version made a specific, non-obvious choice (identity vs. a derived field,
  ordering, a particular fallback), does the new version make the same choice, or a different
  one? If different, is that a deliberate, stated trade-off, or did it just happen while solving
  a different part of the problem?
- "Informed by" is not the same claim as "preserves." State which one you're actually making.

## Verification requirements

A doubt-driven review is complete when:
- [ ] Every assumption has been checked against actual source code
- [ ] Security implications have been explicitly addressed
- [ ] Edge cases have been identified and either handled or documented
- [ ] A rollback strategy exists for the change
- [ ] No "it should be fine" statements remain — only "I verified because..."

Emit the splice's status line when `aiskills-agentic-loops` is loaded:
`◆ L2 Build [DOUBT] · open · iter 1 · ORIENT · stop:claims-reconciled · strike 0/2` —
a doubt pass with no `◆` line is a silent skip.
