---
name: aiskills-security-review
description: Security vulnerability assessment covering injection prevention, authentication, authorization, data protection, secrets management, dependency risk, and infrastructure security. Use as the security lens on a diff, when adding a new service or API, or when assessing third-party dependencies.
---

# Security Review

**Loop stage:** Review — pre-merge (security lens) — threat-model / vulnerability pass before
shipping.

**Loop subgraph** (grammar in `aiskills-agentic-loops`, activation in `brain/loop-contract.md` — neither
restated here): `mini-L3 (security check dimensions, read-only) → CLOSE = findings` ·
stop:review-clean. Fixing the diff opens a Build graph via `aiskills-build-discipline` — never patch-and-post
from inside the review.

**Boundary:** for security/threat review, use `aiskills-code-review`;
pair with `aiskills-doubt-driven-development` for high-stakes verification.

**Loop invariant:** each pass over the checklist either surfaces a new issue class or confirms
a category is clean — never re-walk a category without changing that state. A clean pass is
still a visible ♦ line (auditable negative).

## Security Checklist

### 1. Input Validation
- [ ] All external inputs validated (type, length, format, range) on the trust boundary
- [ ] Parameterized queries for all database operations (no string interpolation)
- [ ] HTML/output encoding to prevent XSS
- [ ] File paths validated against traversal (`..`, absolute paths, symlinks)
- [ ] Deserialization uses safe methods with allowlists
- [ ] Regular expressions are bounded (no catastrophic backtracking / ReDoS)

### 2. Authentication
- [ ] Authentication required for all non-public endpoints
- [ ] Tokens validated server-side on every request (signature, expiry, audience)
- [ ] Session management follows secure patterns (rotation, secure/httpOnly cookies)
- [ ] Credential reset flows can't be enumerated or hijacked
- [ ] Authentication failures don't leak information (same error for wrong user/password)

### 3. Authorization
- [ ] Every operation checks the caller's permissions — object-level, not just endpoint-level
- [ ] Least privilege: minimal permissions granted; no wildcard resource/action grants in production
- [ ] Cross-account/cross-tenant access uses explicit trust with conditions
- [ ] No privilege-escalation paths (a user-controlled field selecting a role, etc.)

### 4. Data Protection
- [ ] Sensitive data encrypted in transit (TLS) and at rest
- [ ] PII identified, minimized, and never written to logs
- [ ] Sensitive fields excluded from error messages, traces, and analytics
- [ ] Data retention/deletion paths exist for regulated data

### 5. Secrets Management
- [ ] No secrets in code, config files, environment defaults, or test fixtures
- [ ] Secrets come from a secrets manager / parameter store at runtime
- [ ] Grep the diff for key patterns (`AKIA`, `sk-`, `-----BEGIN`, `password=`) before merge
- [ ] Rotation is possible without a deploy

### 6. Dependencies
- [ ] New dependencies pinned to exact versions; name checked against typosquatting
- [ ] Known-vulnerability scan (audit tooling) clean, or exceptions justified
- [ ] Licenses compatible; abandoned packages flagged

### 7. Infrastructure & Operations
- [ ] Network exposure minimal (private by default; every open port justified)
- [ ] New endpoints/services flagged if authentication is absent — never silently unauthenticated
- [ ] Error handling fails CLOSED for auth decisions
- [ ] Audit logging on security-relevant events (login, permission change, data export)
- [ ] Rate limiting on authentication and expensive endpoints

## Severity & reporting

Use `aiskills-code-review`'s severity ladder: a confirmed injection, auth bypass, or secret in the
diff is always a **Blocker**. Every finding names the category, the exact mechanism, the attack
enables, and the minimal fix. Uncertain? Escalate as a question — never silently assume safe
(`aiskills-doubt-driven-development`: "I verified because...", not "it should be fine").

## Red flags — stop and doubt

- Building auth/crypto by hand when a vetted library exists
- A permission check that happens client-side only
- "Temporary" debug endpoints or backdoors
- Test credentials that look production-shaped
- An error handler that logs the full request (PII + secrets go to logs)
