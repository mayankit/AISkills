#!/usr/bin/env bash
# bench/rubric.sh <result-dir>
#
# Scores ONE completed run. <result-dir> must contain, after the run:
#   *.py            the task files as the model left them
#   EXPECTED.sh     the task's outcome checks (copied in by run.sh)
#   transcript.txt  the model's assistant-text output, in order
#   stream.jsonl    the full stream-json event log (tool calls included)
#   ledger.txt      any loop-ledger.md the run produced (may be empty)
#
# Prints "key<TAB>0|1" per criterion (task outcome checks first, then the shared
# process checks) and finally "score<TAB>N/M". Exit 0 always.
set -u
d="${1:?usage: rubric.sh <result-dir>}"
cd "$d" || exit 1
T=transcript.txt; [ -f "$T" ] || : > "$T"
L=ledger.txt;     [ -f "$L" ] || : > "$L"
S=stream.jsonl;   [ -f "$S" ] || : > "$S"
DISC="$(cat "$T" "$L" 2>/dev/null)"
TESTS="$(cat test_*.py 2>/dev/null)"

score=0; total=0
crit() { printf '%s\t%s\n' "$1" "$2"; total=$((total+1)); [ "$2" = 1 ] && score=$((score+1)); }
has()  { printf '%s' "$1" | grep -Eiq -- "$2"; }

# ---- task-specific outcome checks ----
if [ -f EXPECTED.sh ]; then . ./EXPECTED.sh; outcome_checks
else crit EXPECTED_sh_present 0; fi

# ---- shared process checks ----------------------------------------------

# a failing test for the NEW behaviour came first: from stream.jsonl, the first
# write to a test_*.py file precedes the first write to the impl module, and a
# pytest FAILURE is observed strictly between them.
test_first=0
python3 - "$S" <<'PY' && test_first=1
import json, sys, os, re
evs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
WRITE = ("Write","Edit","MultiEdit","NotebookEdit")
BIG = 10**9
def tus():
    for i,e in enumerate(evs):
        if e.get("type")!="assistant": continue
        for b in e.get("message",{}).get("content",[]):
            if b.get("type")=="tool_use": yield i,b.get("name",""),b.get("input",{}) or {}
tw = iw = BIG
for i,name,inp in tus():
    if name not in WRITE: continue
    fp = inp.get("file_path") or inp.get("path") or ""
    bn = os.path.basename(fp); blob = json.dumps(inp)
    if bn.startswith("test_") and bn.endswith(".py") and i < tw: tw = i
    if bn.endswith(".py") and not bn.startswith("test_") and i < iw: iw = i
FAIL = re.compile(r"ERROR collecting|errors? during collection|=+ (ERRORS?|FAILURES?) =+|"
                  r"ImportError|NameError|AttributeError|\b\d+ failed\b|\b\d+ error\b|"
                  r"short test summary info", re.I)
fb = False
for i,e in enumerate(evs):
    if e.get("type")!="user" or not (tw < i < iw): continue
    for b in e.get("message",{}).get("content",[]):
        if isinstance(b,dict) and b.get("type")=="tool_result":
            c=b.get("content","")
            if isinstance(c,list): c=" ".join(x.get("text","") for x in c if isinstance(x,dict))
            if FAIL.search(str(c)): fb=True
sys.exit(0 if (tw < iw and fb) else 1)
PY
crit test_written_and_failed_first "$test_first"

has "$DISC$(cat "$S")" 'pytest|python -m pytest|unittest' && crit real_gate_executed 1 || crit real_gate_executed 0
has "$DISC" '◇ PLAN' && crit plan_tree_emitted 1 || crit plan_tree_emitted 0

statusN="$( { cat "$L"; grep -hE '^◆ (L[0-9]|STOP)' "$T" 2>/dev/null; } | grep -cE '◆ (L[0-9]|STOP)' )"
[ "$statusN" -ge 3 ] && crit status_lines_ge3 1 || crit status_lines_ge3 0

# ledger written INCREMENTALLY: >= 2 distinct timestamps AND >= 2 distinct "iter N"
tstamps="$(grep -hoE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z' "$L" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
iters="$(grep -hoE 'iter [0-9]+' "$L" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
{ [ "$tstamps" -ge 2 ] && [ "$iters" -ge 2 ]; } && crit ledger_incremental 1 || crit ledger_incremental 0

{ [ -s "$L" ] && grep -q '◆' "$L"; } && crit ledger_file_written 1 || crit ledger_file_written 0

echo
printf 'score\t%s/%s\n' "$score" "$total"
