---
name: aiskills-build-discipline
description: The end-to-end delivery spine for writing and verifying code — MANDATORY for every build, bug-fix, or refactor task. Phase 0 (locate the real target, learn project conventions and recurring feedback), the RED-GREEN-REFACTOR TDD cycle with a hard coding gate, always-on coding standards, behavior-preserving simplification, and the real verification gate (the command CI runs). Load this FIRST for any task that edits code.
---

# Build Discipline

**Loop stage:** Build → Refactor → Verify — the end-to-end delivery spine. This skill covers
the whole cycle: Phase 0 → RED/GREEN/REFACTOR → VERIFY, plus the simplification lens.

**Loop subgraph** (grammar in `aiskills-agentic-loops`): L0 Convention-Model → L1 (if files unknown) →
[RED-GREEN-REFACTOR→VERIFY] · stop:gate-green · L3 Fan-Out for independent pieces.

## ⚠ The non-negotiable — READ AND OBEY THIS FIRST

> **Phase 0 (model) → RED → GREEN → REFACTOR → VERIFY → Definition of Done.**

This spine applies 100% of the time the task edits code. There is no "sometimes TDD" mode: the
only sanctioned variations are the two explicitly documented ones below (characterization tests
for legacy code, and suite-level checks for non-executable artifacts) — both still put a
Definition of Done gate at the end of the change. Anything else is a discipline violation, and
every deviation gets named and declared in writing, not silently taken.

## ⚠ The coding gate — check this BEFORE every implementation file write

**Before creating or editing ANY production/implementation file, answer this question:**

> *"Can I name the currently-failing test that this code is about to make pass?"*

- **YES** — I can name it: proceed to GREEN. Write the minimal code to make that specific test pass.
- **NO** — I cannot name a failing test: STOP. Do not write a single line of implementation.
  You are not RED, not GREEN. Go write the test first, run it, confirm it fails, THEN return here.

This gate fires **every time** — not just at the start of a task. If you finish one GREEN
and start a new one, the gate resets.

This is the enforcement mechanism. The rules below explain *why*; this question is what gates
each write.

The hard rules that make this TDD and not "tests eventually":

1. **No production/implementation code before a failing test exists.** Write the test FIRST,
   run it, SEE it fail. If you are about to write or edit implementation and there
   is no failing test covering that behavior, STOP — you have left the discipline.
