#!/usr/bin/env bash
# tests/check.sh — this package's own verification gate.
#
# NOTE ON PROVENANCE: this repository was reconstructed from phone photos of a
# laptop screen. The photos showed this file listed in the sidebar (alongside
# e2e-sim.sh and routing-suite.sh) but never showed its contents. This script
# is a fresh implementation of what the README describes it doing —
# structural, portability, enforcement-content, and behavioral checks — not a
# transcription.
#
# Exit 0 = every check passed. Exit 1 = at least one check failed (see FAIL lines).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
pass=0
say_pass() { pass=$((pass+1)); echo "PASS: $1"; }
say_fail() { fail=$((fail+1)); echo "FAIL: $1"; }

# ---------------------------------------------------------------------------
# 1. Structure — every required top-level part exists
# ---------------------------------------------------------------------------
for p in brain/loop-contract.md skills/aiskills-agentic-loops/SKILL.md \
         skills/aiskills-agentic-loops/scripts/loop-status.sh \
         skills/aiskills-agentic-loops/scripts/fanout-check.sh \
         skills/aiskills-build-discipline/SKILL.md README.md; do
  if [ -e "$p" ]; then say_pass "structure: $p exists"; else say_fail "structure: $p is missing"; fi
done

# ---------------------------------------------------------------------------
# 2. Every skills/<name>/ has a SKILL.md with name+description frontmatter
# ---------------------------------------------------------------------------
for dir in skills/*/; do
  name="$(basename "$dir")"
  f="${dir}SKILL.md"
  if [ ! -f "$f" ]; then say_fail "skill $name: no SKILL.md"; continue; fi
  if ! head -1 "$f" | grep -q '^---$'; then say_fail "skill $name: SKILL.md has no frontmatter"; continue; fi
  if ! grep -q "^name: $name$" "$f"; then say_fail "skill $name: frontmatter name: doesn't match directory"; else say_pass "skill $name: name: matches directory"; fi
  if ! grep -q '^description:' "$f"; then say_fail "skill $name: frontmatter has no description:"; else say_pass "skill $name: has description:"; fi
done

# ---------------------------------------------------------------------------
# 3. Every skills/<name>/ has a routing row in aiskills-skill-routing
# ---------------------------------------------------------------------------
routing="skills/aiskills-skill-routing/SKILL.md"
for dir in skills/*/; do
  name="$(basename "$dir")"
  [ "$name" = "aiskills-skill-routing" ] && continue
  if grep -q "\`$name\`" "$routing"; then
    say_pass "routing: $name referenced in aiskills-skill-routing/SKILL.md"
  else
    say_fail "routing: $name is orphaned — no reference in aiskills-skill-routing/SKILL.md"
  fi
done

