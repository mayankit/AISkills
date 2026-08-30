# Benchmark results

Run: `bench/run.sh 3` — 3 runs per arm, `claude-sonnet-5`, headless `claude -p`,
one task (`bench/task/`). Regenerate with `bench/run.sh`; raw transcripts and
per-run `score.tsv` are under `bench/runs/<ts>/` (gitignored).

## Headline

| arm | avg score | scores | avg cost | avg time | avg turns |
|---|---|---|---|---|---|
| baseline (plugin off) | **5.00 / 11** | 5, 5, 5 | $0.090 | 34 s | 8.0 |
| skills (plugin on) | **9.67 / 11** | 9, 11, 9 | $0.196 | 77 s | 11.7 |

**The skills arm did clearly better** — on this task, for ~2.2× the cost and time.

## Per criterion (mean over 3 runs)

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
| heartbeat_ge3_distinct_iters | 0.00 | 0.33 |
| ledger_file_written | 0.00 | 0.67 |

## What actually separated them

- **Testing the new behaviour.** All 3 baseline runs added `total_with_tax`,
  ran the *pre-existing* 2 tests, saw them pass, and stopped — no test for the
  new function, no coverage of the `ValueError` path. All 3 skills runs wrote a
  failing test for the new behaviour first, watched it fail (confirmed from the
  stream-json tool-call order: edit test → `pytest` collection error → edit
  `pricing.py` → `pytest` green), then implemented.
- **Trap A (re-deriving a solved detail).** 1 of 3 baseline runs re-derived
  money rounding (`round(total*rate, 2)`) instead of reusing the module's
  hardened `_round_money`. No skills run did.
- **Auditability.** Baseline leaves nothing. Skills leaves a `◇ PLAN` tree,
  `◆` status lines, and a real `loop-ledger.md` (in 2 of 3 runs — see below).

Neither arm hit Trap B, and **baseline's code was always functionally correct**.
On a task this small with a strong model, the discipline's value here is
*coverage + a trail*, not "it caught a bug the baseline shipped."

## Caveats — read these before quoting a number

- **N = 3, one task, one model.** Indicative, not a measurement.
- **Headless ≠ interactive.** No user steering, no mid-task correction — the
  interrupt / re-orient half of the discipline can't show up here.
- **Criteria 8–11 only the skills arm is asked to do** — they measure "is the
  discipline running", not "is baseline bad". The load-bearing comparison is
  criteria 1–7 (baseline 4.0/7, skills 7.0/7).
- **skills #3 emitted no `◇ PLAN` tree** — `plan_tree_emitted` 0.67, not 1.0.
  In headless `-p`, `force-for-plugin` activation was not 100% reliable across
  these 3 runs (or the model judged the task trivial and skipped planning).
- **heartbeat cadence held in only 1 of 3 skills runs.** On a 2–3 iteration
  task the "a line every iteration" rule collapses to open/close lines. This is
  a real gap between what the discipline says and what a small headless run does.
- **Cost/time**: skills ≈ 2.2× cost, 2.3× wall time, 1.5× turns. Same shape the
  article reported.

## Rubric fixes made while running this

- `test_written_and_failed_first` initially scored 0 for 2 of 3 skills runs even
  though the tool-call order shows genuine RED-first. Cause: the "first write to
  `pricing.py`" matcher used a substring test, which also matched
  `test_pricing.py`, so `test_write == impl_write`. Fixed to match the
  `file_path` basename exactly and to require a pytest *failure* signature
  strictly between the test write and the impl write.
- `status_lines_ge3` missed real ledger lines because it anchored `^◆` — ledger
  lines carry an ISO-timestamp prefix. Fixed to match `◆` anywhere on the line.