2. **Announce each phase.** With `aiskills-agentic-loops` loaded, this is a status line per phase
   transition (see that skill's L2 phase tags: RED/GREEN/REFACTOR/VERIFY/DOUBT). If only this
   skill is loaded, use a simple phase announcement — `RED`, `GREEN`, `REFACTOR`, `VERIFY` — one
   line per transition, not narration of every action inside it.
3. **GREEN is minimal** — only enough code to make the failing test pass, no extras.
4. **REFACTOR only while green** — every change made under REFACTOR is applied with the test
   suite staying green throughout, never against a red suite.
5. **VERIFICATION runs on the real gate** — the command CI runs (identified in Phase 0), not a
   fast subset standing in for it.

Writing tests after the implementation code is validation, not TDD — and does NOT satisfy this
skill. The one sanctioned exception is pre-existing untested code, handled with
`characterization tests` (see "Testing legacy / untested code" below).

# Phase 0 (TDD prerequisite) — MODEL: build a project mental model (before the first RED test)

Do NOT write a test or a line of implementation until you have a mental model of the code you
are about to change. Code written blind to a project's conventions passes the build and still
fails review — and the most expensive version of this mistake isn't a convention miss, it's
implementing the right change in the *wrong place*: editing a generic module when there's a
project-specific one, missing a feature-flag variant and editing the flagged-off fallback
instead, or confusing two similarly-named files. A clean, well-tested, green change in the
wrong file is still wasted work.

## Phase 0, step A — LOCATE the target (do this before conventions)

You cannot build the right way until you know **where**. Detection is cheap if you use the
right anchors:
- **A reference PR, screenshot, or ticket** — if there's a merged PR or a screenshot of the
  feature, use the files it touched as ground truth for *where* the change lives.
- **The running flow** — trace from the actual route/entry point the user sees to the code that
  handles it (grep the call site, follow the route), rather than picking the file that merely
  looks like it should be the one.
- **Disambiguate name collisions explicitly** — if more than one `Carousel`/`Card`/etc. exists
  in the codebase, confirm which one is actually on the live path before touching either; note
  the others so you don't confuse them mid-task.
- **State the exact target path(s) and the anchor** (the PR/ticket, the route trace, the
  call-graph) before writing a line. If you can't confirm the target with confidence, that's a
  NO-PROGRESS signal — delegate a context-gathering scan rather than guess.

## Phase 0, step B — identify the REAL verification gate

Before any test is written, determine the single command that proves the change correct — the
steps CI actually executes, in this priority order:

1. **Read CI config directly** — `.github/workflows/*`, `.circleci/config.yml`,
   `.gitlab-ci.yml`, `Jenkinsfile`. This is ground truth when it exists.
2. **Any runner the repo standardizes on** — `Makefile`, `Taskfile.yml`, `justfile`, or a repo
   script like `scripts/test.sh` / `make check`.
3. **Infer from the package manifest** — `package.json` scripts (`test`, `lint`, `build`),
   `pyproject.toml`/`tox.ini`, `Cargo.toml`'s test target, `go test ./...`,
   `pom.xml`/`build.gradle`'s check task.
4. **No detectable gate** — state that plainly and mark it `[skipped: no gate found]` in the
   Definition of Done — never silently downgrade to "it looks good" as a substitute.

**Write the gate command down exactly as you will run it at VERIFY.** Don't guess and hope
inner-loop checks (one test file, a type-check, a linter run) will substitute for it — VERIFY is
a distinct, run-once gate. "The parts I tested passed" is not the same claim as "the gate passed."

## Phase 0, step C — build the Convention Model

Produce a short, written **Convention Model** for the confirmed target. Scan these four sources:

1. **Structure & layout** — How is the project organized? Where do components, hooks/services,
   styles, types, tests, config/feature flags, and i18n strings live? What are the file-naming
   conventions (`*.styles.tsx`, `*.hook.ts`, `__tests__/`, `*.types.ts`)? Mirror the folder you
   are editing into.
2. **Neighbor code — the strongest signal** — Read 2-3 sibling files closest to what you're
   building (the module next door, its styles file, its test). Copy their shape: imports,
   layering, naming, error handling, test setup. New code should look like it was written by
   the same person who wrote its neighbors.
3. **Enforced rules** — Read the project's lint configuration (`.eslintrc*`, `.ruff.toml`,
   `.golangci.yml`, checkstyle/spotbugs config), formatter config, `CONTRIBUTING.md`,
   pre-commit hooks, and CI-enforced checks. These encode rules an automated reviewer WILL flag.
4. **Review history** — what do reviewers repeatedly flag on merged PRs touching this area
   (`git log --oneline -- <path>`, recent review comments)? Cache the durable lessons to
   `<workspace-root>/.agentic-loops/convention-cache/<project>.md` (gitignored, per
   `aiskills-continuous-learning`) so the next session doesn't re-derive them from scratch.

Apply this as a loop, not a one-shot read. You rarely understand a convention from a single
file — you confirm it by seeing the same shape repeated. Iterate until the model stops changing.

