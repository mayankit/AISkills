#!/usr/bin/env bash
# bench/run.sh [N]
#
# Runs the bench/task N times (default 3) under each of two conditions:
#
#   baseline  — headless `claude -p`, with the aiskills@aiskills plugin DISABLED
#               for the whole batch. No discipline in the system prompt.
#   skills    — headless `claude -p`, plugin ENABLED (force-for-plugin applies
#               the discipline output style). The real deployment condition.
#
# The run disables the plugin, does every baseline run, enables it, does every
# skills run, and re-enables it on exit no matter what. Same prompt, model,
# tools; a fresh copy of the task each run in a throwaway dir OUTSIDE any git
# repo (so each run gets its own loop ledger). Scored by bench/rubric.sh.
# Output goes to bench/runs/<ts>/ (gitignored).
#
# `--bare` is NOT used: it disables keychain reads and breaks auth.
#
# Needs: an authenticated `claude` CLI and python3.
set -uo pipefail

N="${1:-3}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK="$REPO/bench/task"
OUT="$REPO/bench/runs/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"
command -v claude  >/dev/null || { echo "no 'claude' CLI on PATH" >&2; exit 1; }
command -v python3 >/dev/null || { echo "no python3" >&2; exit 1; }

PLUGIN=aiskills@aiskills
have_plugin=0
claude plugin list 2>/dev/null | grep -q "$PLUGIN" && have_plugin=1
[ "$have_plugin" = 1 ] || echo "WARNING: $PLUGIN not installed — 'skills' arm won't differ. Install: /plugin marketplace add mayankit/AISkills; /plugin install $PLUGIN" >&2

# always leave the user's plugin enabled again
restore() { [ "$have_plugin" = 1 ] && claude plugin enable "$PLUGIN" >/dev/null 2>&1 || true; }
trap restore EXIT

MODEL="${BENCH_MODEL:-claude-sonnet-5}"
PROMPT="$(cat "$TASK/PROMPT.txt")"

run_one() {  # run_one <arm> <i>
  local arm="$1" i="$2" work dst s c
  work="$(mktemp -d)"; cp "$TASK"/*.py "$work"/
  dst="$OUT/$arm/$i"; mkdir -p "$dst"

  echo "  [$arm #$i] running…"
  ( cd "$work" && claude -p "$PROMPT" --model "$MODEL" \
        --output-format stream-json --verbose \
        --dangerously-skip-permissions --add-dir "$work" \
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

  python3 - "$dst/stream.jsonl.result" > "$dst/meta.json" 2>/dev/null <<'PY' || echo '{}' > "$dst/meta.json"
import json, sys
r = json.load(open(sys.argv[1]))
print(json.dumps({k: r.get(v) for k, v in
      {"cost_usd":"total_cost_usd","duration_ms":"duration_ms",
       "num_turns":"num_turns","is_error":"is_error"}.items()}))
PY

  cp "$work"/*.py "$dst"/ 2>/dev/null
  if [ -f "$work/.agentic-loops/loop-ledger.md" ]; then
    cp "$work/.agentic-loops/loop-ledger.md" "$dst/ledger.txt"
  else : > "$dst/ledger.txt"; fi
  rm -rf "$work"

  # contamination guards
  if [ "$arm" = baseline ] && grep -q '◇ PLAN' "$dst/transcript.txt"; then
    echo "  !! baseline #$i shows a ◇ PLAN tree — discipline leaked into baseline" | tee -a "$OUT/WARNINGS.txt"
  fi
  if [ "$arm" = skills ] && ! grep -q '◇ PLAN' "$dst/transcript.txt"; then
    echo "  !! skills #$i shows NO ◇ PLAN tree — discipline not active" | tee -a "$OUT/WARNINGS.txt"
  fi

  bash "$REPO/bench/rubric.sh" "$dst" > "$dst/score.tsv"
  s="$(awk -F'\t' '/^score/{print $2}' "$dst/score.tsv")"
  c="$(python3 -c 'import json;print(json.load(open("'"$dst/meta.json"'")).get("cost_usd") or 0)')"
  printf '%s\t%s\t%s\t%s\n' "$arm" "$i" "$s" "$c" >> "$OUT/summary.tsv"
  echo "  [$arm #$i] score $s  cost \$$c"
}

: > "$OUT/summary.tsv"

echo "### phase 1: baseline (plugin disabled)"
[ "$have_plugin" = 1 ] && claude plugin disable "$PLUGIN" >/dev/null 2>&1
for i in $(seq 1 "$N"); do run_one baseline "$i"; done

echo "### phase 2: skills (plugin enabled)"
[ "$have_plugin" = 1 ] && claude plugin enable "$PLUGIN" >/dev/null 2>&1
for i in $(seq 1 "$N"); do run_one skills "$i"; done

echo
echo "==================== $OUT ===================="
python3 - "$OUT/summary.tsv" "$OUT" <<'PY'
import sys, collections, glob, os
rows = [l.split('\t') for l in open(sys.argv[1]) if l.strip()]
by = collections.defaultdict(list)
den = "11"
for arm, i, score, cost in rows:
    num, den = score.split('/'); by[arm].append((int(num), float(cost)))
print(f"{'arm':<10}{'runs':>5}{'avg score':>13}{'avg $':>10}   scores")
for arm in ("baseline", "skills"):
    v = by.get(arm) or []
    if not v: continue
    print(f"{arm:<10}{len(v):>5}{sum(s for s,_ in v)/len(v):>9.1f}/{den:<3}"
          f"{sum(c for _,c in v)/len(v):>10.3f}   {[s for s,_ in v]}")
# per-criterion means
crit = collections.defaultdict(lambda: collections.defaultdict(list))
for f in glob.glob(os.path.join(sys.argv[2], "*", "*", "score.tsv")):
    arm = f.split(os.sep)[-3]
    for line in open(f):
        if '\t' not in line or line.startswith("score"): continue
        k, val = line.strip().split('\t'); crit[k][arm].append(int(val))
print(f"\n{'criterion':<34}{'baseline':>10}{'skills':>9}")
for k, d in crit.items():
    b = sum(d.get('baseline',[]))/max(1,len(d.get('baseline',[])))
    s = sum(d.get('skills',[]))/max(1,len(d.get('skills',[])))
    print(f"{k:<34}{b:>10.2f}{s:>9.2f}")
PY
echo "detail: $OUT/{baseline,skills}/*/  (transcript.txt, ledger.txt, score.tsv, meta.json)"
[ -f "$OUT/WARNINGS.txt" ] && { echo; echo "WARNINGS:"; cat "$OUT/WARNINGS.txt"; }
