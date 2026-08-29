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
         skills/aiskills-build-discipline/SKILL.md README.md \
         install.sh output-styles/loops-within-loops.md \
         hosts/kiro-steering.md hosts/README.md \
         .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if [ -e "$p" ]; then say_pass "structure: $p exists"; else say_fail "structure: $p is missing"; fi
done

# install.sh must parse, be executable, and honour --dry-run without touching anything
if bash -n install.sh 2>/dev/null; then say_pass "install.sh: passes bash -n"; else say_fail "install.sh: syntax error"; fi
[ -x install.sh ] && say_pass "install.sh: is executable" || say_fail "install.sh: not executable (chmod +x)"
if CLAUDE_CONFIG_DIR="$(mktemp -d)" bash install.sh --dry-run >/dev/null 2>&1; then
  say_pass "install.sh --dry-run: exits 0 and changes nothing"
else
  say_fail "install.sh --dry-run: non-zero exit"
fi

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
# 4. Agent specs — plain *.md (the extension Claude Code plugins discover),
#    each with name+description frontmatter and a brain-contract reference.
#    Legacy *.agent.md must NOT remain: a plugin's agents/ scan ignores them.
# ---------------------------------------------------------------------------
if ls agents/*.agent.md >/dev/null 2>&1; then
  say_fail "agents: legacy *.agent.md file(s) present — plugins only discover agents/*.md (rename them)"
else
  say_pass "agents: no legacy *.agent.md files (plugin-discoverable *.md only)"
fi
md_agents=0
for f in agents/*.md; do
  [ -e "$f" ] || continue
  md_agents=$((md_agents+1))
  name="$(basename "$f" .md)"
  if ! grep -q "^name: $name$" "$f"; then say_fail "agent $name: frontmatter name: doesn't match filename"; else say_pass "agent $name: name: matches filename"; fi
  if ! grep -q '^description:' "$f"; then say_fail "agent $name: frontmatter has no description:"; else say_pass "agent $name: has description:"; fi
  if ! grep -q 'loop-contract.md' "$f"; then say_fail "agent $name: doesn't reference brain/loop-contract.md"; else say_pass "agent $name: references the brain contract"; fi
done
[ "$md_agents" -ge 4 ] && say_pass "agents: found $md_agents agents/*.md specs" || say_fail "agents: expected >=4 agents/*.md specs, found $md_agents"

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
# 8. Host adapters — every self-contained adapter that RESTATES brain + grammar
#    for a host with no skill loader must carry frontmatter and every
#    load-bearing phrase, so it can't silently drift out of sync with
#    brain/loop-contract.md and skills/aiskills-agentic-loops/SKILL.md.
#
#    Covered: output-styles/*.md (Claude Code) and hosts/*.md (Kiro steering,
#    and any future self-contained host adapter). hosts/README.md is wiring
#    notes, not a restatement, so it is skipped. Each adapter declares its
#    required frontmatter key after the '|'.
# ---------------------------------------------------------------------------
adapter_specs="output-styles/loops-within-loops.md|^name:
hosts/kiro-steering.md|^inclusion:"
while IFS='|' read -r adapter fmkey; do
  [ -z "$adapter" ] && continue
  base="$adapter"
  if [ ! -f "$adapter" ]; then say_fail "adapter $base: missing"; continue; fi
  if [ "$(head -1 "$adapter")" != "---" ]; then say_fail "adapter $base: no frontmatter"; continue; fi
  grep -qE "$fmkey" "$adapter" && say_pass "adapter $base: has frontmatter $fmkey" \
                               || say_fail "adapter $base: frontmatter missing $fmkey"
  miss=""
  for phrase in \
    'DONE' 'BLOCKED-EXTERNAL' 'BLOCKED-AMBIGUOUS' 'NO-PROGRESS' 'BUDGET' \
    '◇ PLAN' '◆ ' '.agentic-loops/loop-ledger.md' \
    'L0 Convention' 'L1 Context' 'L2 Build' 'L3 Fan-Out' 'L4 Refinement' \
    'currently-failing test' 'Two strikes' 'ORIENT' 'OBSERVE'; do
    grep -qF "$phrase" "$adapter" || miss="$miss '$phrase'"
  done
  [ -z "$miss" ] && say_pass "adapter $base: retains every load-bearing phrase" \
                 || say_fail "adapter $base: out of sync — missing:$miss"
done <<< "$adapter_specs"

# Any other hosts/*.md (besides README) is assumed to be a self-contained
# restating adapter and must be listed in adapter_specs above — catch drift-in.
for h in hosts/*.md; do
  [ -e "$h" ] || continue
  case "$(basename "$h")" in README.md) continue ;; esac
  case "$h" in
    hosts/kiro-steering.md) : ;;  # already checked above
    *) printf '%s\n' "$adapter_specs" | grep -qF "$h" \
         && say_pass "adapter $h: listed in adapter_specs" \
         || say_fail "adapter $h: present but not listed in check.sh adapter_specs (add it + its phrase checks)" ;;
  esac
done

# ---------------------------------------------------------------------------
# 9. Claude Code plugin manifest — parses, names the plugin, components resolve.
# ---------------------------------------------------------------------------
PJ=.claude-plugin/plugin.json
if [ ! -f "$PJ" ]; then
  say_fail "plugin: $PJ missing"
elif ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$PJ" 2>/dev/null; then
  say_fail "plugin: $PJ is not valid JSON"
else
  say_pass "plugin: $PJ parses as JSON"
  pj_name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("name",""))' "$PJ")"
  [ "$pj_name" = "aiskills" ] && say_pass "plugin: name is 'aiskills'" || say_fail "plugin: name is '$pj_name', expected 'aiskills'"
  for k in version description; do
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get(sys.argv[2]) else 1)' "$PJ" "$k" \
      && say_pass "plugin: has $k" || say_fail "plugin: missing $k"
  done
  # components the plugin ships are discovered from these root dirs
  for d in skills agents output-styles; do
    [ -d "$d" ] && say_pass "plugin: component dir $d/ exists" || say_fail "plugin: component dir $d/ missing"
  done
fi

# ---------------------------------------------------------------------------
# 10. Marketplace manifest — parses, lists the plugin, its source resolves.
# ---------------------------------------------------------------------------
MP=.claude-plugin/marketplace.json
if [ ! -f "$MP" ]; then
  say_fail "marketplace: $MP missing"
elif ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$MP" 2>/dev/null; then
  say_fail "marketplace: $MP is not valid JSON"
else
  say_pass "marketplace: $MP parses as JSON"
  python3 - "$MP" <<'PY'
import json, sys, os
d = json.load(open(sys.argv[1]))
ok = True
def check(cond, msg):
    global ok
    print(("PASS: " if cond else "FAIL: ") + msg)
    ok = ok and cond
check(bool(d.get("name")), "marketplace: has name")
check(bool(d.get("description")), "marketplace: has description (needed for --strict)")
check(bool(d.get("owner", {}).get("name")), "marketplace: owner.name present")
plugins = d.get("plugins", [])
entry = next((p for p in plugins if p.get("name") == "aiskills"), None)
check(entry is not None, "marketplace: lists a plugin named 'aiskills'")
if entry is not None:
    src = entry.get("source")
    check(src is not None, "marketplace: 'aiskills' entry has a source")
    if isinstance(src, str):
        p = os.path.normpath(os.path.join(".claude-plugin", "..", src))
        check(os.path.isdir(p) and os.path.isfile(os.path.join(p, ".claude-plugin", "plugin.json")),
              "marketplace: source %r resolves to a dir containing .claude-plugin/plugin.json" % src)
    check(bool(entry.get("description")), "marketplace: 'aiskills' entry has a description")
sys.exit(0 if ok else 1)
PY
  if [ $? -eq 0 ]; then say_pass "marketplace: manifest content checks passed"; else say_fail "marketplace: manifest content checks failed (see FAIL lines above)"; fi
fi

# ---------------------------------------------------------------------------
# 11. `claude plugin validate` — run it when the CLI is present (skip cleanly
#     otherwise; this repo's CI does not require the CLI).
# ---------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
  for m in "$PJ" "$MP"; do
    if [ -f "$m" ] && claude plugin validate --strict "$m" >/dev/null 2>&1; then
      say_pass "claude plugin validate --strict $m: clean"
    else
      say_fail "claude plugin validate --strict $m: reported errors/warnings (run it directly to see them)"
    fi
  done
else
  say_pass "claude plugin validate: SKIPPED (no 'claude' CLI on PATH) — manifests still checked structurally above"
fi

# ---------------------------------------------------------------------------
echo
echo "----------------------------------------"
echo "check.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