**If this change generalizes, extends, or replaces an existing narrower implementation of the
same concept** (a sibling branch, an earlier commit, a smaller version of the same feature
elsewhere in this codebase's history) — this is a fifth, mandatory source, not optional: read
that prior implementation's actual code, not just its name or its commit message, and write
down what it *supports*, not just how it's styled. Two failure modes this specifically guards
against, both real and both missed by green tests before this rule existed:
  - **Silently narrowing capability.** The new, more general version must support everything
    the narrower prior version already did, unless you have an explicit, stated reason to drop
    something. "I referenced the prior branch" is not the same claim as "I preserved what it
    could do" — verify the second one directly, by testing the prior version's specific
    supported cases against the new implementation, not by reading its docstring and assuming.
  - **Re-deriving a hard-won detail from scratch, worse.** If the prior implementation made a
    specific, non-obvious choice (e.g. resolving identity by object rather than by a shared/
    derived field, to correctly distinguish things that only look the same), find out *why*
    before choosing differently — re-solving a subtle problem the codebase already solved,
    slightly wrong, is a regression even though nothing about it looks new or untested.

- The four sources are independent — fan them out concurrently (one subagent per source in the
  SAME turn when subagents exist; parallel reads otherwise).
- When two sources disagree (a neighbor's style overlaps a lint rule differently, or an old PR
  contradicts current code), the enforced rule wins, and the most-recently-touched neighbor
  breaks any remaining tie. Record the resolution in the checklist and don't keep re-scanning
  past it.

**Output — the Convention Checklist you carry into RED/REFACTOR/VERIFY:**
- [ ] The gate command (the exact command CI runs)
- [ ] Styles/config/strings live where the project puts them, not inlined/hardcoded
- [ ] Business logic lives where it belongs, not mixed into the UI/entry layer
- [ ] No `any`/untyped escape hatches in source or tests
- [ ] Interactive/rendered UI has required accessibility markup
- [ ] Test naming follows the neighbor tests' assertion style

Time-box it: this is a scan, not an audit. Only after the Convention Model exists do you
proceed to RED.

---

# The TDD cycle — RED → GREEN → REFACTOR

## TDD Phase 1 — RED — write a failing test FIRST (before any implementation)

1. Identify the next smallest behavior to implement
2. Write a test that asserts that behavior
3. Run the test — it MUST fail
4. If it passes, your test is wrong or the behavior already exists

**Rules:**
- Test one behavior per test case; Arrange → Act → Assert structure
- Descriptive names that read as requirements: `shouldReturnEmptyListWhenNoOrdersExist`
- No implementation code exists yet
- **When enriching existing output with a new field**, trace the existing code's data flow to
  identify its **selection points** before writing the assertion — where does the code narrow
  from candidates to the one winner (sort, filter, first-match)? Your new field's expected
  value must come from that same winner, not from "all candidates." A wrong assumption here
  produces a wrong assertion, which produces an implementation that passes a wrong test.

## TDD Phase 2 — GREEN — write the minimal code to make the failing test pass

- Write the MINIMAL code to pass the test; hardcoding and shortcuts are fine here
- Don't add features the tests don't require; that's REFACTOR's job, if it's needed at all
- Apply the **Coding Standards** (below) as you write — it's the always-on lens

## TDD Phase 3 — REFACTOR — improve the code while every test stays green

- Never refactor tests; make small changes, re-run tests frequently
- Remove duplication, improve naming, extract functions — production AND test code both
- Don't add new behavior during refactoring
- Apply the **Simplification lens** (below) here — that's what REFACTOR *is*

## TDD for non-executable artifacts (prose, prompts, configs, skills)

The spine applies to EVERY change, including artifacts that aren't "code" — markdown, JSON,
YAML, a prompt. RED still comes first: write the failing check (a validation script, a
schema assertion, or a scenario the current artifact fails), run it, SEE it fail, THEN change
the artifact, THEN watch the same check turn green. This is not a lesser rule for
non-executable artifacts — it's the same rule applied to a different kind of test. Doubt pass:
can this check ever actually fail? Prove it by seeding a known defect and confirming the check
catches it, before trusting a green run of it.

---

# Coding Standards — the always-on baseline (applies through GREEN & REFACTOR)

The project's Convention Checklist (from Phase 0) is the overlay — where a project convention
differs from a generic rule here, the project convention wins.

1. **Immutability by default** — prefer `final`/`const`/`readonly`; mutations explicit and localized.
2. **Explicit error handling** — never swallow exceptions; log with context; typed errors;
   handle at the appropriate level.
3. **Single responsibility** — each function does one thing; each file has a focused purpose;
   if you can't name it clearly, it's doing too much.
4. **Naming reveals intent** — `calculateShippingCost()` not `calc()`; booleans read as
   questions (`isReady`, `hasPermission`); collections plural.
5. **File organization** — group by feature; keep files under ~300 lines; mirror source structure.
6. **Documentation — code-level AND user-facing, not just one.** Public APIs get docstrings;
   comments explain WHY, not WHAT. Separately: if the change adds, removes, or changes
   user-facing behavior (a new public API, a new flag, a changed default, a new error case a
   user can hit), the project's user-facing docs (README, a `docs/` site, a CHANGELOG/CHANGES
   file — whichever this project actually uses, per the Convention Checklist) get updated in
   the SAME change, not filed as a follow-up. A docstring is not a substitute for this — a
   docstring lives where the maintainer already is; user-facing docs are for everyone else. This
   is not optional scope creep — a feature with no way for its users to discover it isn't done.
   Determine which docs this project actually maintains during Phase 0 (a `docs/` directory in
   the tree, a documented site-generator, or a `CHANGES.md`/`CHANGELOG.md` at the repo root are
   the usual signals); if the project genuinely has none, say so explicitly rather than silently
   skipping this standard.
