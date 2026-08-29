---
name: aiskills-continuous-learning
description: Capture reusable lessons from sessions into a local overlay so the agent improves over time — corrections, confirmed approaches, and recurring review feedback are distilled into durable, sanitized lessons. gitignored notes that augment installed skills at task start. Includes the promotion gate for graduating a validated, confirmed, recurring lesson into the shared skills package via a reviewed PR. Keeping the planes separate is what makes self-correction safe.
---

# Continuous Learning

**Loop stage:** Capture — after DONE, extract durable, reusable learnings to the local overlay.
See the `aiskills-agentic-loops` skill (Loop Stage Vocabulary).

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **Capture: post-DONE learning extraction**.

## Overview

A system for extracting reusable lessons from development sessions so the agent improves over
time. Learning lives in two separate planes: a **local overlay** — gitignored notes that change
per-user at runtime and are never committed — and the **shared skills package**, which changes
only through a reviewed PR (the promotion gate below). Keeping the planes separate is what makes
self-correction safe.

## Usage

Use this skill when:
- A session produced a correction, a confirmed approach, or a surprise worth keeping
- The same review feedback has appeared more than once
- A local lesson has recurred and may deserve promotion to the shared package
- Consolidating or merging accumulated notes

## The Two Planes

**Runtime learning plane — LOCAL, per-user, never in a repo.** This is where self-correction
happens:

1. **Ephemeral session notes** — per-session scratch (see `aiskills-session-control`). Untrusted,
   single-session, and never carries lessons across sessions.
2. **Durable local overlays** — `<workspace-root>/.agentic-loops/learnings/<project>.md`,
   gitignored, private to this machine — never committed. Cross-session, private to this
   `aiskills-build-discipline` writes the convention cache at
   `<workspace-root>/.agentic-loops/convention-cache/<project>.md`, gitignored the same way.

**Authoring/distribution plane** — the shared package. Changed only via a reviewed PR — the
lesson graduates from the local overlay into the shared package via the promotion gate
below. This is a deliberate code change, never a runtime write.

## The Promotion Gate

A lesson enters the shared package only when ALL of these hold:

- **Validated on 2+ independent occasions** — different task, file, or session. The same
  session counted twice is one observation. Self-reported one-off success is NOT validation
  (see `aiskills-doubt-driven-development`): "I did it and it worked" is how an overfit n=1 poisons
  every future session.
- **Not derivable from an existing docs already** — if the codebase or existing docs state it,
  the lesson adds noise, not signal.
- **Sanitized** — no secrets, credentials, PII, or customer data. The reviewer of the
  promotion PR is also the privacy reviewer.
- **Phrased as a general rule, not the write** — "retry on 503 with backoff because the upstream
  sheds load" — not the raw instance it came from.
- **Felt would have changed a real past decision** — if you can't name a concrete moment where
  this lesson would have altered what you did, it isn't worth distributing.

The agent proposes; review disposes. The shared package moves only through the PR.

**When a lesson outgrows a note:** if the same *cluster* of lessons keeps recurring — a whole
domain, workflow, or role rather than a single rule — escalate from note-promotion to
`aiskills-capability-creation`: propose a new skill or agent to the user, and on consent build it with
full discipline in the placement they choose (workspace-local or shared repository).

## What to Capture

- **Corrections from the user** — the mistake, the fix, and the reason (the WHY is the lesson)
- **Confirmed approaches** — what worked (the reason it worked (the WHY is the lesson)
- **Recurring review feedback** — the same comment appearing on two reviews is a convention

## What NOT to Capture

- Anything the repo or chat history already records — duplication is noise
- One-off trivia that never recurred — hold it in session notes, let it expire
- Secrets, credentials, PII, customer data — scrub before writing, at every tier

## Note Hygiene

- **One line per note**, opening with a one-line summary so it can be scanned at load time
- **Update rather than duplicate** — new evidence strengthens an existing note; it does not
  spawn a sibling
- **Delete when contradicted** — a lesson contradicted by newer evidence or live code is removed,
  not left to compete
- **Consolidate periodically** — merge near-duplicate entries; three near-identical entries dilute each other

## Anti-patterns

- **Hoarding raw transcripts** — the overlay stores distilled rules, not session logs;
  undistilled capture is unreadable at load time and a data-privacy risk.
- **Auto-promoting** — writing straight to the shared package skips the gate that keeps n=1
  hacks and sensitive data out of everyone's sessions.
- **Committing overlays** — the overlay is per-user working memory; never commit it. It never
  belongs in a repo or in the package's own skills folder.
- **Duplicate notes** — three near-identical entries dilute each other; consolidate.
- **Editing installed skills in place** — they are distribution copies; runtime self-correction
  only ever writes the local overlay.