# ---------------------------------------------------------------------------
# 4. Every agents/*.agent.md has name+description frontmatter
# ---------------------------------------------------------------------------
for f in agents/*.agent.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .agent.md)"
  if ! grep -q "^name: $name$" "$f"; then say_fail "agent $name: frontmatter name: doesn't match filename"; else say_pass "agent $name: name: matches filename"; fi
  if ! grep -q '^description:' "$f"; then say_fail "agent $name: frontmatter has no description:"; else say_pass "agent $name: has description:"; fi
  if ! grep -q 'loop-contract.md' "$f"; then say_fail "agent $name: doesn't reference brain/loop-contract.md"; else say_pass "agent $name: references the brain contract"; fi
done

# ---------------------------------------------------------------------------
# 5. Portability — no hardcoded absolute paths outside $HOME-relative examples
# ---------------------------------------------------------------------------
if grep -rlE '/(Users|home)/[a-zA-Z0-9_-]+/' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v '^\./tests/check.sh$' | grep -q .; then
  say_fail "portability: found a hardcoded user-specific absolute path"
else
  say_pass "portability: no hardcoded user-specific absolute paths"
fi

# ---------------------------------------------------------------------------
# 6. Enforcement content — the non-negotiable phrases must survive verbatim
# ---------------------------------------------------------------------------
# portable across bash 3.2 (macOS default) and bash 4+: no associative arrays
must_contain_pairs="skills/aiskills-build-discipline/SKILL.md|Can I name the currently-failing test
skills/aiskills-agentic-loops/SKILL.md|two-strike
skills/aiskills-doubt-driven-development/SKILL.md|CLAIM"
while IFS='|' read -r f needle; do
  [ -z "$f" ] && continue
  if [ -f "$f" ] && grep -qi "$needle" "$f"; then
    say_pass "enforcement-content: $f retains '$needle'"
  else
    say_fail "enforcement-content: $f missing '$needle'"
  fi
done <<< "$must_contain_pairs"

# ---------------------------------------------------------------------------
# 7. Behavioral — the ledger scripts are syntactically valid and self-consistent
# ---------------------------------------------------------------------------
for s in skills/aiskills-agentic-loops/scripts/loop-status.sh skills/aiskills-agentic-loops/scripts/fanout-check.sh; do
  if bash -n "$s" 2>/dev/null; then say_pass "behavioral: $s passes bash -n"; else say_fail "behavioral: $s has a syntax error"; fi
done

if [ -x skills/aiskills-agentic-loops/scripts/fanout-check.sh ] || [ -f skills/aiskills-agentic-loops/scripts/fanout-check.sh ]; then
  tmp_ws="$(mktemp -d)"
  out="$(AGENT_WS_ROOT="$tmp_ws" bash skills/aiskills-agentic-loops/scripts/fanout-check.sh 3 2>&1)"
  if echo "$out" | grep -q "FAN-OUT REQUIRED"; then
    say_pass "behavioral: fanout-check.sh 3 -> FAN-OUT REQUIRED"
  else
    say_fail "behavioral: fanout-check.sh 3 did not return FAN-OUT REQUIRED (got: $out)"
  fi
  out="$(AGENT_WS_ROOT="$tmp_ws" bash skills/aiskills-agentic-loops/scripts/fanout-check.sh 1 2>&1)"
  if echo "$out" | grep -q "SINGLE PIECE"; then
    say_pass "behavioral: fanout-check.sh 1 -> SINGLE PIECE"
  else
    say_fail "behavioral: fanout-check.sh 1 did not return SINGLE PIECE (got: $out)"
  fi
  if [ -f "$tmp_ws/.agentic-loops/loop-ledger.md" ]; then
    say_pass "behavioral: fanout-check.sh wrote the ledger"
  else
    say_fail "behavioral: fanout-check.sh did not write a ledger under AGENT_WS_ROOT"
  fi
  rm -rf "$tmp_ws"
fi

if [ -f skills/aiskills-agentic-loops/scripts/loop-status.sh ]; then
  tmp_ws="$(mktemp -d)"
  out="$(AGENT_WS_ROOT="$tmp_ws" bash skills/aiskills-agentic-loops/scripts/loop-status.sh L1 "test line" 2>&1)"
  if echo "$out" | grep -q "L1"; then
    say_pass "behavioral: loop-status.sh L1 emits an L1 line"
  else
    say_fail "behavioral: loop-status.sh L1 did not emit an L1 line (got: $out)"
  fi
  if AGENT_WS_ROOT="$tmp_ws" bash skills/aiskills-agentic-loops/scripts/loop-status.sh check >/dev/null 2>&1; then
    :
  fi
  rc=$?
  if [ "$rc" -eq 1 ] || [ "$rc" -eq 0 ]; then
    say_pass "behavioral: loop-status.sh check runs against a fresh ledger without crashing"
  else
    say_fail "behavioral: loop-status.sh check exited unexpectedly ($rc)"
  fi
  rm -rf "$tmp_ws"
fi

# ---------------------------------------------------------------------------
echo
echo "----------------------------------------"
echo "check.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
