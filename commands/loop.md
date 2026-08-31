---
description: Run a task under the aiSkills loop discipline — plan tree first, closed loops, an incremental ledger, a real verify gate.
argument-hint: <what to build / fix / investigate>  [e.g. "add cursor pagination to /users, test-first"]
---

You are running the task below under the **aiSkills loop discipline**. This command
is the opt-in entry point: the structure is not optional here, and the steps run
in this order.

**Task:** $ARGUMENTS

---

## Step 1 — bootstrap the ledger (do this first, before anything else)

```bash
LS="${CLAUDE_PLUGIN_ROOT}/skills/aiskills-agentic-loops/scripts/loop-status.sh"
[ -x "$LS" ] || LS="$(command -v loop-status.sh || true)"
# ledger root = first ancestor of $PWD that is NOT inside a git repo
_p="$PWD"; while _t="$(git -C "$_p" rev-parse --show-toplevel 2>/dev/null)"; do _p="$(dirname "$_t")"; done
export AGENT_WS_ROOT="$_p"
mkdir -p "$AGENT_WS_ROOT/.agentic-loops"
echo "ledger: $AGENT_WS_ROOT/.agentic-loops/loop-ledger.md · loop-status.sh: ${LS:-none (emit plain-text ◆ lines)}"
```

## Step 2 — load the grammar

Load the `aiskills-agentic-loops` skill now. If the task creates or edits **any**
behaviour-affecting file (source, tests, configs, prompts, schemas), also load
`aiskills-build-discipline`. Do not work from this command text alone — those
skills own the loop mechanics and the build spine.

## Step 3 — classify, then emit the `◇ PLAN` tree BEFORE your first real tool call

Classify the task against the Task Graph (Build / Review / Incident / Design /
Performance / Research / Routing). Then emit the plan: a `TASK` root line, a
`◇ PLAN v1:` summary, one indented line per planned loop, each with its own
`stop:<condition>` and a glyph (`○` not started · `●` open · `✓` done · ~~struck~~
abandoned), `← here` on the current line. A genuinely trivial single-step task may
say so and skip the tree — nothing else may.

Record it: pipe the tree through `bash "$LS" PLAN '<-'` when `$LS` exists, else
paste the identical block in your reply.

## Step 4 — run closed loops, with a heartbeat

Work the plan in OODA iterations. **Every iteration emits one `◆` line** — loop,
OODA phase, `iter N` (with the space), `stop:` — appended to the ledger as it
happens (`bash "$LS" <L0|L1|L2|L3|L4> "<text>"` or a direct
`printf '%s  %s\n' "$(date -u +%FT%TZ)" '◆ …' >> "$AGENT_WS_ROOT/.agentic-loops/loop-ledger.md"`).
Not one batch at the end. Re-emit the plan tree at every loop boundary and every
~3 iterations. Two strikes on the same failing approach ⇒ change strategy.

For a Build task: Phase 0 (locate the real target, find the gate CI runs, learn
conventions) → RED (write the failing test, run it, see it fail) → GREEN (minimal
pass) → REFACTOR (green throughout) → VERIFY (the real gate, in full) → Definition
of Done. No implementation line before a named failing test.

## Step 5 — close

End with `bash "$LS" STOP <DONE|BLOCKED-EXTERNAL|BLOCKED-AMBIGUOUS|NO-PROGRESS|BUDGET> "<summary>"`
(or the plain-text `◆ STOP:` line). Report the exact verify command you ran and
its real output — never "looks right". Do not hand back steps you had the tools
to finish.
