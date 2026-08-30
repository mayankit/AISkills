#!/usr/bin/env bash
# tests/seed-defect-proof.sh — prove that tests/check.sh actually FAILS when a
# claim it verifies is broken. For each check added to guard a discipline claim
# (sections 8-13 of check.sh), this seeds ONE deliberate defect into a scratch
# copy of the repo, runs check.sh there, and asserts the matching FAIL fires.
#
# This is the "can this check ever actually fail?" step the build discipline
# requires before trusting a green run. Run it whenever check.sh's claim/plugin
# sections change.
#
# Exit 0 = every seeded defect was caught. Exit 1 = at least one check is a
# no-op (a defect slipped past it) or the harness itself broke.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# Work on a copy of the tracked tree (plus any uncommitted edits to the files
# the proofs touch), so nothing here can corrupt the real repo.
( cd "$ROOT" && git ls-files -z | while IFS= read -r -d '' f; do
    mkdir -p "$SCRATCH/$(dirname "$f")"; cp "$ROOT/$f" "$SCRATCH/$f"
  done )
for f in tests/check.sh brain/loop-contract.md skills/aiskills-agentic-loops/SKILL.md \
         output-styles/loops-within-loops.md hosts/kiro-steering.md \
         .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  [ -f "$ROOT/$f" ] && cp "$ROOT/$f" "$SCRATCH/$f"
done
chmod +x "$SCRATCH/tests/"*.sh 2>/dev/null || true

cd "$SCRATCH"
have_claude=0; command -v claude >/dev/null 2>&1 && have_claude=1

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "PROVEN     $1"; }
bad()  { fail=$((fail+1)); echo "NOT CAUGHT $1  <-- $2 is a no-op check"; }

# run check.sh in the scratch tree, return its full output.
# NB: capture into a var and match with a herestring — never `run_check | grep -q`,
# because grep -q's early exit SIGPIPEs check.sh and `set -o pipefail` then marks
# the whole pipeline failed, hiding real matches.
run_check() { bash tests/check.sh 2>&1; }
check_has_fail() { grep -qE "^FAIL: .*$1" <<<"$2"; }

# seed_md <fail-regex> <file> <sed-script> <description>
#   mutate a markdown/JSON file, expect a FAIL line matching <fail-regex>, restore
seed_md() {
  local re="$1" file="$2" sed_script="$3" desc="$4" out
  cp "$file" "$file.__bak"
  sed -i.__t "$sed_script" "$file" && rm -f "$file.__t"
  out="$(run_check)"
  if check_has_fail "$re" "$out"; then ok "$desc"; else bad "$desc" "check for /$re/"; fi
  mv "$file.__bak" "$file"
}

echo "== section 12: discipline-claim checks (markdown, verbatim) =="
seed_md 'heartbeat/every-iteration.*kiro-steering' hosts/kiro-steering.md            's/every iteration/at loop edges/g'                 'heartbeat: "every iteration" dropped from Kiro adapter'
seed_md 'heartbeat/ooda-state.*loops-within-loops' output-styles/loops-within-loops.md 's/OODA phase/step/g'                             'heartbeat: "OODA phase" dropped from Claude Code adapter'
seed_md 'heartbeat/cadence.*loop-contract'         brain/loop-contract.md             's/minute/while/g'                                  'heartbeat: named cadence ("minute") removed from brain'
seed_md 'heartbeat/no-silent-batch.*agentic-loops' skills/aiskills-agentic-loops/SKILL.md 's/tool calls with no/tool calls without a/g'  'heartbeat: no-silent-batch clause removed from grammar'
seed_md 'heartbeat/line-shape.*loops-within-loops' output-styles/loops-within-loops.md 's/iter 3 . ACT/iteration three/'                 'heartbeat: example status line shape removed from adapter'
seed_md 'ooda/four-phases.*kiro-steering'          hosts/kiro-steering.md             's/OBSERVE/CHECK/g'                                 'OODA: "OBSERVE" phase word removed from Kiro adapter'
seed_md 'plan-before-first-tool-call.*loop-contract' brain/loop-contract.md           's/the first tool call/the first action/g'          'plan-first: "the first tool call" removed from brain'
seed_md 'five-stop-conditions.*agentic-loops'      skills/aiskills-agentic-loops/SKILL.md 's/BUDGET/LIMIT/g'                              'stop-conditions: "BUDGET" removed from grammar'
seed_md 'two-strike.*loop-contract'                brain/loop-contract.md             's/strike/hit/g'                                    'two-strike rule removed from brain'
seed_md 'heartbeat/iter-token.*kiro-steering'      hosts/kiro-steering.md             's/iter N/iteration count/g'                        'heartbeat: "iter N" token spec dropped from Kiro adapter'
seed_md 'ledger/append-incrementally.*agentic-loops' skills/aiskills-agentic-loops/SKILL.md 's/written after the fact/logged whenever/g'    'ledger: incremental-append rule removed from grammar'
seed_md 'ledger/no-small-task-skip.*loop-contract' brain/loop-contract.md             's/trivial single-step task/tiny job/g'             'ledger: "small task is no excuse" removed from brain'

