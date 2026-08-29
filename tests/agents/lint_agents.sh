#!/usr/bin/env bash
# tests/agents/lint_agents.sh — deterministic, no-API compliance tests for the 4 agent specs.
#
# These are static checks on the prompt text itself: does each agent.md actually
# commit to the behaviors its description promises? This catches spec drift
# (e.g. someone edits aiskills-code-reviewer.md and quietly drops "writes no code")
# without needing to call a model.
#
# Exit 0 = every agent passed every one of its required assertions.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail=0
pass=0
say_pass() { pass=$((pass+1)); echo "PASS: $1"; }
say_fail() { fail=$((fail+1)); echo "FAIL: $1"; }

require() {
  # require <file> <pattern> <description>
  local f="$1" pat="$2" desc="$3"
  if [ ! -f "$f" ]; then say_fail "$f missing entirely — cannot check: $desc"; return; fi
  if grep -qiE "$pat" "$f"; then
    say_pass "$f: $desc"
  else
    say_fail "$f: $desc (pattern not found: $pat)"
  fi
}

forbid() {
  # forbid <file> <pattern> <description>
  local f="$1" pat="$2" desc="$3"
  if [ ! -f "$f" ]; then say_fail "$f missing entirely — cannot check: $desc"; return; fi
  if grep -qiE "$pat" "$f"; then
    say_fail "$f: $desc (forbidden pattern present: $pat)"
  else
    say_pass "$f: $desc"
  fi
}

echo "== aiskills-builder-dev =="
F=agents/aiskills-builder-dev.md
require "$F" 'aiskills-build-discipline'                          "loads aiskills-build-discipline (the TDD spine)"
require "$F" 'PLAN'                                       "commits to emitting a PLAN tree"
require "$F" 'currently-failing test|failing test'        "commits to the named-failing-test coding gate"
require "$F" 'RED'                                        "names the RED phase"
require "$F" 'GREEN'                                       "names the GREEN phase"
require "$F" 'REFACTOR'                                    "names the REFACTOR phase"
require "$F" 'VERIFY'                                       "names the VERIFY phase"
require "$F" 'two-strike'                                   "commits to the two-strike rule"

echo
echo "== aiskills-code-reviewer =="
F=agents/aiskills-code-reviewer.md
require "$F" 'writes NO code|writes no code'                "explicitly commits to writing no code"
require "$F" 'Blocker'                                       "defines a Blocker severity"
require "$F" 'Major'                                          "defines a Major severity"
require "$F" 'Minor'                                           "defines a Minor severity"
require "$F" 'security'                                         "covers the security dimension"
require "$F" 'correctness'                                       "covers the correctness dimension"
require "$F" 'file[s]?/line|file/line'                             "commits to file/line-anchored findings"
forbid  "$F" 'you (may|should|can) (edit|modify|write) (the )?(file|code|implementation)' "does not authorize editing files from inside a review"

echo
echo "== aiskills-incident-investigator =="
F=agents/aiskills-incident-investigator.md
require "$F" 'Mitigate first|mitigate first'                  "commits to the mitigate-first doctrine"
require "$F" 'blast radius'                                     "commits to scoping the blast radius"
require "$F" 'root.?cause'                                        "commits to root-cause analysis"
require "$F" 'human (gate|confirmation)'                            "requires human confirmation for risky actions"
require "$F" 'blameless'                                             "commits to a blameless post-incident review"
require "$F" 'guard'                                                  "commits to leaving a guard (test/alarm) against recurrence"

echo
echo "== aiskills-architect =="
F=agents/aiskills-architect.md
require "$F" 'ADR'                                                     "commits to recording ADRs"
require "$F" 'decisions, contracts'                                      "states its deliverables are decisions/contracts"
require "$F" 'never build|do not build|you do not build'                  "explicitly commits to not building"
require "$F" 'YAGNI|rule of three'                                          "references YAGNI / rule-of-three restraint"
require "$F" 'existing convention'                                            "weighs existing convention"
forbid  "$F" 'implement the feature|write the implementation'                    "does not instruct itself to implement features"

echo
echo "== all agents: shared contract =="
for f in agents/*.md; do
  require "$f" 'loop-contract\.md'    "$(basename "$f"): defers to brain/loop-contract.md"
  require "$f" 'aiskills-agentic-loops'        "$(basename "$f"): loads aiskills-agentic-loops as a first action"
done

echo
echo "----------------------------------------"
echo "lint_agents.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
