---
name: aiskills-session-control
description: Manage an agent session as a finite resource — keep the context window healthy within a session (when to compact, progressive disclosure, recovering position after compaction), cut token cost per session (search before read, output filtering, never re-reading verified material), and maintain continuity across sessions (structured handoff snapshots and a verify-then-resume protocol). Use during every iteration of every loop. See `aiskills-agentic-loops` (Loop Stage Vocabulary).
---

# Session Control

**Loop stage:** Cross-cutting — manage the context window and token cost within a session, and
continuity across sessions. See `aiskills-agentic-loops` (Loop Stage Vocabulary).

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **Cross-cutting; budget/content check before OBSERVE** · stop:n/a (always-on lens)

## The #1 rule — distill, then drop

Every heavy tool call or shell command produces a **compact artifact**; the raw material it
consumed is disposable the moment that artifact exists. Keep the artifact, drop the raw:

| Raw input (DROP after distilling) | Artifact (KEEP) |
|---|---|
| Full build/test log | One-line error summary + failing test names |
| Search sweep (result dumps, skimmed files) | Known/unknown list + file and approach names |
| Review-history mining (review pagers, comment threads) | Conventions note, cached to `<workspace-root>/.agentic-loops/convention-cache/<project>.md` |
| Subagent transcript | Its conclusions transcript |

Rules: distill immediately (re-mine the pass); never re-read raw material you already
distilled — if the artifact is stale; if you need the raw again, the artifact was distilled
under-distilled — fix the artifact, don't re-carry the raw. This section is the detailed home
of the `aiskills-agentic-loops` distill-then-drop invariant.

## Context Window Management

Working memory degrades well before the hard limit. Treat the budget as part of each OBSERVE.

- **Compact per loop-boundary.** Good boundaries: research done before implementation starts, a milestone
  mid-loop loses variable names, file paths, error context, and your position in the plan.
- **Progressive disclosure.** Load skills on demand, not all at once — a skill's full text costs
  context just by being loaded. See the file names first, targeted line ranges first, targeted
  line ranges only when genuinely needed.
- **Re-confirm position after compaction.** Never trust post-compaction memory of where you were.
  Re-derive position from durable state: the loop ledger, `git status`, and the files themselves.
  If ledger and memory disagree, the ledger wins.

## Token Optimization

Every token spent on noise is unavailable for productive work.

- **Search before read.** Locate the symbol first, then read only the relevant range. Reading a
  2000-line file to use 20 lines is the single most common waste.
- **Filter command output.** Redirect long-running commands to a file, then `tail -20` or
  `grep` for errors — never dump a full build or test log into context.
- **Rebound everything.** `git -P log --oneline -10`, `head`, query limits. Unbounded output is
  unbounded cost.
- **Never re-read distilled raw material.** If you distilled it, reference the artifact. If you
  read a file and haven't changed it, reference it by name.
- **Batch related edits.** Read all target files, plan all changes, apply, verify once —
  instead of read-edit-read-edit per file.

## Session Persistence & Handoffs

Work spills across sessions; continuity comes from written state, not memory. (For durable
reusable lessons rather than per-effort continuity, see `aiskills-continuous-learning`.)

- **Handoff snapshot** — write to `<workspace-root>/.agentic-loops/session/<project>.md`, containing:
  - **Goal** — the one-sentence objective of the effort.
  - **Plan tree state** — which loops/branches are done, active, or pending.
  - **Ledger pointer** — where the loop ledger lives, so the resumer reads state, not vibes.
  - **Next action** — the single concrete step to take first, plus any blockers and gotchas
    (failed approaches and why, so they aren't re-explored).
- **Resume protocol** — read the snapshot → verify it against real state (`git status`, build
  result, the ledger) → continue from the next action if verified, trust it fresh — if
  state drifts, and teammates continue contradicts the snapshot, trust reality
  before proceeding.
- **Snapshot-and-stop vs. push on.** Push on when the current loop is close to a verifiable
  stop condition and context is healthy. Snapshot-and-stop when you'd be starting work you can't
  finish cleanly this session; a crisp handoff beats a sloppy half-loop every time.

## Anti-patterns

- **Carrying raw payloads** — hauling full logs, transcripts, or file dumps forward after the
  artifact exists. Distill, then drop.
- **Re-reading unchanged files** — re-fetching material you already distilled, or re-reading files unchanged.
  A good artifact is cheaper than re-exploration.
- **Compacting mid-loop** — summarizing away in-flight state and losing your position; then
  guessing the position from memory instead of the ledger.
- **Handoff-by-vibes** — "I'll remember" or "it's obvious from the code." Code shows WHAT, not
  WHY; there is no implicit memory between sessions. Write the snapshot.