echo
echo "== section 8: adapter phrase-sync =="
seed_md 'adapter output-styles/loops-within-loops.md: out of sync' output-styles/loops-within-loops.md 's/Two strikes/Two hits/' 'adapter drift: a load-bearing phrase removed from the Claude Code adapter'

echo
echo "== section 9/10: plugin + marketplace manifest =="
seed_md 'plugin: name is'  .claude-plugin/plugin.json  's/"name": "aiskills"/"name": "wrong"/'  'plugin.json: plugin name changed'
# marketplace: rename just the plugin ENTRY (not the marketplace name) via python,
# because BSD/GNU sed disagree on the s///N occurrence flag.
cp .claude-plugin/marketplace.json .claude-plugin/marketplace.json.__bak
python3 - <<'PY'
import json
p=".claude-plugin/marketplace.json"; d=json.load(open(p))
d["plugins"][0]["name"]="other"
json.dump(d,open(p,"w"),indent=2); open(p,"a").write("\n")
PY
out="$(run_check)"
if check_has_fail "marketplace: lists a plugin named" "$out"; then ok "marketplace: the aiskills plugin entry renamed"; \
  else bad "marketplace: the aiskills plugin entry renamed" "the plugins[] name check"; fi
mv .claude-plugin/marketplace.json.__bak .claude-plugin/marketplace.json

echo
echo "== section 13a: version agreement =="
seed_md 'plugin e2e: plugin.json version and marketplace' .claude-plugin/plugin.json  's/"version": "[0-9.]*"/"version": "9.9.9"/'        'plugin.json version no longer matches the marketplace entry'

echo
echo "== section 13b: live plugin install + inspect =="
if [ "$have_claude" -eq 1 ]; then
  # Skills (16): remove one skill dir -> details should report 15
  cp -R skills/aiskills-observability "$SCRATCH/.__skill_bak"
  rm -rf skills/aiskills-observability
  out="$(run_check)"
  if check_has_fail 'plugin e2e: details did NOT report Skills \(16\)' "$out"; then
    ok 'plugin e2e: a removed skill is detected (Skills count check)'
  else bad 'plugin e2e: Skills (16) count check' 'the details-count assertion'; fi
  mv "$SCRATCH/.__skill_bak" skills/aiskills-observability

  # Agents (4): remove one agent
  cp agents/aiskills-architect.md "$SCRATCH/.__agent_bak"
  rm -f agents/aiskills-architect.md
  out="$(run_check)"
  if check_has_fail 'plugin e2e: details did NOT report Agents \(4\)' "$out"; then
    ok 'plugin e2e: a removed agent is detected (Agents count check)'
  else bad 'plugin e2e: Agents (4) count check' 'the details-count assertion'; fi
  mv "$SCRATCH/.__agent_bak" agents/aiskills-architect.md

  # force-for-plugin: flip it off
  seed_md 'plugin e2e: installed output style missing or lacks force-for-plugin' \
    output-styles/loops-within-loops.md 's/^force-for-plugin: true$/force-for-plugin: false/' \
    'plugin e2e: force-for-plugin:true removed from the shipped output style'

  # Hooks (0): introduce a real hook (this package must ship none)
  mkdir -p hooks
  cat > hooks/hooks.json <<'HK'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "true" } ] } ] } }
HK
  out="$(run_check)"
  if check_has_fail 'plugin e2e: details reports hooks' "$out"; then
    ok 'plugin e2e: an introduced hook is detected (no-hooks guard)'
  else bad 'plugin e2e: no-hooks guard' 'the Hooks (0) assertion'; fi
  rm -rf hooks
else
  echo "SKIPPED (no 'claude' CLI) — section 13b live-install proofs need the CLI"
fi

echo
echo "----------------------------------------"
echo "seed-defect-proof.sh: $pass proven, $fail no-op"
[ "$fail" -eq 0 ] && exit 0 || exit 1
