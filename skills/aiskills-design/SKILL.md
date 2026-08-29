---
name: aiskills-design
description: Choosing the right design pattern (GoF + SOLID) for the problem while resisting over-engineering (YAGNI/KISS), and recording significant choices as Architecture Decision Records (ADRs). Use when shaping a new feature, noticing duplication or branching-on-type, and recording a choice that would be expensive to reverse.
---

# Design (patterns + decisions)

**Loop stage:** Design — while shaping/implementing a feature; pick a pattern only if
the problem needs it, and capture the "why" of significant choices before all build time.
When you write code applying a pattern, load `aiskills-build-discipline` (Phase 0 →
RED/GREEN/REFACTOR → VERIFY) for the how — this skill tells you *what* to apply; the build
discipline is shown you build and verify it.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): `L1 Context → Design (ORIENT/DECIDE) → ADR` · stop:decision-recorded (no
build gate unless code follows).

## Usage

Pattern selection (Part 1):
- Designing a new feature/component and deciding how to structure it
- You notice duplication, branching-on-type, or change-pressure in existing code
- Reviewing code for over- or under-engineering

Architecture decisions (Part 2):
- Choosing between architectural approaches, or a technology/library/framework
- Making a decision that would be expensive to reverse
- Other engineers will ask "why did we do it this way?"

---

# Part 1: Design Patterns (problem-first, YAGNI-gated)

Design patterns are a shared vocabulary for recurring problems, not a checklist to apply.
The skill is NOT "know the 23 patterns" — it's recognizing *what kind of problem* a feature is,
whether a known pattern's trade-offs fit the forces in play, and having the discipline to skip
the simplest thing that works when it doesn't.

Golden rule: **the problem picks the pattern; you don't pick a pattern and hunt for a problem.**
A pattern that doesn't remove real, present complexity is just complexity with a fancy name.

## The two forces to balance

1. **Fit** — does the shape of the problem match a pattern's intent?
2. **YAGNI / KISS** — is the complexity the pattern adds justified by complexity that's a cost,
   known? "Might need it someday" is speculative flexibility is a cost, not a feature.

If fit is high but cost is small/stable — skip the pattern, write the direct code.
If fit is high and the problem has real variation/change-pressure — apply the minimal pattern.

### The overriding tie-breaker: existing convention wins

Before applying any pattern, check what the surrounding code already does for this kind of
problem. **If there's an established convention, follow it — even if a "better" pattern
exists.** Consistency across the codebase beats local optimality, unless the current convention is
actively causing bugs/security issues/real maintenance pain, OR it's part of a deliberate,
agreed migration (recorded as an ADR) — never a drive-by rewrite. When you must diverge,
consistently within your change and record why (Part 2).

## Pattern Selection Loop

