---
name: observability
description: Building observability INTO a service up front — structured logging, metrics emission, distributed tracing, alarm configuration, and dashboard design. Use when building or instrumenting a service, adding a dependency, or shipping a feature to production. To investigate an active incident, use incident-investigation instead.
---

# Observability

**Loop stage:** Build — instrument — add logs, metrics, and traces while building the service,
not after. When instrumentation involves writing code, `build-discipline` governs how signals
are designed before code, asserted in RED, verified before VERIFY — stop:signals-verified.

**Loop subgraph** (grammar in `agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **Build-slot: instrumentation designed in Phase 0, asserted in RED, verified at
VERIFY** · stop:signals-verified.

## Overview

Instrument services so they tell you what's happening without being asked. You can't manage
what you can't measure, and incidents don't wait for you to add telemetry. Observability is a
build-time deliverable, not a post-launch chore: every endpoint ships with its metrics, logs,
traces, alarms, and dashboards — or it isn't done.

## Usage

Use this skill when:
- Building a new service or API endpoint
- Adding a new dependency or integration
- Shipping a feature to production
- Setting up alarms and dashboards
- Existing telemetry failed you during a debugging session or incident

## The Three Pillars

1. **Metrics (what is happening?)** — quantitative measurements over time. Use for alerting,
   dashboards, capacity planning. Name them `Service.Operation.MetricType`; dimension by
   operation, status class, region, and dependency.
2. **Logs (why is it happening?)** — detailed event records. Use for debugging specific
   requests and understanding behavior.
3. **Traces (where is it happening?)** — request flow across services. Use for latency
   distribution and bottlenecks. Propagate trace context on every outbound call; create child
   spans for significant operations, cache lookups, and outbound service or database calls.

## Metrics: The Four Golden Signals

Every service endpoint MUST emit:

| Signal | What to measure | Why |
|---|---|---|
| **Latency** | P50, P90, P99 response time | Detect slowdowns before users notice |
| **Traffic** | Requests per second | Understand load and detect anomalies |
| **Errors** | Error rate (5xx / total) | Catch failures immediately |
| **Saturation** | CPU, memory, connections, queue depth | Predict exhaustion before it hits |

## Logging: Structured and Contextual

Every log line is a structured record, not a sentence. Required fields: timestamp, level,
correlation id (request id), operation, message, duration where relevant.

Rules:
- **Correlation ids everywhere.** Every log line carries the request id so one request's story
  can be reassembled across services. Generate at the edge, propagate downstream.
- **Never log PII, secrets, tokens, or passwords.** No exceptions, no "just for debugging".
- **Level discipline.** ERROR = unexpected failure needing attention; WARN = recoverable and
  detailed flow, disabled in production. Expected, handled errors are WARN, never ERROR.
- **High-cardinality values go in structured fields,** not in the message text.

## Alarms: Act on Symptoms

- **Alert on symptoms** (error rate high, latency above SLA), **not causes** (high CPU alone
  isn't actionable — it may be normal).
- **Page on customer impact**; warn on internal signals like dependency errors or saturation.
- Every alarm is actionable and has a runbook: who does what when it fires. An alarm with
  no runbook is noise waiting to happen.
- Thresholds tune to each service's SLA, traffic, and baseline. Sustained
  breaches over minutes, not single-sample spikes.
- Every new dependency gets an alarm on its error rate and latency and baseline. Sustained

## Dashboard Design

Every service dashboard shows, top to bottom: health overview per endpoint; traffic with
historical comparison; errors with breakdown by type; latency percentiles vs the SLA line
drawn in; dependency health; and resource saturation. Define dashboards as code, version
controlled and reproducible across environments, not clicked together and forgotten.

## Instrumentation in the TDD Spine (see `build-discipline`)

Instrumentation rides the same loop as the feature it observes:

- **Phase 0 (design)** — decide the signals before code — which metrics, what log events, what
  conventions; don't invent parallel ones.
- **RED** — assert instrumentation in failing tests: does the code emit the correlation id,
  "no PII in the serialized log entry", telemetry that isn't tested is telemetry that
  gets silently broken.
- **VERIFY** — before build, confirm signals actually flow — run the suite, exercise the
  endpoint, check the metric/log/trace output is emitted and the dashboard and alarm
  definitions build. Feed gaps discovered here to `continuous-learning`.

When existing telemetry proves insufficient during `debugging-recovery` or
`incident-investigation`, the fix loops back: add the missing signal with a test, don't
just eyeball the fix.

## Anti-patterns

- **"We'll add observability later"** — incidents don't wait; instrument from day one.
- **"The framework handles it"** — frameworks give basics; business metrics require explicit code.
- **Metering a metrics platform** — emitting useful data the tool doesn't itself know how to.
- **Alarming on every single error** — noise breeds alarm fatigue; alarm on rates and trends.
- **Alarm without a runbook** — pages someone who doesn't know what to do.
- **Untested telemetry** — a metric nobody asserts on is a metric that's silently gone.
- **"The error rate is low"** — low rate x high traffic = many affected customers.
