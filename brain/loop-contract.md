# Loop Contract (the always-on BRAIN)

This file is the single activation authority for the loop discipline. Keep it always in
context (system prompt, `CLAUDE.md`/`AGENTS.md` include, or your host's persistent-context
mechanism); it stays small on purpose. Skills and agent prompts MUST NOT restate these rules;
they stay lean-on-demand. The detailed mechanics live in two skills, loaded on demand:

- **`aiskills-agentic-loops`** — the loop taxonomy (L0-L4), status-line format, plan tree, fan-out
  mechanics, stop conditions. Load it for any multi-step task.
- **`aiskills-build-discipline`** — the delivery SPINE (Phase 0 → RED → GREEN → REFACTOR → VERIFY).
  Load it whenever the row below says Build.

Supporting skills load at their stage, routed by `aiskills-skill-routing`'s detailed index — skill
selection + ADRs during shaping, the `aiskills-doubt-driven-development` splice at every hard-to-reverse act.

## Bootstrap (lazy — before the first turn you actually WRITE, not every turn)

Skip this for routing-lite turns. A pure quick-QA turn (the Routing row below) makes NO tool
call and must NOT run this bootstrap. Run it only on the first turn that starts real
multi-step work — the first turn a plan tree gets emitted for, not every turn after.

Resolve the ledger script and pin the workspace root (requires a shell tool):

```bash
_LOOP_SH=$(find ~/.claude/skills -maxdepth 6 -path "*aiskills-agentic-loops/scripts/loop-status.sh" 2>/dev/null | head -1)
export AGENT_WS_ROOT=$(pwd)   # pin the ledger root — run this from the workspace root, outside any git repo when possible
echo "loop-status: ${_LOOP_SH:-none} (emit lines as plain text if none)"
```

All ledger writes go through that script (and its sibling `fanout-check.sh`, in the same
directory). `AGENT_WS_ROOT` makes the ledger location deterministic; without it, the script
climbs out of any enclosing git work tree and falls back to `$HOME`. The ledger must never live
inside a repository, where it could be accidentally committed. If no shell exists at all, emit
the identical lines as plain text — the format doesn't change.

## The Task Graph — pick the loop graph by task type, then load only its skills

Classify the task FIRST — this is the ORIENT step, and for the first turn the classification
rule is mechanical, not a judgment call: if the task will create or edit ANY behavior-affecting
file — source, tests, prompts, configs, schemas — it is a Build task and `aiskills-build-discipline`
loads. No exceptions, except the two `aiskills-build-discipline` documents explicitly on its own terms
(characterization tests for legacy code; suite-level checks for non-executable artifacts) —
both of those still put implementation behind a failing check first, they just define what
"the test" means for that case.

| Task type | Loop graph | Load |
|---|---|---|
| **Build / bug / refactor** (any behavior-affecting edit) | L0 Convention-Model → L1 (if files unknown) → L2 [RED-GREEN-REFACTOR-VERIFY] | `aiskills-build-discipline` + `aiskills-agentic-loops` (grammar) |
| **Code-review** (evaluate a diff — no fixing) | L1 Context (skim tickets, prior comments, diff) → mini-L3 (check dimensions, read-only) → CLOSE = findings report | `aiskills-agentic-loops` only — a review writes NO code, NOT `aiskills-build-discipline` |
| **Review → fix transition** | CLOSE the review graph, then open a Build graph — never patch-and-post from inside a review | add `aiskills-build-discipline` at the transition |
| **Incident / investigation** | Investigate graph: triage → scope → mitigate first → hypothesize → verify → guard | `aiskills-incident-investigation` |
| **Design** (ORIENT/DECIDE-heavy) | L1 Context → aiskills-design (ORIENT/DECIDE) → decision recorded as ADR | `aiskills-design` — no build gate unless code follows |
| **Hard-to-reverse act** (security, data, payments, prod-rollback) | a `[DOUBT]` splice inside whichever graph is already open | `aiskills-doubt-driven-development` |
| **Routing / quick QA** (single lookup, no state change) | Single pass — plan tree and ledger optional | `aiskills-skill-routing` if the right skill is unclear |

A task that changes type mid-flight (a review finds a bug; an investigation needs a code
change) is itself an ORIENT event: restate the goal, close the graph that no longer fits,
reconcile any loops still open, bump the plan tree to a new version, and only then act under
the new graph.

**Composition:** the grammar (L0-L4, OODA, stops, strikes, status-line format) lives in exactly
ONE place — the `aiskills-agentic-loops` skill. Every other skill declares a one-line `Loop subgraph`
written in that grammar instead of restating it. Loading a skill mid-task splices its subgraph
into the current position (a plan version bump), under whatever loop is already open — it never
opens an unrelated graph of its own. Domain-overlay skills (project- or team-specific
conventions) parameterize a parent subgraph with domain knowledge; they declare no loops and
change no grammar, and load alongside whichever skill owns the loop they're feeding into.

## Non-negotiable rules (the what — formats live in `aiskills-agentic-loops`)

These seven hold across every graph in the table above, regardless of which skills are loaded:

1. **Plan before the first tool call.** Any task expected to take more than one or two tool
   calls gets a `● PLAN` tree emitted before work starts — not after the first action, not only
   once "it turns out to be complicated." A trivial single-step task can skip it; anything else
   can't. The tree's format (indentation, per-line `stop:<condition>`, glyphs) is defined once,
   in `aiskills-agentic-loops` — never redefined per skill.
2. **Signal position, don't just narrate it.** Every loop open, close, and DONE gets one status
   line, written through the ledger script (`aiskills-agentic-loops`'s `loop-status.sh`) when a shell
   exists, or the identical line as plain text when it doesn't. A task with no visible status
   lines and no ledger entries has left the discipline even if the underlying work is fine.
3. **Every open loop names its stop condition up front**, chosen from exactly five:
   `DONE`, `BLOCKED-EXTERNAL` (needs something outside the agent's control), `BLOCKED-AMBIGUOUS`
   (needs a human decision), `NO-PROGRESS` (repeated attempts aren't converging), or `BUDGET`
   (time/token/iteration budget exhausted). A loop that closes without one of these five named
   has not actually stopped, it has just stopped talking.
4. **Two strikes, then change approach.** The same fix attempted twice without success is not
   attempted a third time in the same form — the third attempt must be a materially different
   diagnosis or strategy, not a variation on the same guess (see `aiskills-agentic-loops`'s L2
   `strike <s>/2` tracking).
5. **Independent work is dispatched together, in one turn.** Two or more pieces with no shared
   mutable file are never serialized — not across turns, and not by awaiting one subagent
   before dispatching the next. This is enforced mechanically by the ledger scripts
   (`fanout-check.sh` + the sibling-loop tripwire in `loop-status.sh`), not left to discretion.
6. **Never hand back work you had the tools to finish.** "Here's what you'd need to do next" is
   only acceptable at a genuine `BLOCKED-*` stop, never as a substitute for finishing a task the
   agent could complete itself in the same session.
7. **A build task never ships without its gate passing for real.** `aiskills-build-discipline`'s coding
   gate and VERIFY phase are not optional inside a Build graph; a green lint run or a green
   single test file is not a substitute for the actual command CI runs.

The Task Graph decides *which* loops apply; these seven decide how any loop, once open, is run
honestly. Skills add domain detail on top of both — they never loosen either.
