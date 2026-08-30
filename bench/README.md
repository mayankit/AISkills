# bench/ — with-aiSkills vs baseline

A reproducible A/B: the same coding task, given to headless `claude` twice —
plugin enabled + discipline in the system prompt vs nothing — scored on
objective, mechanically-checkable criteria.

```bash
bash bench/run.sh 5                       # 5 runs/arm on every task in bench/task*/
bash bench/run.sh 3 bench/task2           # just one task
```

Needs an authenticated `claude` CLI and `python3`. Real tokens: ~$0.1–0.5 and
1–3 min per run, so `5 × 2 arms × 2 tasks` ≈ $3–8.

## The two arms

| arm | plugin | system prompt |
|---|---|---|
| `baseline` | **disabled** for the batch | default |
| `skills` | **enabled** | default **+** the discipline output style appended (`--append-system-prompt`) **+** `--plugin-dir <repo>` so the 16 skills load on demand |

`skills` applies the discipline **deterministically** — an earlier version relied
on `force-for-plugin` alone and it activated in only ~2 of 3 headless runs.
`run.sh` disables the plugin, runs every baseline, enables it, runs every skills
run, and re-enables on exit. It flags any baseline that shows a `◇ PLAN` tree,
or any skills run that doesn't (discipline in the prompt but not followed).

Same prompt, model (`claude-sonnet-5`, override `BENCH_MODEL`), tools; a fresh
copy of the task each run in a throwaway dir **outside any git repo** so each
produces its own `.agentic-loops/loop-ledger.md`.

## Tasks

Each `bench/task*/` has `PROMPT.txt`, the starting `*.py`, and `EXPECTED.sh`
(the task's outcome checks, sourced by `rubric.sh`).

- **`task/`** — add `total_with_tax(items, region)` to a `pricing.py` that
  already has a hardened `_round_money` (Decimal, half-up) and a `TAX_RATES`
  table. Two traps from the article's comparison: re-deriving money rounding
  (`round(total*rate, 2)`) instead of reusing `_round_money`, and hardcoding
  the rates. Plus: test the unknown-region `ValueError`.
- **`task2/`** — add `latest_per_customer(orders)`. Trap: a quick
  `{o["customer_id"]: o for o in orders}` keeps whichever order is **last in
  list order**, not the one with the highest `ts`. The `selects_by_max_ts…`
  check is the bug check — the baseline is expected to ship the wrong result
  some of the time.

## Scoring (`bench/rubric.sh`)

Task outcome checks (from `EXPECTED.sh`) + 7 shared process checks:

- `test_written_and_failed_first` — from the stream-json tool-call order: first
  write to a `test_*.py` precedes the first write to the impl module, and a
  pytest failure is seen strictly between them
- `real_gate_executed` — the suite was actually run
- `plan_tree_emitted` — a `◇ PLAN` tree
- `status_lines_ge3` — `◆` loop status lines
- `ledger_incremental` — the ledger has ≥2 distinct timestamps **and** ≥2
  distinct `iter N` (i.e. it was appended to as work happened, not reconstructed
  in one batch at the end)
- `ledger_file_written` — a real `loop-ledger.md` with `◆` entries

`run.sh` also records `cost_usd`, `duration_ms`, `num_turns`.

## Honest caveats

- **Small N, two tasks, one model.** Indicative, not a measurement.
- **Headless ≠ interactive.** No user steering / mid-task correction — the
  interrupt & re-orient half of the discipline can't show here.
- The process checks (`plan/status/ledger*`) are, by construction, things only
  the `skills` arm is asked to do. They measure "is the discipline running",
  not "is baseline bad". The load-bearing comparison is the task outcome checks
  + `test_written_and_failed_first`.
- Expect `skills` to cost ~2× and take ~2–3× longer — the article's shape.

## Results

Checked-in numbers: [`bench/RESULTS.md`](RESULTS.md) (regenerate with `run.sh`).
Raw transcripts / per-criterion `score.tsv`: `bench/runs/` (gitignored).
