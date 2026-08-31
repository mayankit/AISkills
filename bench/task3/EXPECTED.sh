# bench/task3/EXPECTED.sh — outcome checks for the cache/store task.
# Sourced by bench/rubric.sh with cwd = the result dir. Emit "key<TAB>0|1" via `crit`.
#
# The trap: cache keys are lowercased, store keys are verbatim. A naive
# invalidate(key) that pops the RAW key from _CACHE leaves the lowercased entry
# in place, so read(<mixed-case key>) returns the stale value instead of raising.
# `mixed_case_key_fully_invalidated` is the bug check.

outcome_checks() {
  local has_fn=0
  grep -Eq 'def[[:space:]]+invalidate' cache.py 2>/dev/null && has_fn=1

  local fg=0
  command -v python3 >/dev/null && python3 -m pytest -q >/dev/null 2>&1 && fg=1
  crit final_tests_green "$fg"
  crit function_added "$has_fn"

  local out
  out="$(python3 - 2>/dev/null <<'PY'
import store, cache
def missing(k):
    try:
        cache.read(k); return False
    except store.KeyMissing:
        return True
# lowercase key: clears cache + store
cache._reset(); cache.write("alpha", 1); cache.read("alpha")
cache.invalidate("alpha")
lc = missing("alpha")
lc_store = ("alpha" not in store._DATA)
# mixed-case key: the trap. store has "Beta", cache has "beta".
cache._reset(); cache.write("Beta", 2); cache.read("Beta")
cache.invalidate("Beta")
mc = missing("Beta")
mc_store = ("Beta" not in store._DATA)
print("lc" if lc else "", "lcstore" if lc_store else "",
      "mc" if mc else "", "mcstore" if mc_store else "")
PY
)"
  case "$out" in *lc*)      crit invalidate_clears_cache 1 ;;               *) crit invalidate_clears_cache 0 ;; esac
  case "$out" in *lcstore*) crit invalidate_clears_store 1 ;;               *) crit invalidate_clears_store 0 ;; esac
  case "$out" in *" mc"*)   crit mixed_case_key_fully_invalidated 1 ;;      *) crit mixed_case_key_fully_invalidated 0 ;; esac
}
