# Host adapters

The BRAIN (`brain/loop-contract.md`), the GRAMMAR (`skills/aiskills-agentic-loops/SKILL.md`),
the SPINE (`skills/aiskills-build-discipline/SKILL.md`), the 16 `aiskills-*` skills and the 4
role agents are **identical text on every host**. Only the *mount point* differs — where the
brain goes so the model actually follows it, and how the skills become readable on demand.

Most hosts need **no adapter file**: paste `brain/loop-contract.md` into the host's strongest
standing-instruction slot, keep this repo cloned and `export AISKILLS_HOME=<clone>`, and the
brain's own resolution order (`$AISKILLS_HOME/skills` → `~/.claude/skills` → `./.claude/skills`
→ `./skills`) finds the skills. An adapter file is only needed when the host has **no skill
loader**, so the brain paste alone can't reach the grammar — then the adapter must be
*self-contained*: it restates the parts of the brain + grammar an agent needs in order to act.

## Files here

| File | Host | Why it exists |
|---|---|---|
| `kiro-steering.md` | Kiro | Kiro has no skill loader. Self-contained restatement, front-matter `inclusion: always`. Drop at `.kiro/steering/loops-within-loops.md`. |
| *(Claude Code)* | Claude Code | Not here — it's `output-styles/loops-within-loops.md` (an output style edits the system prompt; also the `aiskills` plugin's activation path). |

## Hosts that need no adapter (paste the brain, wire `AISKILLS_HOME`)

| Host | Strongest standing slot | Skills |
|---|---|---|
| Codex / any `AGENTS.md` host | `AGENTS.md` (repo) or `~/.codex/AGENTS.md`. Codex also honours a profile / custom "instructions" prompt — use that too if you keep one. | clone readable + `export AISKILLS_HOME=<clone>` |
| Cursor | Project Rules (`.cursor/rules/*.mdc`, "Always") or the legacy `.cursorrules` | clone beside the workspace + `AISKILLS_HOME` |
| Windsurf | `.windsurf/rules/*.md` (activation "Always On") or the legacy `.windsurfrules` | clone beside the workspace + `AISKILLS_HOME` |
| GitHub Copilot / chat-only agents with file access | `.github/copilot-instructions.md` or the tool's persistent-instructions field | any readable clone path |
| Any other | wherever it keeps always-on context | any readable path (`$AISKILLS_HOME/skills`, `./skills`, …) |

Cursor and Windsurf can both read arbitrary workspace files, so the plain brain paste plus
`AISKILLS_HOME` is sufficient — no rules-file *restatement* adapter is shipped for them. If a
future host turns out to need one, add it here as `hosts/<host>.md` **and** register it in
`tests/check.sh` §8 (`adapter_specs`) so its brain/grammar phrases are kept in sync.

## The sync rule

Every self-contained adapter (`output-styles/loops-within-loops.md`, `hosts/kiro-steering.md`,
and any future `hosts/*.md`) carries a comment saying it restates the brain + grammar, and is
phrase-checked by `tests/check.sh` §8 against a fixed list of load-bearing terms (the five stop
conditions, `◇ PLAN`, `◆ `, the ledger path, `L0 Convention`…`L4 Refinement`, the
`currently-failing test` gate, `Two strikes`, `ORIENT`, `OBSERVE`). Edit the brain or the
grammar → update every adapter in the same change, or the check fails.
