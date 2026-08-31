# Loop Contract (the always-on BRAIN)

This file is the single activation authority for the loop discipline. It is a set of
**conventions written in plain text** — not a product feature and not a runtime enforced by
code. Keep it always in context (system prompt, `CLAUDE.md`/`AGENTS.md` include, Kiro steering,
Cursor rules, or your host's persistent-context mechanism); it stays small on purpose. Skills
and agent prompts MUST NOT restate these rules; they stay lean-on-demand. The detailed
mechanics live in two skills, loaded on demand:

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

Resolve the ledger script and pin the workspace root (requires a shell tool). **Skill
resolution order** — first hit wins, and finding nothing is fine (emit lines as plain text):
`$AISKILLS_HOME/skills` → `~/.claude/skills` → `./.claude/skills` → `./skills`.

```bash
for _d in "${AISKILLS_HOME:-}/skills" ~/.claude/skills ./.claude/skills ./skills; do
  _LOOP_SH=$(find "$_d" -maxdepth 6 -path "*aiskills-agentic-loops/scripts/loop-status.sh" 2>/dev/null | head -1)
  [ -n "$_LOOP_SH" ] && break
done
# Pin the ledger root to the first ancestor that is NOT inside a git repo — a ledger
# committed by accident defeats its purpose. (This mirrors the script's own fallback climb.)
_p=$(pwd)
while _top=$(git -C "$_p" rev-parse --show-toplevel 2>/dev/null); do _p=$(dirname "$_top"); done
export AGENT_WS_ROOT="$_p"
echo "loop-status: ${_LOOP_SH:-none — plain text} · ledger root: $AGENT_WS_ROOT"
```

The ledger scripts are a **recording and formatting convenience**, not a gate: they format a
line, append it ISO-timestamped to `<AGENT_WS_ROOT>/.agentic-loops/loop-ledger.md`, and
(`loop-status.sh check`) audit that a trail exists. `fanout-check.sh` records the fan-out
decision so the ledger shows whether independent pieces opened together. If no shell exists,
emit the identical lines as plain text — the format doesn't change and nothing is lost but the
file.

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
| **Performance / capacity** (slow endpoint, traffic growth — over already-green code) | L1 Context → L4 Refinement [measure → change → verify] over a green L2 | `aiskills-performance-tuning` — measure first; never optimize without data |
| **Research / analysis** (literature review, competitive analysis, "find out whether…") | L0 (read broadly) → L1 (narrow to the question) → L2 with a cite-first gate → L4 (overstated / missing?) | `aiskills-agentic-loops`; L2's "done" is *every claim traced to a real source*, not tests-green |
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
   calls gets a `◇ PLAN` tree emitted before work starts — not after the first action, not only
   once "it turns out to be complicated." A trivial single-step task can skip it; anything else
   can't. The tree's format (indentation, per-line `stop:<condition>`, glyphs) is defined once,
   in `aiskills-agentic-loops` — never redefined per skill.
2. **Signal position continuously — a heartbeat every iteration.** Every loop open, close, and
   DONE gets one status line, and so does **every OODA iteration in between**: a `◆` line
   naming the loop, the phase, and the iteration number (`◆ L2 Build [x] · iter 3 · ACT ·
   stop:… · <what this pass is doing>`), even when nothing opened or closed. `iter N` has a
   space; batched status lines are not a substitute for per-iteration ones. Inside a
   long-running loop, refresh on the shorter of every ~3 iterations or roughly a minute of
   work, and re-emit the `◇ PLAN` tree on that same beat.
   Never run a batch of tool calls with no `◆` line between them — a watcher must be able to
   tell, at any moment, which loop is live, its OODA phase, and its iteration without asking.
   **When a shell exists, the ledger file is written — appended to as each line happens, not
   reconstructed at the end.** A ledger whose entries all share one timestamp
   was written after the fact and does not count. Lines go through the ledger script
   (`aiskills-agentic-loops`'s `loop-status.sh`), or a direct timestamped append, whenever a
   shell is available; the identical plain-text line in the reply is the fallback **only** when
   there is no shell. A task that feels small is not an exception to the ledger or the plan
   tree — the only thing that skips both is a genuinely trivial single-step task (see rule 1).
   A multi-step task with no visible status lines and no ledger entries has left the discipline
   even if the underlying work is fine.
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
   before dispatching the next. Record the decision with `fanout-check.sh <n>` before
   dispatching; the ledger's timestamps then show whether the pieces actually opened together.
6. **Never hand back work you had the tools to finish.** "Here's what you'd need to do next" is
   only acceptable at a genuine `BLOCKED-*` stop, never as a substitute for finishing a task the
   agent could complete itself in the same session.
7. **A build task never ships without its gate passing for real.** `aiskills-build-discipline`'s coding
   gate and VERIFY phase are not optional inside a Build graph; a green lint run or a green
   single test file is not a substitute for the actual command CI runs.

The Task Graph decides *which* loops apply; these seven decide how any loop, once open, is run
honestly. Skills add domain detail on top of both — they never loosen either.

**Right-size the ceremony, never the gate.** The structure is meant to be proportional. On a
small, well-understood change the plan tree is one line, L0 and L1 collapse into a single quick
pass (you already know the file), and L2 is two iterations, not six — and that is correct, not
a shortcut. What does *not* scale down with task size is the gate: a real failing test before
the implementation, and the real verify command run in full at the end, hold whether the diff
is one line or one hundred. If the discipline feels like dead weight on a task, the fix is to
compress the ceremony to match the task — not to skip RED or VERIFY.
