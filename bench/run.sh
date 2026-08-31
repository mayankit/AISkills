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
TASKS=("$@"); [ ${#TASKS[@]} -eq 0 ] && TASKS=("$REPO/bench/task" "$REPO/bench/task2" "$REPO/bench/task3")
# RESUME=<dir> continues a run that aborted (skips runs that already have a
# non-error score); otherwise a fresh timestamped dir.
OUT="${RESUME:-$REPO/bench/runs/$(date -u +%Y%m%dT%H%M%SZ)}"
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
  dst="$OUT/$tname/$arm/$i"
  if [ -f "$dst/score.tsv" ] && ! grep -q '"is_error": *true' "$dst/meta.json" 2>/dev/null; then
    echo "  [$tname/$arm #$i] already done — skip"; return 0
  fi
  work="$(mktemp -d)"; cp "$tdir"/*.py "$work"/
  mkdir -p "$dst"
  cp "$tdir/EXPECTED.sh" "$dst/EXPECTED.sh"

  local -a extra=()
  [ "$arm" = skills ] && extra=( --append-system-prompt "$STYLE_BODY" --plugin-dir "$REPO" )

  echo "  [$tname/$arm #$i] running…"
  ( cd "$work" && claude -p "$(cat "$tdir/PROMPT.txt")" --model "$MODEL" \
        --output-format stream-json --verbose \
        --dangerously-skip-permissions --add-dir "$work" \
        ${extra[@]+"${extra[@]}"} </dev/null \
  ) > "$dst/stream.jsonl" 2> "$dst/stderr.txt" || true

  # abort the whole run if the account hit its usage limit — otherwise every
  # remaining run records a bogus 0-token error row.
  if grep -q '"rateLimitType"\|hit your monthly spend limit\|"error":"rate_limit"' "$dst/stream.jsonl"; then
    echo "  !! rate limit hit — aborting the run. Re-run after it resets." | tee -a "$OUT/WARNINGS.txt"
    rm -rf "$work"; return 3
  fi

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
  local err cost
  read -r err cost < <(python3 -c 'import json;d=json.load(open("'"$dst/meta.json"'"));print(int(bool(d.get("is_error"))), d.get("cost_usd") or 0)')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$tname" "$arm" "$i" "$s" "$cost" "$err" >> "$OUT/summary.tsv"
  echo "  [$tname/$arm #$i] $s  \$$cost$([ "$err" = 1 ] && echo '  (ERROR)')"
}

: > "$OUT/summary.tsv"
PACE="${BENCH_PACE:-20}"   # seconds between runs — headless coding runs are token-heavy
abort=0
for tdir in "${TASKS[@]}"; do
  [ "$abort" = 1 ] && break
  tname="$(basename "$tdir")"
  echo "### $tname — phase 1: baseline (plugin disabled)"
  [ "$have_plugin" = 1 ] && claude plugin disable "$PLUGIN" >/dev/null 2>&1
  for i in $(seq 1 "$N"); do
    run_one "$tdir" "$tname" baseline "$i" || { [ $? = 3 ] && abort=1 && break; }
    sleep "$PACE"
  done
  [ "$abort" = 1 ] && break
  echo "### $tname — phase 2: skills (plugin enabled + discipline appended)"
  [ "$have_plugin" = 1 ] && claude plugin enable "$PLUGIN" >/dev/null 2>&1
  for i in $(seq 1 "$N"); do
    run_one "$tdir" "$tname" skills "$i" || { [ $? = 3 ] && abort=1 && break; }
    sleep "$PACE"
  done
done
[ "$abort" = 1 ] && echo "RUN ABORTED (rate limit) — partial results below; re-run when the limit resets."

echo
echo "==================== $OUT ===================="
python3 - "$OUT/summary.tsv" "$OUT" <<'PY'
import sys, collections, glob, os, json
rows = [l.rstrip("\n").split('\t') for l in open(sys.argv[1]) if l.strip()]
# columns: task arm i score cost is_error   (is_error may be absent in old files)
ok = collections.defaultdict(list); errs = collections.Counter()
for r in rows:
    tname, arm, i, score = r[:4]
    cost = float(r[4]) if len(r) > 4 else 0.0
    is_err = (len(r) > 5 and r[5] == "1")
    n, m = score.split('/')
    if is_err: errs[(tname, arm)] += 1
    else:      ok[(tname, arm)].append((int(n), int(m), cost, os.path.join(sys.argv[2], tname, arm, i)))
tasks = sorted({t for t, _ in ok} | {t for t, _ in errs})
print(f"{'task':<8}{'arm':<10}{'ok':>4}{'err':>5}{'avg score':>12}{'avg $':>9}   scores")
for t in tasks:
    for arm in ("baseline", "skills"):
        v = ok.get((t, arm)) or []; e = errs.get((t, arm), 0)
        if not v and not e: continue
        if v:
            m = v[0][1]
            print(f"{t:<8}{arm:<10}{len(v):>4}{e:>5}{sum(n for n,*_ in v)/len(v):>8.2f}/{m:<3}"
                  f"{sum(c for _,_,c,_ in v)/len(v):>9.3f}   {[n for n,*_ in v]}")
        else:
            print(f"{t:<8}{arm:<10}{0:>4}{e:>5}{'--':>12}{'--':>9}   (all errored)")
# per-criterion means over OK runs only
crit = collections.defaultdict(lambda: collections.defaultdict(list))
for (t, arm), v in ok.items():
    for *_ , dpath in v:
        sp = os.path.join(dpath, "score.tsv")
        if not os.path.exists(sp): continue
        for line in open(sp):
            if '\t' not in line or line.startswith("score"): continue
            k, val = line.strip().split('\t'); crit[(t, k)][arm].append(int(val))
last_t = None
for (t, k), d in crit.items():
    if t != last_t:
        print(f"\n[{t}] {'criterion':<34}{'baseline':>10}{'skills':>9}"); last_t = t
    b = d.get('baseline'); s = d.get('skills')
    bs = f"{sum(b)/len(b):.2f}" if b else "--"; ss = f"{sum(s)/len(s):.2f}" if s else "--"
    print(f"        {k:<34}{bs:>10}{ss:>9}")
def avg(t, arm, key):
    xs = []
    for _,_,_,dp in ok.get((t, arm), []):
        try: xs.append(json.load(open(os.path.join(dp, "meta.json"))).get(key) or 0)
        except Exception: pass
    return sum(xs)/len(xs) if xs else 0
print()
for t in tasks:
    for key, lbl in (("cost_usd","$"), ("duration_ms","ms"), ("num_turns","turns")):
        print(f"[{t}] avg {lbl:<6} baseline {avg(t,'baseline',key):>10.2f}   skills {avg(t,'skills',key):>10.2f}")
PY
[ -f "$OUT/WARNINGS.txt" ] && { echo; echo "WARNINGS:"; cat "$OUT/WARNINGS.txt"; }
