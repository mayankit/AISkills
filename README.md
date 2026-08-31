# AISkills — Brain · Spine · Ledger

A portable, host-agnostic discipline layer that turns any capable, tool-using coding agent
(Claude Code, OpenAI Codex, Kiro, Cursor, Windsurf, GitHub Copilot, or a custom agent you
built yourself) into a closed-loop engineer: one that plans before acting, verifies before
declaring done, and leaves a real, auditable trail of what it actually did. No proprietary
tooling, no hosted service — plain markdown, bash, and git. The content is byte-for-byte
identical on every host; only the one-line *mount* differs, and this README gives you that
line for each tool.

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

### The model — three things, on every host

| # | What | Where it goes |
|---|---|---|
| 1 | **BRAIN** — `brain/loop-contract.md`, always in context | the host's *strongest* standing-instruction slot (below) |
| 2 | **SKILLS** — the `skills/` folder, readable on demand | anywhere the agent can read files; pointed to by `AISKILLS_HOME` |
| 3 | **AGENTS** *(optional)* — the 4 role prompts in `agents/` | wherever the host keeps custom roles / sub-agents / modes |

Nothing here is Claude-specific. Pick your host below, run the block, then confirm with
[**"What 'it's working' looks like"**](#what-its-working-looks-like-any-host).

| Host | Strongest mount | Install | Activate |
|---|---|---|---|
| **Claude Code** | Plugin → output style (edits the system prompt). `CLAUDE.md` is soft context — fallback only. | `/plugin marketplace add mayankit/AISkills` → `/plugin install aiskills@aiskills` | **automatic** when the plugin is enabled |
| **Claude Code** (no plugin) | Same output style, copied into `~/.claude/` | `git clone … && ./install.sh` | `install.sh` sets `outputStyle` in `settings.json` |
| **OpenAI Codex** (CLI / IDE) | `AGENTS.md` — repo root, or `~/.codex/AGENTS.md` for every project. Codex has no separate user-editable system prompt, so `AGENTS.md` *is* the top slot. | `cat brain/loop-contract.md >> AGENTS.md` + `export AISKILLS_HOME=<clone>` | every turn `AGENTS.md` is read |
| **Kiro** | Steering file, front-matter `inclusion: always` (Kiro's strongest slot; the discipline is reported to work well here) | `cp hosts/kiro-steering.md .kiro/steering/loops-within-loops.md` + `export AISKILLS_HOME=<clone>` | always-on once the file is saved |
| **Cursor** | Project Rule `.cursor/rules/aiskills.mdc`, rule type **Always** (or legacy `.cursorrules`) | paste `brain/loop-contract.md` into the rule + `export AISKILLS_HOME=<clone>` | always-on rule |
| **Windsurf** | `.windsurf/rules/aiskills.md`, activation **Always On** (or legacy `.windsurfrules`) | paste `brain/loop-contract.md` into the rule + `export AISKILLS_HOME=<clone>` | always-on rule |
| **GitHub Copilot** | `.github/copilot-instructions.md` | paste `brain/loop-contract.md` + keep the repo readable | loaded with the workspace |
| **Any other agent** | whatever standing-context slot it has (system prompt, instructions field) | put `brain/loop-contract.md` there; make `skills/` readable | always-on |

**Adapter files.** Two hosts have no skill loader, so they get a *self-contained* file that
restates the brain + essential grammar inline: Claude Code
([`output-styles/loops-within-loops.md`](output-styles/loops-within-loops.md), shipped by the
plugin) and Kiro ([`hosts/kiro-steering.md`](hosts/kiro-steering.md)). Every other host reads
the real `skills/` on demand, so the plain `brain/loop-contract.md` paste is enough. Full
per-host notes and the adapter-sync rule: [`hosts/README.md`](hosts/README.md).

`export AISKILLS_HOME=<clone>` is all a non-Claude host needs for the skills — the brain's
bootstrap resolves them across `$AISKILLS_HOME/skills` → `~/.claude/skills` →
`./.claude/skills` → `./skills` (first hit wins). No shell? The discipline still holds — the
agent emits the same `◇`/`◆` lines as plain text instead of piping them through `loop-status.sh`.

---

### Claude Code — the plugin (recommended)

```
/plugin marketplace add mayankit/AISkills
/plugin install aiskills@aiskills
```

Then start a **new** session. That's the whole install.

- The plugin **is** this repository (`.claude-plugin/plugin.json` +
  `.claude-plugin/marketplace.json` at the root). It ships all 16 `aiskills-*` skills, the 4
  agents, the **Loops Within Loops** output style, and the `/aiskills:loop` command.
- The output style is marked `force-for-plugin: true`, so enabling the plugin applies the loop
  discipline to the main thread **automatically — there is no manual step.** (The standalone
  `/output-style` command was removed in Claude Code v2.1.91; if you ever need to toggle it by
  hand, use `/config` → Output style.)
- **`/aiskills:loop <task>`** is the opt-in entry point — run it on a specific task to get the
  discipline applied deterministically (bootstrap the ledger, emit the plan tree first, then
  closed loops with an incremental ledger and a real verify gate). Use it when you want the
  structure guaranteed rather than relying on the always-on style.
- Update: `/plugin update aiskills@aiskills`. Disable: `/plugin disable aiskills@aiskills`.
- `claude plugin validate --strict` passes on both manifests; `claude plugin install` from a
  local clone lists the 16 skills + the `loop` command + 4 agents in `claude plugin details`.

### Claude Code — without the plugin (`install.sh`)

For a non-plugin setup, or to see exactly what the plugin wires:

```bash
git clone https://github.com/mayankit/AISkills && cd AISkills
./install.sh                 # copies skills + agents + the output style into ~/.claude/,
                             # then sets "outputStyle": "Loops Within Loops" in settings.json
./install.sh --dry-run       # print every step, change nothing
./install.sh --no-activate   # copy the files, don't touch settings.json
./install.sh --uninstall     # remove everything it installed (*.aiskills-bak backups kept)
```

`install.sh` honours `$CLAUDE_CONFIG_DIR`, is safe to re-run, and needs only `bash` + `python3`
(the latter only for the one `settings.json` key — skip it with `--no-activate`). The same by
hand:

```bash
mkdir -p ~/.claude/output-styles ~/.claude/skills ~/.claude/agents
cp output-styles/loops-within-loops.md ~/.claude/output-styles/loops-within-loops.md
cp -r skills/aiskills-* ~/.claude/skills/
cp agents/aiskills-*.md ~/.claude/agents/
#   then, inside Claude Code:  /config → Output style → Loops Within Loops
```

`CLAUDE.md` is soft context and the output style supersedes it; `install.sh` strips any older
aiSkills brain block from `~/.claude/CLAUDE.md`.

### OpenAI Codex (CLI or IDE) — any `AGENTS.md` host

```bash
git clone https://github.com/mayankit/AISkills aiskills
export AISKILLS_HOME="$PWD/aiskills"                 # add this to your shell profile

# 1 — BRAIN: append the contract to the AGENTS.md your project actually loads
cat "$AISKILLS_HOME/brain/loop-contract.md" >> AGENTS.md
#     …or ~/.codex/AGENTS.md to get it in every project

# 2 — SKILLS: nothing to copy. The brain's bootstrap finds them under $AISKILLS_HOME/skills.
# 3 — AGENTS (optional): paste an agents/aiskills-<name>.md body as a Codex profile / custom prompt.
```

Codex reads `AGENTS.md` on every turn, so the brain is always in context. Confirm with the
signals below.

### Kiro

```bash
git clone https://github.com/mayankit/AISkills aiskills
export AISKILLS_HOME="$PWD/aiskills"                 # add this to your shell profile

# 1 — BRAIN: the steering adapter is self-contained (front-matter `inclusion: always`)
mkdir -p .kiro/steering
cp "$AISKILLS_HOME/hosts/kiro-steering.md" .kiro/steering/loops-within-loops.md

# 2 — SKILLS (optional, for depth): readable via $AISKILLS_HOME/skills once the env var is set.
# 3 — AGENTS (optional): use an agents/aiskills-<name>.md body as a steering-scoped role.
```

Kiro prepends every `inclusion: always` steering file to each turn — this is its strongest
slot, and the discipline is reported to hold well here.

### Cursor

```bash
git clone https://github.com/mayankit/AISkills aiskills
export AISKILLS_HOME="$PWD/aiskills"

mkdir -p .cursor/rules
cp "$AISKILLS_HOME/brain/loop-contract.md" .cursor/rules/aiskills.mdc
#   then set that rule's type to "Always" in Cursor's Rules UI
#   (legacy alternative: paste the same text into .cursorrules)
```

Cursor can read any workspace file, so the plain brain paste plus `AISKILLS_HOME` reaches the
full `skills/` — no adapter needed.

### Windsurf

```bash
git clone https://github.com/mayankit/AISkills aiskills
export AISKILLS_HOME="$PWD/aiskills"

mkdir -p .windsurf/rules
cp "$AISKILLS_HOME/brain/loop-contract.md" .windsurf/rules/aiskills.md
#   then set that rule's activation to "Always On" in Windsurf
#   (legacy alternative: paste the same text into .windsurfrules)
```

### Any other agent (minimum viable wiring)

Any host that can (a) keep one file always in context and (b) read files on demand can run
this:

1. Put the contents of `brain/loop-contract.md` in the host's standing-instructions slot.
2. Keep this repo cloned somewhere readable and `export AISKILLS_HOME=<clone>` (or clone it as
   `./skills` next to your work).
3. Skip the agent roles if the host has no custom-profile mechanism — brain + skills alone
   hold the discipline.

### What "it's working" looks like (any host)

Give the agent a real task (`build X, test-first`). You should see, in order:

- a **`◇ PLAN` tree** in the reply *before* the first tool call — one line per planned loop,
  each with its own `stop:` condition;
- **`◆` status lines** at every loop open / close / STOP (`◆ L2 Build [x] · open · … · stop:tests-green`);
- on a build task, a **failing test written and run first**, before any implementation;
- if a shell is available, a growing **ledger** at
  `<first-non-repo-parent>/.agentic-loops/loop-ledger.md` (outside your repo, so it is never
  committed).

If you see the agent jump straight to editing code with no PLAN tree and no `◆` lines, the
brain isn't in context — re-check step 1 for your host (for Claude Code, confirm the output
style is active with `/config`).

### Keep the ledger out of your repos (any host)

```bash
echo ".agentic-loops/" >> <workspace-root>/.gitignore   # if the workspace root is itself a repo
export AGENT_WS_ROOT=<workspace-root>                    # optional; the scripts also auto-resolve it
```

The ledger scripts climb out of any enclosing git work tree by default (the ledger must never
live inside a repository) and fall back to `$HOME`. Setting `AGENT_WS_ROOT` makes the root
deterministic instead of inferred.

### Verify the package itself

```bash
bash tests/check.sh               # structure, portability, enforcement phrases, discipline claims,
                                  #   plugin + marketplace manifests, adapters
bash tests/agents/lint_agents.sh  # do the 4 agent specs commit to what their descriptions promise?
bash tests/seed-defect-proof.sh   # proves the checks above actually FAIL when a claim is broken
                                  #   (seeds one deliberate defect per guarded check; ~1 min, needs the claude CLI
                                  #   for the live plugin-install proofs). check.sh runs it too with RUN_SEED_PROOF=1.
```

Exit 0 on all = every check passed. `tests/check.sh` also runs `claude plugin validate
--strict` on both manifests **and a real `claude plugin install` into a throwaway config dir**
(asserting Skills = 16, Agents = 4, Hooks = 0, and `force-for-plugin: true` on the shipped
output style) when the `claude` CLI is on `PATH` — and skips those cleanly when it isn't.
Everything runs against a temp directory; nothing touches your real `~/.claude`. Run all three
after editing anything in this package — they are this repo's CI gate.

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
commands/
  loop.md                                  # /aiskills:loop — opt-in per-task discipline entry point
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
