---
name: api-design
description: API design patterns covering REST, GraphQL, and RPC including versioning, pagination, error handling, rate limiting, idempotency, and backward compatibility strategies. Use when designing new APIs or endpoints, adding operations to existing services, or reviewing API contracts.
---

# API Design

**Loop stage:** Design — shape the API/contract before building against it. When you implement
the contract in code, load `build-discipline` for the how; this skill tells you *what* the
contract is.

**Loop subgraph** (grammar in `agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): **Fan-Out orchestration** — the L3 dispatch/join mechanics live in `design`
· stop:contract-agreed. Record expensive-to-reverse contract choices as ADRs (`design`, Part 2).

## REST design

### Resources
- Nouns, not verbs: `/orders` not `/getOrders`; plural collections: `/products`
- Hierarchy for ownership: `/orders/{id}/items`; lowercase-with-hyphens: `/order-items`

### Methods
| Method | Purpose | Idempotent | Safe |
|---|---|---|---|
| GET | Read | Yes | Yes |
| POST | Create | No | No |
| PUT | Replace | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove | Yes | No |

**Idempotency for unsafe operations:** any POST a client may retry (payments, orders) takes an
idempotency key; replays return the original result, not a duplicate side effect.

### Status codes — use the precise one
`200` read/update OK · `201` created (with Location) · `202` accepted async · `204` no body ·
`400` malformed · `401` unauthenticated · `403` absent/insufficient permissions · `404` doesn't
exist but you had permission · `409` conflict · `422` semantic error · `429` throttled ·
`5xx` server fault (never for client mistakes).

### Errors — one machine-readable shape everywhere

```json
{
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order 123 does not exist",
    "requestId": "abc-123",
    "details": [{"field": "orderId", "issue": "unknown id"}]
  }
}
```

- Stable, documented `code` values — clients pattern-match them; changing one is a breaking change
- Human `message` for developers; never lean internals (stack traces, SQL, hostnames)
- Always include a correlation/request id

## Pagination — mandatory on every collection

- **Cursor-based** (opaque `nextToken`) for anything that grows: stable under concurrent
  writes, no deep-offset cost. Offset/page only for small, static sets.
- Response carries the page AND the cursor: `{ "items": [...], "nextToken": "..." }`
- Server-enforced max page size; document the default.
- An unbounded list endpoint is a Blocker in review — it will fall over at scale.

## Versioning & backward compatibility

Compatibility contract — clients must keep working:
- **Non-breaking (allowed):** adding optional request fields, adding response fields, adding
  new endpoints/operations, relaxing validation.
- **Breaking (needs a new version or a migration):** removing/renaming fields, changing types
  or semantics, making optional required, tightening validation, changing error codes,
  reordering enum semantics.

Strategy: evolve additively for as long as possible; version (URL `/v2` or header) only when
additive evolution genuinely can't express the change. Deprecate with a documented sunset
window and telemetry to see who's still calling.

## Rate limiting & resilience

- Every public/multi-tenant endpoint has a rate limit; respond `429` with `Retry-After`
- Document limits: scope them per-caller, not globally
- Timeouts on everything the server calls; retries only on idempotent operations, with
  exponential backoff + jitter: a retry storm is a self-inflicted outage
- Design for partial failure: bulk endpoints report per-item success/failure

## GraphQL / RPC notes

- GraphQL: depth/complexity limits (a hostile query is a DoS), dataloader-style batching to
  kill N+1s, deprecate fields via `@deprecated` — never remove while queried.
- RPC: operations named verb-object (`CreateOrder`); requests/responses are structs (never
  scalars) so new fields can be added compatibly; keep fields optional; keep quality typed.

## Contract review checklist (before handoff to Build)

- [ ] Every operation: documented purpose, request/response shape, error codes
- [ ] Collections paginated; unsafe/retriable operations idempotent
- [ ] Error shape uniform and machine-readable; no internal leakage
- [ ] Compatibility impact stated (additive/breaking/versioned)
- [ ] Rate limits + auth model named per endpoint
- [ ] Expensive-to-reverse choices recorded as an ADR
