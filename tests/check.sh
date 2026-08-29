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
  if [ "$(head -1 "$f")" != "---" ]; then say_fail "skill $name: SKILL.md has no opening frontmatter"; continue; fi
  if [ -z "$(awk 'NR>1{ if($0=="---"){print NR; exit} }' "$f")" ]; then say_fail "skill $name: frontmatter block is never closed"; continue; fi
  if ! grep -q "^name: $name$" "$f"; then say_fail "skill $name: frontmatter name: doesn't match directory"; else say_pass "skill $name: name: matches directory"; fi
  if ! grep -q '^description:' "$f"; then say_fail "skill $name: frontmatter has no description:"; else say_pass "skill $name: has description:"; fi
done

# ---------------------------------------------------------------------------
# 3. Every skill is reachable — named in BOTH the intent->skill table AND the
#    master map of aiskills-skill-routing (a mention in prose is not enough).
# ---------------------------------------------------------------------------
routing="skills/aiskills-skill-routing/SKILL.md"
intent_tbl="$(awk '/^## The routing table/{f=1;next} f&&/^## /{f=0} f' "$routing")"
master_tbl="$(awk '/^## Master map/{f=1;next} f&&/^## /{f=0} f' "$routing")"
for dir in skills/*/; do
  name="$(basename "$dir")"
  [ "$name" = "aiskills-skill-routing" ] && continue
  in_intent=0; in_master=0
  printf '%s\n' "$intent_tbl" | grep -q "\`$name\`" && in_intent=1
  printf '%s\n' "$master_tbl" | grep -q "\`$name\`" && in_master=1
  if [ "$in_intent" -eq 1 ] && [ "$in_master" -eq 1 ]; then
    say_pass "routing: $name is in both the intent table and the master map"
  else
    say_fail "routing: $name is orphaned (intent table: $in_intent, master map: $in_master)"
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
if grep -rnE '/(Users|home)/[a-zA-Z0-9_-]+/' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v 'portability-ok' | grep -q .; then
  say_fail "portability: found a hardcoded user-specific absolute path (mark an intentional one with '# portability-ok')"
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

if [ -f skills/aiskills-agentic-loops/scripts/fanout-check.sh ]; then
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
  LS=skills/aiskills-agentic-loops/scripts/loop-status.sh
  tmp_ws="$(mktemp -d)"

  out="$(AGENT_WS_ROOT="$tmp_ws" bash "$LS" L1 "Context · open · iter 1 · ORIENT · stop:can-name-files" 2>&1)"
  case "$out" in
    "◆ L1 "*) say_pass "behavioral: loop-status.sh L1 emits a '◆ L1 …' line" ;;
    *) say_fail "behavioral: loop-status.sh L1 line malformed (got: $out)" ;;
  esac

  # a sibling-suffix level is tolerated, not rejected
  AGENT_WS_ROOT="$tmp_ws" bash "$LS" L2a "Build [x] · open · stop:tests-green" >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 0 ] && say_pass "behavioral: loop-status.sh tolerates a trailing-letter level (L2a)" \
                  || say_fail "behavioral: loop-status.sh rejected L2a (rc=$rc)"

  # STOP must name one of the five conditions
  AGENT_WS_ROOT="$tmp_ws" bash "$LS" STOP "DONE — all green" >/dev/null 2>&1
  rc=$?; [ "$rc" -eq 0 ] && say_pass "behavioral: loop-status.sh STOP DONE accepted" \
                         || say_fail "behavioral: loop-status.sh STOP DONE rejected (rc=$rc)"
  AGENT_WS_ROOT="$tmp_ws" bash "$LS" STOP "BANANA not a condition" >/dev/null 2>&1
  rc=$?; [ "$rc" -eq 2 ] && say_pass "behavioral: loop-status.sh STOP rejects an unknown condition (exit 2)" \
                         || say_fail "behavioral: loop-status.sh STOP accepted a bogus condition (rc=$rc)"

  # a valid PLAN block is accepted; a tab-indented one is rejected
  printf '%s\n' 'TASK demo                         stop:done' \
                '  ◇ PLAN v1: 1 piece' \
                '  ● L0 Convention                   stop:model-stable  ← here' \
    | AGENT_WS_ROOT="$tmp_ws" bash "$LS" PLAN '<-' >/dev/null 2>&1
  rc=$?; [ "$rc" -eq 0 ] && say_pass "behavioral: loop-status.sh accepts a well-formed PLAN block" \
                         || say_fail "behavioral: loop-status.sh rejected a well-formed PLAN block (rc=$rc)"
  printf 'TASK demo stop:done\n\t● L0 Convention stop:model-stable\n' \
    | AGENT_WS_ROOT="$tmp_ws" bash "$LS" PLAN '<-' >/dev/null 2>&1
  rc=$?; [ "$rc" -eq 2 ] && say_pass "behavioral: loop-status.sh rejects a tab-indented PLAN (exit 2)" \
                         || say_fail "behavioral: loop-status.sh accepted a tab-indented PLAN (rc=$rc)"

  # check: real exit code captured (0 healthy / 1 stale-or-incomplete), never a crash
  AGENT_WS_ROOT="$tmp_ws" bash "$LS" check >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ] || [ "$rc" -eq 1 ]; then
    say_pass "behavioral: loop-status.sh check returns a clean 0/1 against a live ledger (rc=$rc)"
  else
    say_fail "behavioral: loop-status.sh check exited unexpectedly (rc=$rc)"
  fi

  rm -rf "$tmp_ws"
fi

# ---------------------------------------------------------------------------
echo
echo "----------------------------------------"
echo "check.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