7. **Fail loudly on an unresolvable reference — never silently no-op.** Any time a change
   introduces a declared reference from one thing to another by name or identifier (a config key
   naming another config key, an option naming a sibling option, a plugin naming a hook it
   attaches to), an unresolvable reference is a defect that raises immediately and explicitly —
   never a value that's silently absent, an empty match treated as "no conflict"/"no match", or
   a condition that quietly never fires. Test this directly: construct the broken-reference case
   (the typo, the renamed target, the missing entry) and confirm the code raises — don't just
   test the happy path and assume the failure path "obviously" works. A reference-based feature
   that degrades to doing nothing when given bad input is worse than one that doesn't exist,
   because it looks like it's working.
8. **Deduplicate and key by identity, never by a derived or shared field, unless you've proven
   that field is actually 1:1 with identity.** Two distinct things can legitimately share a
   name, a label, or a destination — collapsing them because they share that field is a
   different bug from the one you're trying to prevent (skipping a genuine duplicate). Before
   using any field as a dedup/lookup key, ask: can two different real entities legitimately
   share this value? If yes, key by object identity (or a genuine unique id) and use the shared
   field only for *display*, not for equality. Write the test that would catch the confused
   case explicitly (two distinct things sharing the derived field, both expected to survive) —
   this is exactly the kind of bug that ships behind a fully green test suite, because the
   tests never constructed the case where the shortcut and the real rule disagree.
9. **Inclusive language** — primary/replica, allowlist/denylist; never the non-inclusive variants.
10. **Conventional Commits** — `<type>(<scope>): <subject>`, imperative mood, subject <50 chars,
    body explains what and why.
11. **Testing floors** — 80%+ line coverage on new code; deterministic, independent tests that
    assert behavior, not implementation.
12. **Security baselines** — no secrets in code; validate all external input; parameterized
    queries; least privilege; encrypt sensitive data in transit and at rest.

---

# Simplification — the REFACTOR lens (behavior-preserving)

Complexity is the enemy of reliability — every line is a liability. This lens preserves
behavior; changing behavior is a feature change, not simplification.

**Chesterton's Fence rule** — before removing or changing code, understand WHY it exists: check
`git blame`, the linked ticket or PR, and only remove code you can explain. If you can't
determine why a guard exists, ASK before removing it.

Techniques: extract method (a 50-line function with 3 sections → 3 well-named helpers); remove
dead code outright (delete it — git remembers it); flatten nesting with guard clauses; replace
magic numbers with named constants (`MAX_RETRIES`); collapse a long parameter list
(`if (a, b, c, d, e)`) into a single options object; split a function that's doing two things
into two functions.

