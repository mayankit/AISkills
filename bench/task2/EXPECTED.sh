# bench/task2/EXPECTED.sh — task-specific outcome checks for the orders task.
# Sourced by bench/rubric.sh with cwd = the result dir. Emit "key<TAB>0|1" via `crit`.
#
# The trap: a quick `{o["customer_id"]: o for o in orders}` keeps the LAST order
# in list order, not the one with the highest ts. `selects_by_max_ts` is the bug
# check — baseline is expected to fail it some of the time.

outcome_checks() {
  local has_fn=0
  grep -Eq 'def[[:space:]]+latest_per_customer' orders.py 2>/dev/null && has_fn=1

  local fg=0
  command -v python3 >/dev/null && python3 -m pytest -q >/dev/null 2>&1 && fg=1
  crit final_tests_green "$fg"
  crit function_added "$has_fn"

  # run from cwd (the result dir) via stdin so `import orders` resolves
  local out
  out="$(python3 - 2>/dev/null <<'PY'
import sys
try:
    from orders import latest_per_customer as L
except Exception:
    print("noimport"); sys.exit()
def ids(rows): return sorted((r["customer_id"], r["ts"]) for r in rows)
a = L([{"customer_id":1,"name":"A","ts":50,"amount":1},
       {"customer_id":1,"name":"A","ts":20,"amount":2}])
maxts = (len(a)==1 and a[0]["ts"]==50)
b = L([{"customer_id":1,"name":"Sam","ts":5,"amount":1},
       {"customer_id":2,"name":"Sam","ts":7,"amount":1},
       {"customer_id":1,"name":"Sam","ts":9,"amount":1}])
per_customer = (ids(b) == [(1,9),(2,7)])
try:    empt = (L([]) == [])
except Exception: empt = False
print("maxts" if maxts else "", "percust" if per_customer else "", "empty" if empt else "")
PY
)"
  case "$out" in *maxts*)   crit selects_by_max_ts_not_list_order 1 ;; *) crit selects_by_max_ts_not_list_order 0 ;; esac
  case "$out" in *percust*) crit one_row_per_distinct_customer 1 ;;    *) crit one_row_per_distinct_customer 0 ;; esac
  case "$out" in *empty*)   crit handles_empty_input 1 ;;              *) crit handles_empty_input 0 ;; esac
}
