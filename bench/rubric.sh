#!/usr/bin/env bash
# bench/rubric.sh <result-dir>
#
# Scores ONE completed run against objective, mechanically-checkable criteria.
# <result-dir> must contain, after the run:
#   *.py            the task files as the model left them
#   transcript.txt  the model's assistant-text output, in order
#   stream.jsonl    the full stream-json event log (tool calls included)
#   ledger.txt      any loop-ledger.md the run produced (may be empty)
#
# Prints one "key<TAB>0|1" line per criterion, then "score<TAB>N/11".
# Exit 0 always (scoring is not pass/fail).
set -u
d="${1:?usage: rubric.sh <result-dir>}"
cd "$d" || exit 1
T=transcript.txt; [ -f "$T" ] || : > "$T"
L=ledger.txt;     [ -f "$L" ] || : > "$L"
S=stream.jsonl;   [ -f "$S" ] || : > "$S"
DISC="$(cat "$T" "$L" 2>/dev/null)"                 # discipline signals: text + ledger
TESTS="$(cat test_*.py 2>/dev/null)"                # every test file, combined

score=0
crit() { printf '%s\t%s\n' "$1" "$2"; [ "$2" = 1 ] && score=$((score+1)); }
has()  { printf '%s' "$1" | grep -Eiq -- "$2"; }

# --- outcome: the change is correct --------------------------------------
final_green=0
if command -v python3 >/dev/null 2>&1; then
  python3 -m pytest -q >/tmp/bench_pytest.$$ 2>&1 && final_green=1
  rm -f /tmp/bench_pytest.$$
fi
crit final_tests_green "$final_green"

fn_body="$(awk '/def[[:space:]]+total_with_tax/{f=1} f&&/^def /&&!/total_with_tax/{f=0} f' pricing.py 2>/dev/null)"
[ -n "$fn_body" ] && crit function_added 1 || crit function_added 0

ve=0
grep -q 'raise ValueError' pricing.py 2>/dev/null && has "$TESTS" 'ValueError|raises\(' && ve=1
crit unknown_region_guarded_and_tested "$ve"

# trap A — reuse _round_money, don't re-derive money rounding in the new fn
reuse_round=0
if [ -n "$fn_body" ]; then
  printf '%s' "$fn_body" | grep -q '_round_money' \
    && ! printf '%s' "$fn_body" | grep -Eq 'round\(|Decimal\(|quantize|%\.2f|f".*:\.2f' \
    && reuse_round=1
fi
crit reuses_round_money_helper "$reuse_round"

# trap B — reference TAX_RATES in the new fn, no fresh rate literals
reuse_rates=0
if [ -n "$fn_body" ]; then
  printf '%s' "$fn_body" | grep -q 'TAX_RATES' \
    && ! printf '%s' "$fn_body" | grep -Eq '0\.08|0\.20?|0\.12|\b8\b.*%|1\.08|1\.20|1\.12' \
    && reuse_rates=1
fi
crit reuses_tax_rates_table "$reuse_rates"

# --- process: a failing test for the new behaviour came first ----------
# from stream.jsonl: order of (a) first tool_use writing a test file mentioning
# total_with_tax, (b) first tool_use editing pricing.py, (c) a pytest run whose
# result shows a failure/error.
test_first=0
python3 - "$S" <<'PY' && test_first=1
import json, sys
evs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
tu = []   # (idx, name, text-ish)
for i, e in enumerate(evs):
    if e.get("type") != "assistant": continue
    for b in e.get("message", {}).get("content", []):
        if b.get("type") == "tool_use":
            tu.append((i, b.get("name",""), json.dumps(b.get("input",{}))))
def first(pred):
    for idx, name, inp in tu:
        if pred(name, inp): return idx
    return 10**9
test_write = first(lambda n,i: n in ("Write","Edit","MultiEdit") and "test" in i.lower() and "total_with_tax" in i)
impl_write = first(lambda n,i: n in ("Write","Edit","MultiEdit") and "pricing.py" in i and "total_with_tax" in i)
# a failing pytest observed anywhere before impl_write
fail_before = False
for i, e in enumerate(evs):
    if e.get("type") != "user": continue
    for b in e.get("message", {}).get("content", []):
        if not (isinstance(b, dict) and b.get("type") == "tool_result"): continue
        c = b.get("content","")
        if isinstance(c, list): c = " ".join(x.get("text","") for x in c if isinstance(x,dict))
        c = str(c)
        if any(k in c for k in ("failed","FAILED","Error","error","assert")) and i < impl_write:
            fail_before = True
sys.exit(0 if (test_write < impl_write and fail_before) else 1)
PY
crit test_written_and_failed_first "$test_first"

gate=0; has "$DISC$(cat "$S")" 'pytest|python -m pytest|unittest' && gate=1
crit real_gate_executed "$gate"

# --- process: the loop discipline is visibly running -------------------
has "$DISC" '◇ PLAN'                         && crit plan_tree_emitted 1        || crit plan_tree_emitted 0

# real ◆ status lines. Ledger lines carry an ISO-timestamp prefix, so match ◆
# anywhere on the line, immediately followed by a loop level or STOP.
statusN="$( { cat "$L"; grep -hE '^◆ (L[0-9]|STOP)' "$T" 2>/dev/null; } | grep -cE '◆ (L[0-9]|STOP)' )"
[ "$statusN" -ge 3 ] && crit status_lines_ge3 1 || crit status_lines_ge3 0

# heartbeat: distinct "iter N" on real status lines in the ledger
iters="$(grep -hoE 'iter [0-9]+' "$L" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
[ "$iters" -ge 3 ] && crit heartbeat_ge3_distinct_iters 1 || crit heartbeat_ge3_distinct_iters 0

[ -s "$L" ] && grep -q '◆' "$L" && crit ledger_file_written 1 || crit ledger_file_written 0

echo
printf 'score\t%s/11\n' "$score"