Targets: functions under ~30 lines · cyclomatic complexity under 10 · nesting depth <=3 ·
parameter count <=3 · files under ~300 lines.

Red flags — STOP if any of these show up mid-refactor: the change you're making breaks
correctness (that's a bug with a named failure, not a refactor — revert and start over as a
Build task); you can't explain WHY the code is now simpler after making the change; the
"simpler" version is actually longer; you find yourself unable to explain the code even after
touching it twice.

---

# Testing legacy / untested code (characterization)

When adding tests to code that already exists, you can't start with RED — the behavior is
already there, tested or not.

1. Find a seam to inject/observe behavior without rewriting the code under test
2. Write **characterization tests** that capture the ACTUAL current output (even if it looks
   wrong) — a safety net, not a correctness claim
3. Run and confirm the characterization tests are green against current behavior
4. **Change behind the net** — refactor or fix in small steps, running the tests after each one
5. Resume normal RED-GREEN-REFACTOR for any genuinely new behavior once the seam exists

Don't "fix" surprising behavior while characterizing it; capture it as-is first, then change it
deliberately in a separate, clearly-described step.

Testing anti-patterns to avoid throughout: testing implementation details instead of behavior;
brittle assertions (exact error message text, timestamps); test interdependence (test B only
passes if test A ran first); over-mocking (mock only true external dependencies — network, DB,
clock — never the thing actually under test).

---

# ⛔ VERIFY (final TDD phase) — the quality gate (before commit / PR)

Run these checks in order; fix anything that fails before proceeding. When `aiskills-agentic-loops` is
loaded, this whole phase is the L2 Self-Correct loop, governed by the two-strike rule: the same
failure surviving two fix attempts forces a fundamentally different approach on the third.

1. **The gate is the command from Phase 0, run in full.** Fast inner-loop checks (one test
   file, a type-check, a linter pass alone) are NOT substitutes for the full gate. Don't
   declare done on the strength of the parts.
2. **Build/gate command** — full build + all tests pass; no newly-skipped previously-passing
   tests; coverage target met (80%+ on new code).
3. **Linter / lint checks** — clean, or every unresolved warning commented with a reason.
4. **Security check** — no secrets in the diff (grep for key/token/password patterns); input
   validation on external data; no string-concatenated queries; no wildcard permissions.
5. **Visual check (UI changes only)** — tests are blind to pixels; a green test suite doesn't
   confirm the change looks right. If user-facing UI changed and a local dev setup can run,
   render the actual route/component in the browser and check every affected variant (including
   the flag-off fallback). If that's genuinely unavailable, say so explicitly — never claim the
   UI is correct without having looked at it.
6. **Doubt review (self-review)** — read the diff line-by-line as a wary reviewer would: does it
   satisfy the Convention Checklist? Any debug code left in? Unresolved TODOs? Would the linter
   or a teammate flag anything here? Fix what you find before moving on.
