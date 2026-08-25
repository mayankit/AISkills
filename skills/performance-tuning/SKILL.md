---
name: performance-tuning
description: Performance optimization patterns including profiling methodology, caching strategies, database and query optimization, concurrency patterns, and capacity planning. Use when investigating slow endpoints, planning for traffic growth. Measure first — never optimize without data.
---

# Performance Tuning

**Loop stage:** Optimize — post-correctness measure → profile → optimize → verify loop. When
you change code to optimize, load `build-discipline` for the how; this skill tells you *what*
to optimize.

**Loop subgraph** (grammar in `agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): `L4 Refinement [measure → change → verify]` · stop:targets-met-or-no-worthwhile-gain, only over a green L2 — never optimize failing code.

## Methodology

### 1. Measure First
**Never optimize without data.** A guess about the bottleneck is wrong more often than right.
- Establish a baseline: P50 / P90 / P99 latency, throughput, resource usage.
- Set an explicit, numeric target BEFORE changing anything (e.g., "P99 < 200ms") — without a
  target the loop has no stop condition.
- Measure at realistic scale and data shape; superliner behavior hides at toy scale.

### 2. Profile
- Profile CPU, memory, I/O, and lock contention separately — they need different fixes.
- Use tracing to find WHERE time goes across calls; profile the hot path, not the whole app.
- Prioritize over averages: the P99 is where users suffer and averages lie.

### 3. Optimize the bottleneck
- Fix the #1 bottleneck first — optimizing anything else changes nothing measurable.
- One change per iteration; re-measure after EACH change against the same baseline.
- Stop when targets are met (`stop:targets-met`) — over-optimization isn't worth its complexity.
- Keep the receipts: before/after numbers — record which change made the difference.

### 4. Verify
- The full test gate still passes AND the improvement holds at P99, not just the average.

## The usual suspects (check in this order)

1. **N+1 queries / chatty I/O** — one query per item in a loop; batch or join instead.
2. **Missing indexes** — a full scan behind a hot filter; explain/analyze the query plan.
3. **Overfetching** — loading whole objects/collections for one field; select what you need.
4. **Serial awaits of independent calls** — fan out concurrent I/O (same bug the loop grammar
   forbids in tool dispatch).
5. **Unbounded work per request** — no pagination/limit; superlinear algorithms on user input.
6. **Allocation churn in hot loops** — building strings/collections per iteration.
7. **Lock contention** — a coarse lock around fine-grained work.
8. **Cold caches / no cache** — recomputing stable values per request.

## Caching (the sharpest knife — cut deliberately)

- Cache only what's measured hot AND tolerably stale; name the TTL and the staleness budget deliberately.
- Every cache needs an invalidation story BEFORE it ships — "it expires eventually" is an
  incident deferred.
- Guard against stampedes (request coalescing / jittered TTLs) and unbounded growth (max size + eviction).
- A cache with a low hit rate is pure complexity; measure the hit rate or delete it.

## Concurrency

- Parallelize independent I/O; keep CPU-bound parallelize a core count.
- Bound every queue and pool — unbounded queues turn overload into memory death.
- Backpressure over buffering: shed or slow producers when consumers lag.
- Timeouts + circuit breakers on every remote call; a slow dependency without a timeout makes
  its latency YOUR latency.

## Capacity planning

- Load-test to find the knee (where P99 degrades nonlinearly); operate below with headroom.
- Plan for peak + safety factor, not average; know the scaling unit (what do you add when full?).
- Watch saturation trends (`observability`'s Golden Signals) — capacity is a forecast, not a reaction.

## Anti-patterns

- **Optimizing without a baseline** — you can't prove the win, and there may be one.
- **Micro-optimizing the cold path** — nanoseconds in code that runs once per deploy.
- **Cache-as-bugfix** — caching over a query that should just be fixed.
- **Premature optimization** — complexity added before any user felt the latency.
- **Benchmark theater** — best-of-N on a warm laptop presented as a production claim.
