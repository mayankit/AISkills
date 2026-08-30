# bench/ — with-aiSkills vs baseline

A small, reproducible A/B: the **same** coding task, given to headless `claude`
twice — once with the aiSkills package active, once with nothing added — then
scored against objective, mechanically-checkable criteria.

```bash
bash bench/run.sh 5        # 5 runs per arm (default 3); writes bench/runs/<ts>/
```

Needs an authenticated `claude` CLI and `python3`. Each run costs real tokens
(~$0.2–0.6 and 1–5 min per run), so 5×2 ≈ $2–6.

## The two arms

Both are plain `claude -p "<task>" --dangerously-skip-permissions`. The only
difference is whether the `aiskills@aiskills` plugin is enabled:

| arm | plugin |
|---|---|
| `baseline` | **disabled** for the whole baseline batch — no discipline in the system prompt |
| `skills` | **enabled** — `force-for-plugin` applies the discipline output style; this is the real deployment condition |

`run.sh` disables the plugin, runs every baseline, enables it, runs every
skills run, and re-enables it on exit regardless. (`--bare` would be simpler but
it disables keychain reads and breaks auth, so the run toggles the plugin
instead.) It also flags any baseline run that shows a `◇ PLAN` tree, or any
skills run that doesn't.

Same prompt, same model (`claude-sonnet-5`, override with `BENCH_MODEL`), same
tools, a fresh copy of the task each run in a throwaway dir **outside any git
repo** so each produces its own `.agentic-loops/loop-ledger.md`.

## The task (`bench/task/`)

`pricing.py` already contains a hardened `_round_money()` helper (Decimal,
half-up — with a comment explaining *why* builtin `round()` is wrong for money)
and a `TAX_RATES` table. `test_pricing.py` is an existing suite that must stay
green. The prompt asks for a `total_with_tax(items, region)` function.

Two traps, both from the article's own comparison:

- **re-deriving a solved detail** — a naive impl does `round(total * 1.08, 2)`,
  which is banker's rounding on a binary float and produces wrong cents. The
  right move is to reuse `_round_money()`.
- **duplicating logic** — hardcoding `0.08 / 0.20 / 0.12` at the call site
  instead of reusing `TAX_RATES`.

Plus the ordinary bar: add a test (including the unknown-region `ValueError`
path) and actually run the suite before declaring done.

## Scoring (`bench/rubric.sh`, 11 points)

Outcome — did it get the change right:
1. `final_tests_green` — `pytest` passes in the result dir
2. `function_added`
3. `unknown_region_guarded_and_tested`
4. `reuses_round_money_helper` — no second rounding mechanism introduced
5. `reuses_tax_rates_table` — no fresh rate literals in the new function

Process — did it work like an engineer:
6. `test_written_and_failed_first`
7. `real_gate_executed` — the transcript shows the suite actually run
8. `plan_tree_emitted` — a `◇ PLAN` tree before the work
9. `status_lines_ge3` — `◆` loop status lines
10. `heartbeat_ge3_distinct_iters` — `iter N` visible across ≥3 iterations
11. `ledger_file_written` — a real `loop-ledger.md` with `◆` entries

`bench/run.sh` also records `cost_usd`, `duration_ms`, `num_turns` per run.

## Honest caveats

- **Small N, one task, one model.** LLM runs are stochastic; treat a handful of
  runs as *indicative*, not a measurement. Bump `N` and add tasks under
  `bench/task*/` for anything you'd quote.
- **Headless ≠ interactive.** No user steering, no mid-task correction — the
  interrupt/re-orient parts of the discipline can't show up here.
- Criteria 8–11 are, by construction, things only the `skills` arm is asked to
  do. They measure *"is the discipline actually running"*, not *"is baseline
  bad"*. The load-bearing comparison is criteria 1–7, which both arms are equally
  able to satisfy.
- The article's own run found the structured arm **~3× slower** on a small task
  while catching a real bug the baseline shipped. Expect `run.sh` to reproduce
  that shape: higher `cost_usd`/`duration_ms` for `skills`, higher rubric score.

## Results

Checked-in numbers live in `bench/RESULTS.md` (regenerate with `bench/run.sh`).
Raw transcripts and per-criterion `score.tsv` are under `bench/runs/` (gitignored).
