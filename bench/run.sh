#!/usr/bin/env bash
# bench/run.sh [N] [task-dir ...]
#
# For each task, run it N times (default 5) under two conditions:
#
#   baseline  — headless `claude -p`, aiskills@aiskills plugin DISABLED, nothing
#               added to the system prompt.
#   skills    — headless `claude -p`, plugin ENABLED, PLUS the discipline output
#               style appended to the system prompt (--append-system-prompt) and
#               --plugin-dir <repo> so the 16 skills are loadable. The discipline
#               is applied deterministically — not left to force-for-plugin,
#               which was not 100% reliable in headless.
#
# Same prompt, model, tools; a fresh copy of the task each run in a throwaway
# dir OUTSIDE any git repo (its own loop ledger). Scored by bench/rubric.sh.
# Output -> bench/runs/<ts>/<task>/<arm>/<i>/ (gitignored).
#
# `--bare` is NOT used (it disables keychain reads and breaks auth).
# Needs: an authenticated `claude` CLI and python3.
set -uo pipefail

N="${1:-5}"; shift || true
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS=("$@"); [ ${#TASKS[@]} -eq 0 ] && TASKS=("$REPO/bench/task" "$REPO/bench/task2")
OUT="$REPO/bench/runs/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"
command -v claude  >/dev/null || { echo "no 'claude' CLI on PATH" >&2; exit 1; }
command -v python3 >/dev/null || { echo "no python3" >&2; exit 1; }

PLUGIN=aiskills@aiskills
have_plugin=0
claude plugin list 2>/dev/null | grep -q "$PLUGIN" && have_plugin=1
restore() { [ "$have_plugin" = 1 ] && claude plugin enable "$PLUGIN" >/dev/null 2>&1 || true; }
trap restore EXIT

MODEL="${BENCH_MODEL:-claude-sonnet-5}"
# discipline text a real install puts in the system prompt (drop frontmatter +
# the install comment; keep the body)
STYLE_BODY="$(awk '/^-->$/{c=1;next} c' "$REPO/output-styles/loops-within-loops.md")"

run_one() {  # run_one <taskdir> <taskname> <arm> <i>
  local tdir="$1" tname="$2" arm="$3" i="$4" work dst s c
  work="$(mktemp -d)"; cp "$tdir"/*.py "$work"/
  dst="$OUT/$tname/$arm/$i"; mkdir -p "$dst"
  cp "$tdir/EXPECTED.sh" "$dst/EXPECTED.sh"

  local -a extra=()
  [ "$arm" = skills ] && extra=( --append-system-prompt "$STYLE_BODY" --plugin-dir "$REPO" )

  echo "  [$tname/$arm #$i] running…"
  ( cd "$work" && claude -p "$(cat "$tdir/PROMPT.txt")" --model "$MODEL" \
        --output-format stream-json --verbose \
        --dangerously-skip-permissions --add-dir "$work" \
        ${extra[@]+"${extra[@]}"} \
  ) > "$dst/stream.jsonl" 2> "$dst/stderr.txt" || true

  python3 - "$dst/stream.jsonl" > "$dst/transcript.txt" <<'PY'
import json, sys
for line in open(sys.argv[1], errors="replace"):
    line = line.strip()
    if not line: continue
    try: ev = json.loads(line)
    except Exception: continue
    if ev.get("type") == "assistant":
        for b in ev.get("message", {}).get("content", []):
            if b.get("type") == "text": print(b["text"])
    elif ev.get("type") == "result":
        json.dump(ev, open(sys.argv[1] + ".result", "w"))
PY
  python3 - "$dst/stream.jsonl.result" <<'PY' > "$dst/meta.json" 2>/dev/null
import json, sys
r = json.load(open(sys.argv[1]))
print(json.dumps({k: r.get(v) for k, v in
      {"cost_usd":"total_cost_usd","duration_ms":"duration_ms",
       "num_turns":"num_turns","is_error":"is_error"}.items()}))
PY
  [ -s "$dst/meta.json" ] || echo '{}' > "$dst/meta.json"

  cp "$work"/*.py "$dst"/ 2>/dev/null
  [ -f "$work/.agentic-loops/loop-ledger.md" ] && cp "$work/.agentic-loops/loop-ledger.md" "$dst/ledger.txt" || : > "$dst/ledger.txt"
  rm -rf "$work"

  if [ "$arm" = baseline ] && grep -q '◇ PLAN' "$dst/transcript.txt"; then
    echo "  !! $tname baseline #$i shows a ◇ PLAN tree — discipline leaked" | tee -a "$OUT/WARNINGS.txt"
  fi
  if [ "$arm" = skills ] && ! grep -q '◇ PLAN' "$dst/transcript.txt"; then
    echo "  !! $tname skills #$i shows NO ◇ PLAN tree — discipline present in prompt but not followed" | tee -a "$OUT/WARNINGS.txt"
  fi

  bash "$REPO/bench/rubric.sh" "$dst" > "$dst/score.tsv"
  s="$(awk -F'\t' '/^score/{print $2}' "$dst/score.tsv")"
  c="$(python3 -c 'import json;print(json.load(open("'"$dst/meta.json"'")).get("cost_usd") or 0)')"
  printf '%s\t%s\t%s\t%s\t%s\n' "$tname" "$arm" "$i" "$s" "$c" >> "$OUT/summary.tsv"
  echo "  [$tname/$arm #$i] $s  \$$c"
}

: > "$OUT/summary.tsv"
for tdir in "${TASKS[@]}"; do
  tname="$(basename "$tdir")"
  echo "### $tname — phase 1: baseline (plugin disabled)"
  [ "$have_plugin" = 1 ] && claude plugin disable "$PLUGIN" >/dev/null 2>&1
  for i in $(seq 1 "$N"); do run_one "$tdir" "$tname" baseline "$i"; done
  echo "### $tname — phase 2: skills (plugin enabled + discipline appended)"
  [ "$have_plugin" = 1 ] && claude plugin enable "$PLUGIN" >/dev/null 2>&1
  for i in $(seq 1 "$N"); do run_one "$tdir" "$tname" skills "$i"; done
done

echo
echo "==================== $OUT ===================="
python3 - "$OUT/summary.tsv" "$OUT" <<'PY'
import sys, collections, glob, os, json
rows = [l.rstrip("\n").split('\t') for l in open(sys.argv[1]) if l.strip()]
agg = collections.defaultdict(list)
for tname, arm, i, score, cost in rows:
    n, m = score.split('/'); agg[(tname, arm)].append((int(n), int(m), float(cost)))
tasks = sorted({t for t, _ in agg})
print(f"{'task':<10}{'arm':<10}{'runs':>5}{'avg score':>13}{'avg $':>9}   scores")
for t in tasks:
    for arm in ("baseline", "skills"):
        v = agg.get((t, arm)) or []
        if not v: continue
        m = v[0][1]
        print(f"{t:<10}{arm:<10}{len(v):>5}{sum(n for n,_,_ in v)/len(v):>9.2f}/{m:<3}"
              f"{sum(c for *_,c in v)/len(v):>9.3f}   {[n for n,_,_ in v]}")
# per-criterion means, per task
crit = collections.defaultdict(lambda: collections.defaultdict(list))
for f in glob.glob(os.path.join(sys.argv[2], "*", "*", "*", "score.tsv")):
    parts = f.split(os.sep); tname, arm = parts[-4], parts[-3]
    for line in open(f):
        if '\t' not in line or line.startswith("score"): continue
        k, val = line.strip().split('\t'); crit[(tname, k)][arm].append(int(val))
last_t = None
for (tname, k), d in crit.items():
    if tname != last_t:
        print(f"\n[{tname}] {'criterion':<34}{'baseline':>10}{'skills':>9}"); last_t = tname
    b = d.get('baseline', [0]); s = d.get('skills', [0])
    print(f"         {k:<34}{sum(b)/len(b):>10.2f}{sum(s)/len(s):>9.2f}")
# cost/time
def avg(t, arm, key):
    xs = [json.load(open(f)).get(key) or 0
          for f in glob.glob(os.path.join(sys.argv[2], t, arm, "*", "meta.json"))]
    return sum(xs)/len(xs) if xs else 0
print()
for t in tasks:
    for key, lbl in (("cost_usd","$"), ("duration_ms","ms"), ("num_turns","turns")):
        print(f"[{t}] avg {lbl:<6} baseline {avg(t,'baseline',key):>10.3f}   skills {avg(t,'skills',key):>10.3f}")
PY
[ -f "$OUT/WARNINGS.txt" ] && { echo; echo "WARNINGS:"; cat "$OUT/WARNINGS.txt"; }
