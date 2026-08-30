# bench/task/EXPECTED.sh — task-specific outcome checks for the pricing task.
# Sourced by bench/rubric.sh with cwd = the result dir. Emit "key<TAB>0|1" via `crit`.

outcome_checks() {
  local fn_body
  fn_body="$(awk '/def[[:space:]]+total_with_tax/{f=1} f&&/^def /&&!/total_with_tax/{f=0} f' pricing.py 2>/dev/null)"

  local fg=0
  command -v python3 >/dev/null && python3 -m pytest -q >/dev/null 2>&1 && fg=1
  crit final_tests_green "$fg"

  [ -n "$fn_body" ] && crit function_added 1 || crit function_added 0

  local ve=0
  grep -q 'raise ValueError' pricing.py 2>/dev/null \
    && printf '%s' "$TESTS" | grep -Eq 'ValueError|raises\(' && ve=1
  crit unknown_region_guarded_and_tested "$ve"

  # trap A — reuse _round_money, no second rounding mechanism in the new fn
  local ra=0
  if [ -n "$fn_body" ]; then
    printf '%s' "$fn_body" | grep -q '_round_money' \
      && ! printf '%s' "$fn_body" | grep -Eq 'round\(|Decimal\(|quantize|:\.2f' && ra=1
  fi
  crit reuses_round_money_helper "$ra"

  # trap B — reference TAX_RATES, no fresh rate literals in the new fn
  local rt=0
  if [ -n "$fn_body" ]; then
    printf '%s' "$fn_body" | grep -q 'TAX_RATES' \
      && ! printf '%s' "$fn_body" | grep -Eq '0\.08|0\.20?|0\.12|1\.08|1\.20|1\.12' && rt=1
  fi
  crit reuses_tax_rates_table "$rt"
}
