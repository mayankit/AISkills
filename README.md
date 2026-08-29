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
| **SPINE** | `skills/aiskills-build-discipline/SKILL.md` | The delivery procedure for any code edit: Phase 0 (locate the real target, identify the real verification gate, build a Convention Checklist) → RED → GREEN → REFACTOR → VERIFY → Definition of Done. The coding gate — *"can I name the currently-failing test this code is about to make pass?"* — fires before every implementation write, no exceptions. |
| **LEDGER** | `skills/aiskills-agentic-loops/scripts/{loop-status.sh,fanout-check.sh}` | A running, honest record of what was tried, what worked, what failed, and what changed — the plan tree plus every status line, ISO-timestamped, in `<AGENT_WS_ROOT>/.agentic-loops/loop-ledger.md` (resolved outside any git repo so it's never accidentally committed). The scripts format, append, and audit the ledger; they validate the plan block's structure and the five stop conditions. They are a **convenience, not a runtime** — a host with no shell emits the identical lines as plain text and loses only the file. |

The discipline is a set of **plain-text conventions**, not a product feature: the loop catalog
and the plan/ledger file are markdown and bash that any capable tool-using agent can follow.
The **grammar** itself — the taxonomy (L0 Convention, L1 Context, L2 Build & Self-Correct,
L3 Fan-Out, L4 Refinement), OODA iteration, status-line format, the plan tree, the two-strike
rule, same-turn parallel fan-out — lives in exactly one place: `skills/aiskills-agentic-loops/SKILL.md`.
Every other skill declares a one-line `Loop subgraph` in that grammar instead of restating any
of it; loading a skill mid-task splices its subgraph into whatever loop is already open.

```
ALWAYS-ON        brain/loop-contract.md
(BRAIN)          Task Graph (task type → loop graph, which skills to load)
                 7 non-negotiable rules · picks the root graph, defers "how" to —

GRAMMAR          skills/aiskills-agentic-loops/SKILL.md
(single owner)   OODA · loop catalog · plan tree · status lines · two-strike rule
                 loop-status.sh + fanout-check.sh → LEDGER at
                 <workspace-root>/.agentic-loops/loop-ledger.md
                       every other skill splices its Loop subgraph in here —

SPINE            skills/aiskills-build-discipline/SKILL.md
(Build graph)    Phase 0 → RED → GREEN → REFACTOR → VERIFY
                 coding gate · anti-rationalization table · Definition of Done
```

## The 16 skills

Loaded on demand, routed by task type (see `aiskills-skill-routing` for the full intent → skill table).

| Skill | What it governs |
|---|---|
| `aiskills-agentic-loops` | The grammar itself — OODA, the loop catalog, plan trees, status lines, fan-out, the ledger scripts |
| `aiskills-build-discipline` | The TDD spine — Phase 0, RED/GREEN/REFACTOR/VERIFY, coding standards, Definition of Done |
| `aiskills-design` | Problem-first pattern selection (YAGNI-gated), and recording Architecture Decision Records |
| `aiskills-api-design` | REST/GraphQL/RPC contracts: versioning, pagination, idempotency, backward compatibility |
| `aiskills-doubt-driven-development` | The `DOUBT` splice — CLAIM → EXTRACT → DOUBT → RECONCILE → STOP for high-stakes changes |
| `aiskills-code-review` | Seven-dimension review methodology, severity-classified findings, context-widening first |
| `aiskills-security-review` | The security lens — injection, auth/authz, secrets, dependency risk, infra & operations |
| `aiskills-debugging-recovery` | Five-step triage — reproduce → localize → reduce → fix → guard |
| `aiskills-performance-tuning` | Measure-first optimization — baseline → profile → fix the bottleneck → verify |
| `aiskills-observability` | Golden Signals, structured logging, alarms with runbooks, dashboards designed as code |
| `aiskills-multi-agent-patterns` | Contract-first decomposition, same-turn parallel dispatch, the orchestrated join |
| `aiskills-incident-investigation` | Triage → Scope → Mitigate first → Hypothesize → Verify with timeline evidence → Guard |
| `aiskills-session-control` | Distill-then-drop, context budgets, structured handoffs and a resume protocol |
| `aiskills-continuous-learning` | Session lessons → gitignored local overlay; validated lessons graduate via a promotion gate |
| `aiskills-capability-creation` | The self-extension path — propose a new skill/agent on a recurring gap, build it with full discipline |
| `aiskills-skill-routing` | The intent → skill index — "how does the agent know when to use what?" |

## The 4 agents

Ready-to-use roles in `agents/` that wire the skills together. Each is frontmatter
(`name`/`description`) plus a system prompt that defers to the brain and names its own skills —
none of them restate the loop grammar or the build spine, they just point at them.

| Agent | Use it for | Loads |
|---|---|---|
| `aiskills-builder-dev` | The default engineer: build features, fix bugs, refactor — full TDD spine, closed loop to a verified done | `aiskills-build-discipline`, `aiskills-design`, `aiskills-doubt-driven-development`, `aiskills-debugging-recovery`, `aiskills-code-review`, `aiskills-session-control`, `aiskills-continuous-learning` |
| `aiskills-code-reviewer` | Read-only PR/diff review with visible per-dimension passes and severities; never writes code | `aiskills-code-review`, `aiskills-security-review`, `aiskills-doubt-driven-development` |
| `aiskills-incident-investigator` | Live production incidents: mitigate first, hypothesis-driven root cause, structured verification and a blameless review | `aiskills-incident-investigation`, `aiskills-observability`, `aiskills-debugging-recovery` |
| `aiskills-architect` | Shaping before building: pattern selection, API contracts, trade-offs, ADRs — hands off to the spine rather than writing implementation | `aiskills-design`, `aiskills-api-design`, `aiskills-performance-tuning`, `aiskills-observability`, `aiskills-multi-agent-patterns` |

All four load `aiskills-agentic-loops` as their first action and treat `brain/loop-contract.md` as their
always-on contract.

## Install — how to wire this into different tools

Every host needs the same three things wired in: the **brain** always in context, the
**skills** readable on demand, and (optionally) the **agents** as dedicated roles. The content
is identical everywhere — only the **mount point** differs, so use each host's *strongest*
standing-instruction slot, not the lowest common one:

| Host | Brain goes in | Skills readable via | Agents |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` (or a custom **output style** — stronger; `CLAUDE.md` is soft context) | `~/.claude/skills/` or `.claude/skills/` | `~/.claude/agents/*.md` sub-agents |
| Codex / any `AGENTS.md` host | `AGENTS.md` (repo) or `~/.codex/AGENTS.md` | clone kept readable + `export AISKILLS_HOME=<clone>` | paste an agent body as a profile prompt |
| Cursor / Windsurf | `.cursorrules` / `.windsurfrules` / custom-instructions panel | clone beside the workspace + `AISKILLS_HOME` | agent body as a custom mode |
| Kiro | a steering file (`.kiro/steering/*.md`, "always") | clone in/near the workspace + `AISKILLS_HOME` | agent body as a steering-scoped role |
| Any other | wherever it keeps always-on context | any readable path (`$AISKILLS_HOME/skills`, `./skills`, …) | skip if no profile support — brain + skills suffice |

The brain's bootstrap resolves the skill scripts across
`$AISKILLS_HOME/skills` → `~/.claude/skills` → `./.claude/skills` → `./skills` (first hit wins),
so `export AISKILLS_HOME=<clone>` is all a non-Claude host needs.

### Claude Code

```bash
# 1. Skills — user-level (every project)
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/
#   ...or project-level (this repo only): mkdir -p .claude/skills && cp -r skills/* .claude/skills/

# 2. Brain — append once to your memory file (idempotent: the sentinel guards re-runs)
grep -q 'aiskills-brain-begin' ~/.claude/CLAUDE.md 2>/dev/null || {
  printf '\n<!-- aiskills-brain-begin -->\n' >> ~/.claude/CLAUDE.md
  cat brain/loop-contract.md                 >> ~/.claude/CLAUDE.md
  printf '\n<!-- aiskills-brain-end -->\n'   >> ~/.claude/CLAUDE.md
}
#   `CLAUDE.md` is soft context. For a stronger mount, put the same content in a custom
#   output style (~/.claude/output-styles/loops-within-loops.md) and `/output-style` it on.

# 3. Agents (optional) — install as Claude Code subagents
mkdir -p ~/.claude/agents
for a in agents/*.agent.md; do cp "$a" ~/.claude/agents/"$(basename "${a%.agent.md}").md"; done

# 4. Verify: ask Claude to "build X, test-first" in any project — you should see a
#    ◇ PLAN tree before the first tool call, a status line per loop transition, and a real
#    ledger appear at <AGENT_WS_ROOT>/.agentic-loops/loop-ledger.md
```

### Codex / any `AGENTS.md`-reading host

```bash
git clone <this-repo> aiSkills && export AISKILLS_HOME="$PWD/aiSkills"

# 1. Brain — append the contract to the AGENTS.md your host actually reads
cat "$AISKILLS_HOME/brain/loop-contract.md" >> AGENTS.md   # repo-level
#   or ~/.codex/AGENTS.md for a cross-project default, if your host supports one

# 2. Skills — no copying: the brain's resolution order finds them under $AISKILLS_HOME/skills.
# 3. Agents (optional) — paste an agents/aiskills-<name>.agent.md body as a profile's system prompt.
```

### Cursor / Windsurf / Kiro / other IDE agents

1. **Brain** — paste `brain/loop-contract.md` into the tool's persistent slot (`.cursorrules`,
   `.windsurfrules`, a Kiro "always" steering file, or the custom-instructions panel).
2. **Skills** — keep this repo cloned in or beside your workspace and `export AISKILLS_HOME=<clone>`
   (or just clone it as `./skills`); the brain's resolution order does the rest.
3. **Agents** — use each `agents/aiskills-<name>.agent.md` body as a custom mode / role prompt.

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
this repo's own CI gate: structure, cross-reference completeness, the enforcement-critical
phrases, and the ledger scripts' actual behavior.

## Layout

```
brain/loop-contract.md                       # BRAIN — always-on activation authority
skills/
  aiskills-agentic-loops/
    SKILL.md                                 # GRAMMAR — loops, OODA, stops, plan tree, fan-out
    scripts/loop-status.sh                   # LEDGER — validated status-line writer + auditor
    scripts/fanout-check.sh                  # LEDGER — recorded fan-out decisions
  aiskills-build-discipline/SKILL.md         # SPINE — Phase 0 → RED → GREEN → REFACTOR → VERIFY
  aiskills-skill-routing/SKILL.md            # intent → skill index (when to use what)
  aiskills-design/ · aiskills-api-design/ · aiskills-doubt-driven-development/ · aiskills-code-review/ · aiskills-security-review/
  aiskills-debugging-recovery/ · aiskills-performance-tuning/ · aiskills-observability/ · aiskills-multi-agent-patterns/
  aiskills-incident-investigation/ · aiskills-session-control/ · aiskills-continuous-learning/ · aiskills-capability-creation/
                                            # one SKILL.md each — the supporting disciplines
agents/
  aiskills-builder-dev.agent.md             # default engineer (Build graph)
  aiskills-code-reviewer.agent.md           # read-only review (Review graph)
  aiskills-incident-investigator.agent.md   # production incidents (Investigate graph)
  aiskills-architect.agent.md               # shaping + ADRs (Design graph)
tests/
  check.sh                                  # the package's own structural/behavioral gate
  agents/lint_agents.sh                     # do the agent specs commit to their own descriptions?
```

## Extending

Add a new skill as `skills/<name>/SKILL.md` with `name:` and `description:` frontmatter, and if
it participates in loops, a one-line `Loop subgraph` written in the `aiskills-agentic-loops` grammar —
it has exactly one owner and is never restated. Add the new skill's row to `aiskills-skill-routing` so
it's actually reachable. This package practices what it preaches: `tests/check.sh` enforces
that every skill file has a routing row and that the enforcement-critical phrases survive
verbatim — write the failing check first, watch it fail, then write the skill.

For a deeper look at the reasoning behind this design — why loops-within-loops instead of a
single flat agent loop, why the ledger is a hard gate rather than a log, and where this kind of
discipline earns its cost versus where a capable model already does fine on its own — see
**[An AI Agent Architecture](https://medium.com/@mayank.mittal.cool/an-ai-agent-architecture-b3870125456e)**.
