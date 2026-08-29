---
name: aiskills-capability-creation
description: Detect when a recurring gap deserves a NEW skill or agent, propose it to the user, and — on explicit consent — create it with full discipline, in the placement the user chooses (workspace-local overlay or a shared repository). The self-extension path — the agent gets better tools instead of relearning the same lesson every session.
---

# Capability Creation

**Loop stage:** Capture → Build — turns a recurring, validated gap into a new capability
(skill or agent), proposed to the user, and — on the same promotion path — the creation itself
runs the full `aiskills-build-discipline` for the artifact (via `aiskills-build-discipline`) · stop:capability-shipped-or-declined.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **User gate** for the artifact (via `aiskills-build-discipline`) · stop:capability-shipped-or-declined.

## Overview

Overlay notes (`aiskills-continuous-learning`) are the right home for *lessons*. But when the same
class of work keeps needing the same bundle of knowledge — a domain's conventions, a recurring
workflow, the cheaper long-term move is a *capability*: promotion path; the creation itself
a skill (knowledge/procedure loaded on demand) or an agent (a new-role
role with its own task graph, tool posture, or read/write boundary (a reviewer, an
investigator) — defines when the CURRENT agent should propose the new artifact and how to build it.

The agent *proposes*; the human disposes. Creating a capability is never silent and never
automatic — it changes what every future session loads.

## Step 1: DETECT the recurring-gap trigger

Propose a new skill only when ALL hold (checked against real evidence, not vibes):

- **Recurring** — the same gap appeared on 2+ independent occasions (different task or session)
  (see `aiskills-continuous-learning` uses for promotion). One occurrence is a note, not a skill.
- **Bundleable** — the gap is a cluster of related rules/procedure/checklists it would carry
  a single rule stays an overlay note, not a skill.
- **Not already covered** — `aiskills-skill-routing` has no row that matches Primary or extends existing
  and no existing skill could absorb it as a section. Extending existing skills beats
  creating a near-duplicate (the rule of three applies to capabilities too).
- **Worth the load cost** — the capability will plausibly fire again. Speculative skills are
  YAGNI violations with a frontmatter.

Skill vs agent: knowledge/procedure the CURRENT agent should apply → skill. A distinct
role with its own task graph, tool posture, or read/write boundary (a reviewer, an
investigator) → agent.

## Step 2: PROPOSE — the user gate (explicit consent, always)

Present a compact proposal and STOP for the answer (this is a `BLOCKED-EXTERNAL`-style human
gate — a wrong guess pollutes every future session):

```
PROPOSAL: new skill <name>
Gap          : what kept recurring — cite the 2+ occasions
Would hold   : the bundle (conventions/procedure/checklists it would carry)
Not covered  : why no existing skill/routing fits (and why an overlay note is too small)
Cost         : one routed skill loaded only when its row matches
Create it?   (yes / no / fold into existing skill <x>)
```

No consent = record the evidence as an overlay note and move on. Never create "while you're at it."

## Step 3: PLACEMENT — ask where it lives

On yes, ask ONE more question — placement — because it decides who benefits and who reviews:

| Placement | Path | When |
|---|---|---|
| Workspace-local | `<workspace-root>/.agentic-loops/skills/<name>/SKILL.md` | Private to this machine/workspace; no review needed; gitignored the rest of `.agentic-loops/` — never committed. Default when unsure. |
| Shared repository | `<skills-repo>/skills/<name>/SKILL.md` via a reviewed PR | The user wants teammates/other setups to get it. Goes through the same gate + normal review. |

Workspace-local capabilities load overlays: at task start, alongside the installed
package. That's `aiskills-continuous-learning`'s promotion gate applied to a whole shared repository later —
that's `aiskills-continuous-learning`'s promotion gate applied to a whole capability.

## Step 4: BUILD — the new capability gets the full discipline

A capability is a non-executable artifact; `aiskills-build-discipline`'s TDD for
non-executable artifacts applies. In order:

1. **RED — the failing check first.** Shared placement: add the new skill's assertions to the
   repo's `tests/check.sh` (structure, frontmatter, its content markers, a routing row) and
   SEE them fail. Workspace-local placement: write the acceptance checklist in the proposal
   and verify the file fails it before authoring.
2. **GREEN — author the minimal capability.** Frontmatter (`name:` matching the directory,
   `description:` that routes well); a `Loop stage:` line; a `Loop subgraph:` line in
   the grammar which is the ONE owner (`aiskills-agentic-loops`), a new capability NEVER restates
   that defers explicitly to `brain/loop-contract.md` and names its own owner.
3. **ROUTING — Shared:** add the `aiskills-skill-routing` row (the new intent -> skill mapping) so the
   brain can find it next session, and the skill loads cleanly (read back; verify).
4. **VERIFY — Shared:** the repo's full gate green. Local: every acceptance-checklist item
   checked, and the skill loads cleanly (read back; verify).
5. **DOUBT** — One pass on the load-bearing claim — "this capability would have changed a real
   past decision" — with the 2+ occasions as the cited evidence.

## Anti-patterns

- **Silent creation** — a new skill appearing without a proposal and a yes. The user owns the
  package surface.
- **Skill-as-costume** — wrapping one rule in frontmatter; that's an overlay note wearing a costume.
- **Near-duplicates** — a new skill whose row collides with an existing Primary; extend instead.
- **Grammar forks** — a created capability defining its own loop/stops; the grammar has one owner.
- **Unrouted capabilities** — created but unreachable; if `aiskills-skill-routing` (or the local routing
  note) can't route to it, it doesn't exist.
- **Skipping RED because "it's just markdown"** — the check-first rule is exactly how THIS
  package was built; created capabilities inherit it.
