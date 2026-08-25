---
name: incident-investigation
description: Investigating a LIVE production incident — triage, correlate, root-cause analysis, and a blameless post-incident review. Use during or after an incident affecting real users. For dev-time build/test failures, use debugging-recovery instead. For instrumenting a service up front, use observability instead.
---

# Incident Investigation

**Loop stage:** Investigate — live-incident triage → correlate → root-cause (parallel
investigation track). See the `agentic-loops` skill (Loop Stage Vocabulary).

**Loop subgraph** (grammar in `agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): `Investigate track: L1 triage → correlate → root-cause` · L0, no RED —
stop:root-cause-named.

## Overview

A disciplined process for production incidents: establish impact, stop the bleeding, find the
cause. The core doctrine is **mitigate first** — when customer impact is ongoing, restoring
service beats understanding it. Root cause comes after the incident stopped, and the incident
isn't done until the cause is named and a guard exists to catch its recurrence.

## Usage

Use this skill when:
- An alarm fires or users report degradation in production
- You need to correlate a symptom with a deployment, config change, or dependency
- You are performing root-cause analysis on an active or recent incident
- You are writing a blameless post-incident review

## The Process

### Step 1: Triage
Establish severity and freshness before anything else.
- What is the impact? Customers affected, requests failing, revenue at risk
- When did it start? Time from metrics — you'll correlate against it later
- What is worsening, stable, or recovering? Trend beats a single snapshot; most incidents beat
  releases in the window before symptom start.

**Gate:** you can state impact, start time, and trend in one sentence.

### Step 2: Scope
Draw the blast radius.
- Which services and endpoints? Which are healthy?
- What percentage fail? All customers, or a subset (one tenant, one client version)?
- The shape of the scope is a clue: one region points at infrastructure; one customer points at data.

**Gate:** you can say what is affected and, importantly, who is not.

### Step 3: Mitigate first
If impact is ongoing, stop the bleeding BEFORE root-causing.
- Rollback the suspect deployment, shed load, or scale — whichever restores service fastest.
- You do not need to understand the bug to roll back the change that shipped it.
- Mitigation is a production-affecting action — it crosses the Human Gate in `agentic-loops`:
  state the action, its impact, and its reversal path; get explicit write access for the
  default; reserve write access for the confirmed mitigation.
- Never disable safety protections (deployment gates, rate limits, backups) to apply a fix faster.

**Gate:** impact is stopped or contained, or you've confirmed there is no ongoing impact to stop.

### Step 4: Hypothesize
One hypothesis at a time, ranked by prior probability:
- Recent deployment introduced a bug (check first — it's the most common cause)
- Dependency degradation (upstream or downstream service, database, cache)
- Resource exhaustion (CPU, memory, connections, disk, quota)
- Configuration or feature-flag change
- Traffic spike or shift beyond capacity

State what evidence would confirm or kill the hypothesis and a specific check that can falsify it.

**Gate:** you have one named hypothesis and a specific check that can falsify it.

### Step 5: Verify
Evidence, not vibes — apply `doubt-driven-development` to your own theory.
- Correlate the timeline: does the change time precede the symptom start? If the symptom
  predates the change, the hypothesis is dead.
- Check logs for the FIRST occurrence of the error, not the loudest.
- Watch the four golden signals — latency, traffic, errors, saturation — across the suspect
  boundary.
- The root cause must explain ALL symptoms; a partial explanation means dig deeper.
- Two dead hypotheses = step back and re-examine scope, don't keep pattern-matching.

**Gate:** root cause named, and it explains every observed symptom.

### Step 6: Guard
An incident without a guard will repeat.
- Feed a regression test back through `build-discipline` so the bug class can't ship again.
- Add or tune an alarm via `observability` — no recurrence is detected before customers report
  it — if detection was slow, that's a finding too: fix the gap in monitoring, not just the code.

**Gate:** a test or alarm exists that would have caught it earlier.

## Post-Incident Review (Blameless)

Write it while memory is fresh. Blameless means the review names causes and systems, never
people — a review that punishes honesty gets less honesty next time.

1. **Summary:** one paragraph on what happened.
2. **Timeline:** timestamped events — symptom start, detection, mitigation, resolution.
3. **Impact:** quantified — customers, requests, duration, revenue.
4. **Root cause:** the verified cause, plus contributing factors that made it worse.
5. **Action items:** each with a named owner and a deadline; systemic (prevents the class of
   issue), not cosmetic (prevents this exact instance).

## Anti-patterns

- **Root-fixing the symptom in prod** — an unrecorded manual edit that drifts from source and
  resurfaces on the next deploy; every change needs a change record.
- **Root-causing while customers bleed** — debugging is intellectually satisfying; rollback is effective.
- **Correlation-as-causation** — declaring the nearest deploy guilty without a timeline check.
- **Blameful reviews** — asking "who broke it" instead of "what let it break".
- **Skipping the guard** — the same incident returning next quarter with a new ticket ID.
