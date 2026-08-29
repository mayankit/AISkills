# Host adapters

The brain, skills, and agents are host-neutral. Most tools only need the brain pasted into
their persistent-context slot and the skills kept readable — no adapter file required.

A **host adapter** lives here when a tool needs the discipline expressed in a specific form to
actually take effect. Each adapter restates the parts of `brain/loop-contract.md` and
`skills/aiskills-agentic-loops/SKILL.md` that an agent needs in order to *act* — the one
sanctioned exception to the package's single-owner rule, because the target slot has no skill
loader. Keep an adapter in sync with those two files; `tests/check.sh` checks the load-bearing
phrases survive.

| File | Host | Why an adapter is needed |
|---|---|---|
| `claude-code-output-style.md` | Claude Code | `CLAUDE.md` is soft context and doesn't reliably drive the loop discipline. An **output style** edits the system prompt itself. Install: `cp hosts/claude-code-output-style.md ~/.claude/output-styles/loops-within-loops.md`, then `/output-style Loops Within Loops`. |
