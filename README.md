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

## Install

### Best mount per host

The brain/skills/agents text is **identical on every host**. What differs is the *mount point*
— the strongest standing-instruction slot the host offers, the one that actually makes the
model follow the discipline rather than merely see it.

| Host | Strongest mount | How to install it | Activate command |
|---|---|---|---|
| **Claude Code** | Output style (edits the system prompt). Shipped by the plugin as `force-for-plugin`. `CLAUDE.md` is soft context — fallback only. | `/plugin marketplace add mayankit/AISkills` then `/plugin install aiskills@aiskills` | **automatic** on plugin enable |
| **Claude Code** (no plugin) | Same output style, copied to `~/.claude/output-styles/` | `git clone https://github.com/mayankit/AISkills && cd AISkills && ./install.sh` | `install.sh` sets `outputStyle` in `settings.json`; start a new session (or `/config` → Output style → **Loops Within Loops**) |
| **Codex / any `AGENTS.md` host** | `AGENTS.md` (repo) or `~/.codex/AGENTS.md` — Codex has no separate user-editable system-prompt file, so `AGENTS.md` *is* the strongest persistent slot | `cat "$AISKILLS_HOME/brain/loop-contract.md" >> AGENTS.md` | loaded every turn `AGENTS.md` is read; `export AISKILLS_HOME=<clone>` for skills |
| **Kiro** | Steering file, front-matter `inclusion: always` (strongest slot Kiro has; the discipline is reported to work well here) | `cp hosts/kiro-steering.md .kiro/steering/loops-within-loops.md` | always-on once saved |
| **Cursor** | Project Rules `.cursor/rules/*.mdc` (type **Always**) or legacy `.cursorrules` | paste `brain/loop-contract.md` into the rule | always-on rule; `export AISKILLS_HOME=<clone>` for skills |
| **Windsurf** | `.windsurf/rules/*.md` (activation **Always On**) or legacy `.windsurfrules` | paste `brain/loop-contract.md` into the rule | always-on rule; `export AISKILLS_HOME=<clone>` for skills |
| **Generic / any other** | whatever standing-context slot it has (system prompt, instructions field) | put `brain/loop-contract.md` there; make `skills/` readable | always-on |

`export AISKILLS_HOME=<clone>` is all a non-Claude host needs — the brain's bootstrap resolves
the skills across `$AISKILLS_HOME/skills` → `~/.claude/skills` → `./.claude/skills` → `./skills`
(first hit wins). Without a shell the discipline still holds: the agent emits the same
`◇`/`◆` lines as plain text instead of piping them through `loop-status.sh`.

Only two hosts need a ready-made **adapter file** (a self-contained restatement of the brain +
essential grammar, for a host with no skill loader): Claude Code
(`output-styles/loops-within-loops.md`) and Kiro (`hosts/kiro-steering.md`). Everywhere else
the plain `brain/loop-contract.md` paste plus `AISKILLS_HOME` is enough. See
[`hosts/README.md`](hosts/README.md) for the full per-host wiring and the adapter sync rule.

### Claude Code — the plugin (recommended)

```
/plugin marketplace add mayankit/AISkills
/plugin install aiskills@aiskills
```

The plugin *is* this repository (`.claude-plugin/plugin.json` +
`.claude-plugin/marketplace.json` at the root). It ships all 16 `aiskills-*` skills, the 4
agents, and the **Loops Within Loops** output style. Because that style is marked
`force-for-plugin: true`, enabling the plugin applies the loop discipline to the main thread
**automatically** — there is no `/output-style` step (the standalone `/output-style` command
was removed in Claude Code v2.1.91; the manual fallback is `/config` → Output style).

Start a new session and ask for a real task (`build X, test-first`) — you should see a
`◇ PLAN` tree before the first tool call, `◆` status lines per loop transition, and a ledger
at `<first-non-repo-parent>/.agentic-loops/loop-ledger.md`. Disable with
`/plugin disable aiskills@aiskills`.

`claude plugin validate --strict` passes on both `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`; `tests/check.sh` re-runs that whenever the CLI is present.

### Claude Code — `install.sh` (non-plugin)

For a Claude Code setup without the plugin (or to see exactly what the plugin wires):

```bash
git clone https://github.com/mayankit/AISkills && cd AISkills
./install.sh                 # copies skills + agents + the output style from this repo,
                             # then sets "outputStyle": "Loops Within Loops" in settings.json
./install.sh --dry-run       # show exactly what it would do
./install.sh --no-activate   # install the files, don't touch settings.json
./install.sh --uninstall     # remove everything it installed (backups left as *.aiskills-bak)
```

`install.sh` honours `$CLAUDE_CONFIG_DIR`, is safe to re-run, and needs only `bash` + `python3`
(the latter just for the one `settings.json` key — skip it with `--no-activate`). By hand it is:

```bash
mkdir -p ~/.claude/output-styles ~/.claude/skills ~/.claude/agents
cp output-styles/loops-within-loops.md ~/.claude/output-styles/loops-within-loops.md
cp -r skills/aiskills-* ~/.claude/skills/
cp agents/aiskills-*.md ~/.claude/agents/
#   then, inside Claude Code:  /config → Output style → Loops Within Loops
```

`CLAUDE.md` is soft context and the output style supersedes it; `install.sh` removes any older
aiSkills brain block it finds in `~/.claude/CLAUDE.md`.

### Codex / any `AGENTS.md`-reading host

```bash
git clone https://github.com/mayankit/AISkills aiSkills && export AISKILLS_HOME="$PWD/aiSkills"
cat "$AISKILLS_HOME/brain/loop-contract.md" >> AGENTS.md   # repo-level, or ~/.codex/AGENTS.md
# Skills need no copying — the brain's resolution order finds them under $AISKILLS_HOME/skills.
# Agents (optional) — paste an agents/aiskills-<name>.md body as a profile's system prompt.
```

### Cursor / Windsurf / Kiro / other IDE agents

1. **Brain** — Kiro: `cp hosts/kiro-steering.md .kiro/steering/loops-within-loops.md` (it is
   self-contained, front-matter `inclusion: always`). Cursor/Windsurf/others: paste
   `brain/loop-contract.md` into the tool's always-on rules slot.
2. **Skills** — keep this repo cloned in or beside the workspace and
   `export AISKILLS_HOME=<clone>`; the brain's resolution order does the rest.
3. **Agents** — use each `agents/aiskills-<name>.md` body as a custom mode / role prompt.

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
.claude-plugin/
  plugin.json                              # Claude Code plugin manifest (name: aiskills) — repo root IS the plugin
  marketplace.json                         # single-plugin marketplace (name: aiskills)
install.sh                                   # non-plugin Claude Code setup (--dry-run / --uninstall)
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
  aiskills-builder-dev.md                   # default engineer (Build graph)
  aiskills-code-reviewer.md                 # read-only review (Review graph)
  aiskills-incident-investigator.md         # production incidents (Investigate graph)
  aiskills-architect.md                     # shaping + ADRs (Design graph)
output-styles/
  loops-within-loops.md                    # HOST ADAPTER (Claude Code) — brain+grammar as an output style; the plugin's activation path
hosts/
  kiro-steering.md                         # HOST ADAPTER (Kiro) — self-contained, front-matter inclusion: always
  README.md                                # per-host wiring matrix + the adapter sync rule
tests/
  check.sh                                  # structural/behavioral gate + plugin & marketplace & adapter checks
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
