# Benchmark results

Run `20260831T014254Z` — `claude-sonnet-5`, headless `claude -p`, `skills` arm =
plugin enabled + discipline appended to the system prompt (v0.5.0). N=3.
`task3` did not run — the account hit its 5-hour usage limit on `task2/skills #3`
(guard aborted cleanly). Continue it with:

```
RESUME=bench/runs/20260831T014254Z bash bench/run.sh 3
```

## Headline

| task | arm | runs | avg score | scores | avg cost | avg time |
|---|---|---|---|---|---|---|
| task  | baseline | 3 | **5.67 / 11** | 5, 6, 6 | $0.085 | ~28 s |
| task  | skills   | 3 | **11.00 / 11** | 11, 11, 11 | $0.233 | ~75 s |
| task2 | baseline | 3 | **6.00 / 11** | 6, 6, 6 | $0.066 | ~22 s |
| task2 | skills   | 2 | **11.00 / 11** | 11, 11 | $0.188 | ~70 s |

**Every completed `skills` run scored a perfect 11/11 across two different
tasks.** `baseline` sat at 5–6/11, consistently.

## Per criterion

### task (pricing)

| criterion | baseline | skills |
|---|---|---|
| final_tests_green | 1.00 | 1.00 |
| function_added | 1.00 | 1.00 |
| unknown_region_guarded_and_tested | 0.67 | **1.00** |
| reuses_round_money_helper | 1.00 | 1.00 |
| reuses_tax_rates_table | 1.00 | 1.00 |
| test_written_and_failed_first | **0.00** | **1.00** |
| real_gate_executed | 1.00 | 1.00 |
| plan_tree_emitted | 0.00 | **1.00** |
| status_lines_ge3 | 0.00 | **1.00** |
| ledger_incremental | 0.00 | **1.00** |
| ledger_file_written | 0.00 | **1.00** |

### task2 (latest_per_customer)

| criterion | baseline | skills |
|---|---|---|
| final_tests_green | 1.00 | 1.00 |
| function_added | 1.00 | 1.00 |
| selects_by_max_ts_not_list_order *(the trap)* | **1.00** | 1.00 |
| one_row_per_distinct_customer | 1.00 | 1.00 |
| handles_empty_input | 1.00 | 1.00 |
| test_written_and_failed_first | **0.00** | **1.00** |
| real_gate_executed | 1.00 | 1.00 |
| plan_tree_emitted / status_lines / ledger_incremental / ledger_file | 0.00 | **1.00** |

## What this run tells us

1. **The discipline is now reliably followed.** The mid-session tightening
   (v0.4.0 "write the ledger incrementally", v0.5.0 `/loop` + "right-size the
   ceremony") moved the adherence criteria from the first run's
   `plan_tree_emitted` 0.67 / `ledger_incremental` 0.33 to **1.00 / 1.00** on
   every one of 5 skills runs. Small N, one model, headless — but a clear move.

2. **`baseline`'s shortfall is entirely process, not correctness.** On both
   tasks the baseline's *code was functionally correct every time* — it even
   avoided task2's max-ts trap on all 3 runs. What it never did: write a test
   for the new behaviour first (0 of 6 runs across both tasks), always cover the
   error path (1 of 3 task runs missed it), or leave any record.

3. **Neither task caught the baseline shipping a wrong result.** `task2`'s trap
   wasn't sharp enough for Sonnet. `task3` — the multi-file one, designed so a
   naive `invalidate` returns a stale read — is the real test of "catches a bug
   the baseline ships", and it did not get to run. Until it does, the honest
   claim stays: on small self-contained tasks with a strong model, the value is
   **coverage + an audit trail**, not a caught bug.

4. **Cost: `skills` ≈ 2.5–3× `baseline`** in tokens and ~3× in wall time.

## Caveats

- N ≤ 3, two tasks, one model, headless — indicative, not a measurement.
- The bigger payoff is expected on large / legacy / multi-file repositories
  (existing patterns to match, integration bugs unit tests miss). This harness
  only exercises small self-contained tasks and **cannot test that claim.**
- Process criteria (`plan/status/ledger*`) are things only the skills arm is
  asked to do — they measure "is the discipline running", not "is baseline bad".
- `--append-system-prompt` puts the discipline text alongside Claude Code's base
  instructions; the real plugin's `force-for-plugin` style *replaces* the base
  engineer prompt. Close but not identical.
