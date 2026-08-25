# AISkills — Brain · Spine · Ledger

A portable, host-agnostic discipline layer that turns any capable, tool-using coding agent
(Claude Code, Codex, Cursor, Windsurf, or a custom agent you built yourself) into a
closed-loop engineer: one that plans before acting, verifies before declaring done, and leaves
a real, auditable trail of what it actually did. No proprietary tooling, no hosted service —
plain markdown, bash, and git.

This package is the reference implementation of the architecture described in
**[An AI Agent Architecture](https://medium.com/@mayank.mittal.cool/an-ai-agent-architecture-b3870125456e)**.
Read that first for the *why*; this repo is the *how*.

## The idea, in one paragraph

Most agent failures aren't reasoning failures — they're discipline failures. An agent that's
perfectly capable of writing a correct fix still ships a bug because it never wrote the test
that would have caught it, or drifts off the actual ask three turns into a conversation, or
declares "done" because the code *looks* right rather than because a real gate passed. This
package doesn't make the underlying model smarter. It gives it a grammar for looping —
orient → decide → act → observe, loops nested inside loops, each with a named stop condition —
and a hard gate that won't let it call anything done without a named failing test to point at.
The loop mechanics live in one file; every domain skill just plugs into them.

## The three load-bearing parts

| Part | File(s) | Role |
|---|---|---|
| **BRAIN** | `brain/loop-contract.md` | The single, always-on activation authority. Classifies every incoming task (the Task Graph), decides which loop graph and which skills apply, and carries the seven non-negotiable rules that hold across every graph. Small on purpose — everything else loads on demand. |
| **SPINE** | `skills/build-discipline/SKILL.md` | The delivery procedure for any code edit: Phase 0 (locate the real target, identify the real verification gate, build a Convention Checklist) → RED → GREEN → REFACTOR → VERIFY → Definition of Done. The coding gate — *"can I name the currently-failing test this code is about to make pass?"* — fires before every implementation write, no exceptions. |
| **LEDGER** | `skills/agentic-loops/scripts/{loop-status.sh,fanout-check.sh}` | Every plan tree and status line is validated and appended, ISO-timestamped, to `<workspace-root>/.agentic-loops/loop-ledger.md`, resolved outside any git repo so it's never accidentally committed. Malformed lines are rejected — the validator *is* the discipline, not a suggestion layered on top of one. |

The loop **grammar** itself — the taxonomy (L0 Convention-Model, L1 Context, L2 Self-Correct,
L3 Fan-Out, L4 Refinement), OODA iteration, status-line format, the plan tree, the two-strike
rule, same-turn parallel fan-out — lives in exactly one place: `skills/agentic-loops/SKILL.md`.
Every other skill declares a one-line `Loop subgraph` in that grammar instead of restating any
of it; loading a skill mid-task splices its subgraph into whatever loop is already open.

```
ALWAYS-ON        brain/loop-contract.md
(BRAIN)          Task Graph (task type → loop graph, which skills to load)
                 7 non-negotiable rules · picks the root graph, defers "how" to —

GRAMMAR          skills/agentic-loops/SKILL.md
(single owner)   OODA · loop catalog · plan tree · status lines · two-strike rule
                 loop-status.sh + fanout-check.sh → LEDGER at
                 <workspace-root>/.agentic-loops/loop-ledger.md
                       every other skill splices its Loop subgraph in here —

SPINE            skills/build-discipline/SKILL.md
(Build graph)    Phase 0 → RED → GREEN → REFACTOR → VERIFY
                 coding gate · anti-rationalization table · Definition of Done
```

## The 16 skills

Loaded on demand, routed by task type (see `skill-routing` for the full intent → skill table).

| Skill | What it governs |
|---|---|
| `agentic-loops` | The grammar itself — OODA, the loop catalog, plan trees, status lines, fan-out, the ledger scripts |
| `build-discipline` | The TDD spine — Phase 0, RED/GREEN/REFACTOR/VERIFY, coding standards, Definition of Done |
| `design` | Problem-first pattern selection (YAGNI-gated), and recording Architecture Decision Records |
| `api-design` | REST/GraphQL/RPC contracts: versioning, pagination, idempotency, backward compatibility |
| `doubt-driven-development` | The `DOUBT` splice — CLAIM → EXTRACT → DOUBT → RECONCILE → STOP for high-stakes changes |
| `code-review` | Seven-dimension review methodology, severity-classified findings, context-widening first |
| `security-review` | The security lens — injection, auth/authz, secrets, dependency risk, infra & operations |
| `debugging-recovery` | Five-step triage — reproduce → localize → reduce → fix → guard |
| `performance-tuning` | Measure-first optimization — baseline → profile → fix the bottleneck → verify |
| `observability` | Golden Signals, structured logging, alarms with runbooks, dashboards designed as code |
| `multi-agent-patterns` | Contract-first decomposition, same-turn parallel dispatch, the orchestrated join |
| `incident-investigation` | Triage → Scope → Mitigate first → Hypothesize → Verify with timeline evidence → Guard |
| `session-control` | Distill-then-drop, context budgets, structured handoffs and a resume protocol |
| `continuous-learning` | Session lessons → gitignored local overlay; validated lessons graduate via a promotion gate |
| `capability-creation` | The self-extension path — propose a new skill/agent on a recurring gap, build it with full discipline |
| `skill-routing` | The intent → skill index — "how does the agent know when to use what?" |

## The 4 agents

Ready-to-use roles in `agents/` that wire the skills together. Each is frontmatter
(`name`/`description`) plus a system prompt that defers to the brain and names its own skills —
none of them restate the loop grammar or the build spine, they just point at them.

| Agent | Use it for | Loads |
|---|---|---|
| `builder-dev` | The default engineer: build features, fix bugs, refactor — full TDD spine, closed loop to a verified done | `build-discipline`, `design`, `doubt-driven-development`, `debugging-recovery`, `code-review`, `session-control`, `continuous-learning` |
| `code-reviewer` | Read-only PR/diff review with visible per-dimension passes and severities; never writes code | `code-review`, `security-review`, `doubt-driven-development` |
| `incident-investigator` | Live production incidents: mitigate first, hypothesis-driven root cause, structured verification and a blameless review | `incident-investigation`, `observability`, `debugging-recovery` |
| `architect` | Shaping before building: pattern selection, API contracts, trade-offs, ADRs — hands off to the spine rather than writing implementation | `design`, `api-design`, `performance-tuning`, `observability`, `multi-agent-patterns` |

All four load `agentic-loops` as their first action and treat `brain/loop-contract.md` as their
always-on contract.

## Install — how to wire this into different tools

Every host needs the same three things wired in: the **brain** always in context, the
**skills** readable on demand, and (optionally) the **agents** as dedicated roles. The
mechanism differs per tool; the content doesn't.

### Claude Code

```bash
# 1. Skills — user-level (every project)
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/
#   ...or project-level (this repo only)
mkdir -p .claude/skills && cp -r skills/* .claude/skills/

# 2. Brain — append to your memory file so it's always in context
cat brain/loop-contract.md >> ~/.claude/CLAUDE.md      # global, every project
#   or: cat brain/loop-contract.md >> ./CLAUDE.md       # this project only

# 3. Agents (optional) — install as Claude Code subagents
mkdir -p ~/.claude/agents
for a in agents/*.agent.md; do cp "$a" ~/.claude/agents/"$(basename "${a%.agent.md}").md"; done

# 4. Verify: ask Claude to "build X, test-first" in any project — you should see a
#    ● PLAN tree before the first tool call, a status line per loop transition, and a real
#    ledger appear at <workspace-root>/.agentic-loops/loop-ledger.md
```

### Codex / any `AGENTS.md`-reading host

```bash
git clone <this-repo> aiSkills

# 1. Brain — append the contract to the AGENTS.md your host actually reads
cat aiSkills/brain/loop-contract.md >> AGENTS.md        # repo-level
#   or ~/.codex/AGENTS.md for a cross-project default, if your host supports one

# 2. Skills — keep the clone readable; the brain's own text tells the agent skills live at
#    aiSkills/skills/<name>/SKILL.md and to load them on demand. No copying needed.

# 3. Agents (optional) — paste an agents/<name>.agent.md body as a dedicated profile's
#    system prompt, or at the top of a session when you want that role.
```

### Cursor / Windsurf / other IDE agents

1. **Brain** — paste `brain/loop-contract.md` into the tool's persistent rules file
   (`.cursorrules`, `.windsurfrules`, or your tool's "custom instructions" panel).
2. **Skills** — keep this repo cloned inside or next to your workspace. The brain's own
   resolution order tells the agent to read `skills/<name>/SKILL.md` on demand; nothing to
   configure beyond the file being reachable.
3. **Agents** — use each `agents/<name>.agent.md` body as a custom mode or profile prompt for
   that role.

### GitHub Copilot Workspace / any chat-only agent with file access

Same shape, adapted to whatever "persistent instructions" mechanism the tool exposes (a
`.github/copilot-instructions.md`, a workspace-level system prompt, etc.):
1. Put `brain/loop-contract.md`'s contents wherever that tool keeps always-on context.
2. Make sure the agent can read arbitrary files in the repo — that's all "load a skill on
   demand" requires.
3. Skip the agent roles if the tool doesn't support custom profiles; the brain + skills alone
   are enough for the loop discipline to hold.

### Any other agent (the minimum viable wiring)

Any host that can (a) keep one file always in context and (b) read files on demand can run
this. Put `brain/loop-contract.md` in the system prompt, make `skills/` readable, done. Without
a shell, the discipline still works — the agent emits the same status lines as plain text
instead of piping them through `loop-status.sh`; the format is identical either way.

### Per-project setup (recommended, any host)

```bash
# Keep the ledger and local overlays out of your repos, and pin the ledger root explicitly:
echo ".agentic-loops/" >> <workspace-root>/.gitignore   # if the workspace root is itself a repo
export AGENT_WS_ROOT=<workspace-root>                    # optional; the scripts also auto-resolve it
```

The ledger scripts climb out of any enclosing git work tree by default (the ledger must never
live inside a repository, where it could be accidentally committed) and fall back to `$HOME`.
Setting `AGENT_WS_ROOT` makes the root deterministic instead of inferred.

### Verify the package itself

```bash
bash tests/check.sh              # structural, portability, enforcement-content, behavioral checks
bash tests/agents/lint_agents.sh  # do the 4 agent specs actually commit to what their descriptions promise?
```

Exit 0 on both = every check passed. Run these after editing anything in this package — they're
this repo's own CI gate, and fittingly, `tests/check.sh` was written before most of the content
it verifies.

## Layout

```
brain/loop-contract.md                # BRAIN — always-on activation authority
skills/
  agentic-loops/
    SKILL.md                          # GRAMMAR — loops, OODA, stops, plan tree, fan-out
    scripts/loop-status.sh            # LEDGER — validated status-line writer + auditor
    scripts/fanout-check.sh           # LEDGER — recorded fan-out decisions
  build-discipline/SKILL.md           # SPINE — Phase 0 → RED → GREEN → REFACTOR → VERIFY
  skill-routing/SKILL.md              # intent → skill index (when to use what)
  design/ · api-design/ · doubt-driven-development/ · code-review/ · security-review/
  debugging-recovery/ · performance-tuning/ · observability/ · multi-agent-patterns/
  incident-investigation/ · session-control/ · continuous-learning/ · capability-creation/
                                       # one SKILL.md each — the supporting disciplines
agents/
  builder-dev.agent.md                # default engineer (Build graph)
  code-reviewer.agent.md              # read-only review (Review graph)
  incident-investigator.agent.md      # production incidents (Investigate graph)
  architect.agent.md                  # shaping + ADRs (Design graph)
tests/
  check.sh                            # the package's own structural/behavioral gate
  agents/lint_agents.sh               # do the agent specs commit to their own descriptions?
```

## Extending

Add a new skill as `skills/<name>/SKILL.md` with `name:` and `description:` frontmatter, and if
it participates in loops, a one-line `Loop subgraph` written in the `agentic-loops` grammar —
it has exactly one owner and is never restated. Add the new skill's row to `skill-routing` so
it's actually reachable. This package practices what it preaches: `tests/check.sh` enforces
that every skill file has a routing row and that the enforcement-critical phrases survive
verbatim — write the failing check first, watch it fail, then write the skill.

For a deeper look at the reasoning behind this design — why loops-within-loops instead of a
single flat agent loop, why the ledger is a hard gate rather than a log, and where this kind of
discipline earns its cost versus where a capable model already does fine on its own — see
**[An AI Agent Architecture](https://medium.com/@mayank.mittal.cool/an-ai-agent-architecture-b3870125456e)**.
