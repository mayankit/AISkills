# Benchmark results

**Headline (valid run):** `task/` only, N=3, `claude-sonnet-5`, headless `claude -p`.

| arm | avg score | scores | avg cost | avg time | turns |
|---|---|---|---|---|---|
| baseline (plugin off) | **5.00 / 11** | 5, 5, 5 | $0.090 | 34 s | 8.0 |
| skills (plugin on + discipline in prompt) | **9.67 / 11** | 9, 11, 9 | $0.196 | 77 s | 11.7 |

Five more `task/baseline` runs from an aborted N=5 attempt scored 6, 5, 5, 5, 5 —
the baseline sits at ~5.1/11, very stable. **The skills arm did clearly better,
for ~2.2× the cost and ~2.3× the wall time.**

## Per criterion (mean over the 3 valid runs each)

| criterion | baseline | skills |
|---|---|---|
| **outcome** | | |
| final_tests_green | 1.00 | 1.00 |
| function_added | 1.00 | 1.00 |
| unknown_region_guarded_and_tested | 0.33 | **1.00** |
| reuses_round_money_helper *(trap A)* | 0.67 | **1.00** |
| reuses_tax_rates_table *(trap B)* | 1.00 | 1.00 |
| **process** | | |
| test_written_and_failed_first | 0.00 | **1.00** |
| real_gate_executed | 1.00 | 1.00 |
| plan_tree_emitted | 0.00 | 0.67 |
| status_lines_ge3 | 0.00 | 1.00 |
| ledger_incremental | 0.00 | 0.33 |
| ledger_file_written | 0.00 | 0.67 |

## What separated them

- **Testing the new behaviour.** Every baseline run added `total_with_tax`, ran
  the *pre-existing* 2 tests, saw them pass, and stopped — no test for the new
  function, no `ValueError` coverage. Every skills run wrote a failing test for
  the new behaviour first and watched it fail (confirmed from the stream-json
  tool-call order) before implementing.
- **Trap A.** 1 of 3 baseline runs re-derived money rounding instead of reusing
  `_round_money`. No skills run did.
- **Auditability.** Baseline leaves nothing; skills leaves a plan tree, status
  lines, and (2 of 3 runs) a ledger.

Neither arm hit Trap B, and **baseline's code was always functionally correct.**
On a task this small with a strong model, the discipline's value here is
*coverage + a trail*, not "it caught a bug the baseline shipped."

## What did NOT finish, and why

- **The N=5 × 2-task run aborted.** After ~6 runs the account hit its 5-hour
  usage limit (`rateLimitType: five_hour`, utilization 1.0, overage
  org-disabled). Every run after that was rejected with 0 tokens; `run.sh` now
  detects this and aborts cleanly instead of recording bogus rows.
- **`task2/` has no comparison data yet.** The harness is built and smoke-tested
  (one skills run scored 11/11 with a correct impl), but a full `task2` A/B
  needs budget. Re-run: `bash bench/run.sh 5` after the limit resets — it now
  paces runs (`BENCH_PACE`, default 20 s) and aborts on the next limit.
- **`ledger_incremental` is 0.33 for skills.** 2 of 3 skills runs reconstructed
  the ledger in one batch at the end (or skipped it as "small"). That gap is
  exactly what the `feat(discipline): ledger is written incrementally` change on
  `main` (plugin v0.4.0) tightens — these bench runs predate it, so a re-run on
  v0.4.0 should move this number.

## Caveats — read before quoting a number

- **N = 3, one task, one model.** Indicative, not a measurement.
- **Headless ≠ interactive.** No user steering / mid-task correction — the
  interrupt & re-orient half of the discipline can't show up here.
- The process checks (`plan/status/ledger*`) are things only the skills arm is
  asked to do — they measure "is the discipline running", not "is baseline bad".
  The load-bearing comparison is the outcome checks + `test_written_and_failed_first`
  (baseline 4.0/7, skills 7.0/7).
- `plan_tree_emitted` 0.67, not 1.0 — even with the discipline in the system
  prompt, 1 of 3 skills runs skipped the plan tree on a task it judged trivial.

## Rubric fixes made while running this

- `test_written_and_failed_first` scored 0 for skills runs that genuinely went
  RED-first: the "first write to the impl file" matcher used a substring that
  also matched `test_*.py`. Now matches the `file_path` basename exactly and
  requires a pytest failure strictly between the test write and the impl write.
- `status_lines_ge3` missed real ledger lines (they carry an ISO-timestamp
  prefix, so `^◆` never matched).
- `heartbeat_ge3_distinct_iters` → `ledger_incremental` (≥2 timestamps **and**
  ≥2 `iter N`): checks the ledger was appended to as work happened, without
  punishing an efficient 2-iteration run for not reaching iteration 3.
- `task2` probe imported from a temp-file path that wasn't on `sys.path`; now
  runs via stdin from the result dir.