7. **Doubt pass (always)** — proportional to stakes. State the 1-3 load-bearing claims the
   change rests on ("this field is always present," "this migration is additive," "this
   validation runs before the write") and verify each one against the actual code and tests,
   not against what feels obviously true. "It should be fine" is not a verification. For
   anything security-, data-, or production-affecting, run the full
   `aiskills-doubt-driven-development` cycle on every load-bearing claim.

After ANY fix, re-run the FULL gate — a fix can break something else.

---

# Anti-rationalization table (the excuses that skip the discipline)

| What the agent says | Why it's wrong | What to do instead |
|---|---|---|
| "I know how to build this, I'll just start coding" | Green code that ignores project conventions still fails review | Run Phase 0 first — neighbors + lint config + recent PRs → Convention Checklist |
| "Let me write the implementation, I'll add tests after" | That's validation, not TDD — the test is meant to DEFINE the behavior, not confirm it after the fact | Answer the coding gate: "Can I name the currently-failing test?" If not, write it now |
| "This is a small/obvious change, tests aren't needed" | Small changes are exactly where undetected regressions live; "obvious" is not a test | Write the failing test first, see it fail, then implement |
| "I basically already know this works" | Once the implementation feels done in your head, any test you write afterward tends to just confirm what you already believe | Write the failing test first, see it fail, then implement |
| "This folder matches the name, I'll build here" | A name match isn't proof of the real path — a clean, tested change in the wrong module is wasted work | Phase 0 step A: confirm the target against a real anchor |
| "I'll know if it's broken when I use it" | Manual, one-off verification doesn't prevent a regression next week | Write the failing test — it runs every time, not just once |
| "The linter and unit tests passed" | The parts passing is not the same claim as the gate passing | Run the full gate command, not a subset |
| "I'll rewrite this from scratch" (as a "refactor") | Rewrites introduce new bugs; the existing code has battle-tested edge cases baked in | Simplify incrementally, behind passing tests, never in one leap |
| "It's just markdown/config, TDD doesn't apply" | Non-executable artifacts still need a real verification signal | Write the failing check first (see "TDD for non-executable artifacts") |

# Red flags — stop and rethink

- You're about to write code without having read a single neighbor file in the project
- You can't state where styles, logic, types, and tests are supposed to live before writing
- You can't name the specific failing test your next line of code is meant to satisfy
- You can't name the gate command CI runs for this repo
- Verifying the change would require a human eyeballing something manually, and you're treating
  that as equivalent to a passing automated check

# Definition of Done — declare each item before you say "done"

**You may NOT report the task complete until you have addressed ALL items below. No silent
omissions.** Marking an item `skipped: <reason>` is allowed when it's genuinely inapplicable —
what's not allowed is silently dropping the satisfying-looking parts (RED/GREEN passing, a
green gate) while quietly skipping the diligence parts (the convention scan, the self-review,
the doubt pass).

- [ ] **Target located & confirmed** (Phase 0 step A) against a real anchor, not a name match.
- [ ] **Gate identified** (Phase 0 step B): the exact command CI runs.
- [ ] **Phase 0 — all four sources** (structure, neighbors, enforced rules, review history)
  scanned and a Convention Checklist produced and carried through.
- [ ] **Test was RED before implementation** (confirmed it actually failed, not assumed).
- [ ] **Test is GREEN with minimal implementation.**
- [ ] **Refactoring didn't change any test outcomes.**
- [ ] **Coding standards satisfied** (immutability, error handling, naming, inclusive
  language, no secrets, Conventional Commits).
- [ ] **User-facing docs updated to match**, if this change adds/removes/changes anything a
  user of the project can observe (README, `docs/`, CHANGELOG — whichever this project actually
  maintains). Not the same box as docstrings above; check both separately. `skipped: this
  project has no user-facing docs directory or changelog` is a legitimate reason — silently not
  checking is not.
- [ ] **Every declared reference-by-name this change introduces fails loudly on a bad
  reference** — tested with a deliberately broken one (typo/missing target), not just the happy
  path.
- [ ] **No dedup/lookup key in this change is a derived or shared field that two distinct real
  entities could legitimately share** — or if one is, it's backed by object identity underneath,
  not the shared field, and a test constructs the two-distinct-things-sharing-the-field case
  explicitly.
- [ ] **If this generalizes or replaces a narrower prior implementation of the same thing
  elsewhere in this codebase's history, every case the prior version supported still works** —
  verified by actually running those cases against the new code, not by having read the prior
  commit and assumed.
- [ ] **The full gate passed** (the Phase 0 command — not just a fast subset).
- [ ] **Self-review passed on your own diff.**
- [ ] **Doubt pass complete** — the change's 1-3 load-bearing claims stated and each verified
  against real code/tests.
- [ ] **For a user-facing UI change with a local setup available:** rendered output inspected
  for every affected state (each variant/flag value, plus the flag-off fallback).

If any box is `skipped: <reason>`, state that in your final report so the user sees the gap and
can decide whether it matters.