1. NAME the problem in plain words (what varies? what's stable? what changes together?)
2. CLASSIFY the force:
   - creation is the hard part      → Creational
   - composition/adaptation is hard  → Structural
   - behavior/communication is hard  → Behavioral
   - none / it's just logic          → No pattern; write it plainly (YAGNI)
3. MATCH a candidate pattern by intent (catalog below), name it.
4. VERIFY: is the code now simpler to read, test, and change? If not, back it out —
   the pattern didn't fit.
5. Loop only while genuine complexity remains; stop as soon as the code is clear.

**Rule of three:** don't abstract on the first or second occurrence. The third is when a
pattern usually earns its keep. Refactor toward a pattern when the code tells you to — not up front.

## Quick catalog — by the problem/smell it fixes

### Creational (object creation is the hard part)
| Smell / force | Pattern | Cost to weigh |
|---|---|---|
| `new X()` scattered; type chosen by a flag/enum | Factory Method / Simple Factory | indirection |
| A family of related objects must be built consistently | Abstract Factory | many classes |
| Object has many optional params; step-wise construction | Builder | boilerplate |
| Exactly one shared instance (config, cache, client) | Singleton (use sparingly) | global state, test pain |
| Copying is cheaper/safer than rebuilding | Prototype | clone correctness |

### Structural (composition/adaptation is the hard part)
| Smell / force | Pattern | Cost to weigh |
|---|---|---|
| Incompatible interface you don't own | Adapter | extra layer |
| Add behavior without subclass explosion | Decorator | wrapper chains |
| Simplify a complex subsystem behind one entry point | Facade | can hide too much |
| Many similar objects, memory pressure | Flyweight | shared-state bugs |
| Control access / lazy-load / remote | Proxy | latency surprises |
| Tree of composable operations | Composite | over-generalization |
| Decouple an abstraction from its implementation | Bridge | upfront design |

### Behavioral (behavior/communication is the hard part)
| Smell / force | Pattern | Cost to weigh |
|---|---|---|
| `if/switch` on type to pick an algorithm | Strategy | more classes |
| State-dependent behavior with messy transitions | State | hidden control flow |
| One-to-many notification | Observer | hidden control flow |
| Encapsulate a request (undo, queue, retry) | Command | indirection |
| Fixed steps, varying sub-steps | Template Method | inheritance |
| A request that passes through a chain of handlers | Chain of Responsibility | ordering bugs |
| Ops over an object structure without editing types | Visitor | rigid to new types |

## SOLID (the principles patterns serve)

- **Single responsibility** — one reason to change per unit.
- **Open/closed** — extend without editing existing, stable code (Strategy/Decorator enable this).
- **Liskov substitution** — subtypes must honor the base contract.
- **Interface segregation** — small, focused interfaces over fat ones.
- **Dependency inversion** — depend on abstractions (enables testing/mocking).

Prefer composition over inheritance. Inheritance couples hard; most "flexibility" comes cheaper
from composition and a strategy object.

## Anti-patterns (what to actively avoid)

- **Pattern-itis** — applying a pattern because you know it, not because the problem needs it.
- **Speculative generality** (YAGNI) — abstractions/hooks for imagined future needs. Delete them.
- **Premature abstractions** — a "Manager"/"Helper" that hides everything and owns nothing.
- **God facade** — a Factory/Strategy for a single concrete case. Inline it.
- **DIY taken too far** — coupling to the wrong thing that looks similar cheaper than the wrong
  pattern taken too far — Duplication is cheaper than the wrong abstraction; wait for the rule of three.
- **Singleton as global** — hidden shared mutable state that wrecks testability.

## Verification (did the pattern help?)

- [ ] The pattern removes real, present duplication / branching / coupling (not speculative)
- [ ] Code is easier to read, test, and change than the direct version
- [ ] You can name the problem the pattern solves in one sentence
- [ ] Composition preferred over inheritance where both were options
- [ ] Tests got easier (dependencies injectable/mockable), not harder
- [ ] Matches the existing convention for this problem; any divergence is deliberate and
  documented (ADR, Part 2), not a drive-by rewrite

If any is "no," back out the pattern and write the direct code.

---

# Part 2: Architecture Decision Records (ADRs)

Every significant technical choice should be recorded as an ADR — a decision record for any
context choice made and consequences — so future engineers understand WHY, not just WHAT.

## ADR Template

```markdown
# ADR-NNN: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-NNN]

## Context
What problem or situation requires a decision?
Include constraints, requirements, and forces at play.

## Decision
"We will use X because Y."

## Alternatives Considered
### Option A: [Name]
- Pros / Cons / Why not

## Consequences
### Positive — what becomes easier
### Negative — accepted trade-offs
### Risks — what could go wrong + mitigation

## References
```

## When to write an ADR

Always:
- Choosing a database, cache, or message queue
- Defining an API contract (especially public APIs)
- Selecting a service framework or major library
- Deciding on a deployment strategy; build-vs-buy
- A performance/cost/complexity trade-off
- Splitting or merging services
- Deliberately diverging from an established code convention (Part 1's tie-breaker)

Don't bother:
- Following an established team pattern
- Minor implementation details within a function
- Equally-valid approaches with no trade-offs

## Decision-making framework

1. **Define constraints first** — operational simplicity (can on-call manage it?),
   availability, security, operational cost. The
   non-negotiables filter the option set before preferences do.
2. **Enumerate options** — for each: how it meets the constraints, operational cost, blast
   radius of failure.
3. **Apply weighted criteria** (can on-call manage it?), team expertise, time to deliver. Prefer the
   reversible option when scores are close.
4. **Record it now** — the ADR is the artifact; a decision that isn't written down will be
   re-litigated. High-stakes decisions get a doubt pass (`aiskills-doubt-driven-development`) on its
   load-bearing claims before marking Accepted.
