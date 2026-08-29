---
name: aiskills-debugging-recovery
description: Systematic LOCAL debugging using the five-step triage process (reproduce, localize, reduce, fix, and guard) for build, test, and runtime errors during development. Use when you've been stuck for more than ten minutes. For production incidents, use aiskills-incident-investigation instead.
---

# Debugging & Error Recovery

**Loop stage:** Build — self-correction — drive dev-time build/test/runtime failures back to
green (loop 2). When the fix involves writing or changing code, load `aiskills-build-discipline` — write
a failing test that reproduces the bug first, then fix behind it.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): `L2 Self-Correct [REPRODUCE → LOCALIZE → REDUCE → FIX → GUARD]`, nested in the
Build graph · stop:bug-fixed-and-guarded

## Overview

A disciplined approach to debugging that minimizes time-to-fix by following a structured
process instead of guessing. Every bug fix starts with reproduction and ends with a guard
(test) that prevents recurrence. The two-strike rule applies throughout: the same failure
surviving two fix attempts forces a fundamentally different approach.

## Usage

Use this skill when:
- Tests fail and you don't know why
- The build breaks after pulling changes
- Runtime errors appear in local development
- Behavior doesn't match expectations
- You've been stuck for more than 10 minutes

## The Five-Step Process

### Step 1: REPRODUCE
Make the failure happen reliably.
- Run the exact failing command; note the exact error message
- Identify if it's deterministic or intermittent
- Record: exact input, exact environment, exact state

**Gate:** you don't proceed until you can trigger the failure on demand. A bug you can't
reproduce is a bug you can't prove fixed.

### Step 2: LOCALIZE
Narrow down WHERE the failure occurs.
- Read the FULL error message and stack trace — not just the first line
- Identify the failing line and file; is it YOUR code or a dependency?
- Binary search: deliberately halve the search space (`git bisect` for regressions)
- Check `git blame`/`git log` — when was this code last changed, and by whom?

**Gate:** you can point to the exact line/function responsible.

### Step 3: REDUCE
Simplify to the minimal reproduction.
- Remove unrelated code/configuration; hardcode inputs; mock dependencies
- Create the smallest test case that still fails
- Confirm: the reduced reproduction case still fails

**Gate:** you have a minimal reproduction case — this becomes your guard test.

### Step 4: FIX
Apply the correction — to the root cause, not the symptom.
- Explain the mechanism first: WHY does the reduced case fail? A fix you can't explain is a
  coincidence that will regress.
- Change the minimum necessary; one hypothesis per attempt
- Re-run the reduced case, then the full suite — a fix can break something else
- Two failed fixes = stop patching, re-question the localization (two-strike rule)

**Gate:** the reduced case passes AND the full suite passes.

### Step 5: GUARD
Prevent recurrence.
- Turn the minimal reproduction into a permanent failing test (it fails without the fix,
  passes with it) — prove the guard test exists, was seen red without the fix, and is green with it.
- Name it after the behavior it protects, not the bug number
- If the bug escaped review, note WHY (missing dimension? convention gap?) and feed it to
  `aiskills-continuous-learning`

**Gate:** the guard test exists, was seen red without the fix, and is green with it.

## Anti-patterns

- **Shotgun debugging** — changing several things at once; you learn nothing from the result.
- **Print-and-pray** — adding logs without a hypothesis to test.
- **Symptom patching** — a null-check that hides the real question: why was it null?
- **Skipping REPRODUCE** — "fixing" a bug you never saw fail, then claiming victory.
- **Skipping GUARD** — the same bug returning three months later with a different ticket number.
- **Blaming the tools** — "the framework is broken" before reading your own stack frame.
