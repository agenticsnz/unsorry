# ADR-065: Operator Preflight Doctor

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-065 |
| **Initiative** | unsorry Phase 3 — operability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** an autonomous trunk whose operating surfaces (the scheduled
queue-dispatcher, Gate A runner pools, provider/API tokens) are configured out of
band and assumed correct, with ADR-051 (Experience Layer) and ADR-056 (Control
Plane) describing a full operator interface that remains *Proposed* and unbuilt,
**facing** a concrete incident in which the dispatcher's `REFRESH_TOKEN` secret
lacked pull-request-write permission, so every scheduled run created **zero** PRs
and died with the opaque `Resource not accessible by personal access token
(createPullRequest)` — invisible until hours of log-spelunking, because nothing
checks operator preconditions before they are relied on,
**we decided for** shipping a small **operator preflight doctor**
(`tools/repo/doctor.py`, run as `python3 -m tools.repo.doctor`) — a concrete
first slice of ADR-051/ADR-056 — that runs cheap, side-effect-free checks and
exits non-zero on any `FAIL`, with a flagship `pr-token` check that verifies the
active token can actually open PRs by POSTing to the pulls endpoint **with no
`head`/`base`** (so GitHub rejects it at validation, HTTP 422, and never creates a
PR, but only *after* authorizing the token — so an unauthorized token returns
HTTP 403 first; the status distinguishes the two with no side effect), wired into
the queue-dispatcher workflow as a fail-fast preflight step,
**and neglected** building the full ADR-051/056 dashboard and control plane now
(deferred — the doctor is the minimum that turns a silent precondition failure
into a loud, named one), and inferring token capability from declared PAT scopes
(rejected — fine-grained PATs do not expose scopes via headers and a token with
`Contents: write` but not `Pull requests: write` still passes a scope check yet
fails to create PRs, which is exactly the incident),
**to achieve** preconditions that fail loudly and early with an actionable
message instead of silently breaking autonomous operation,
**accepting that** the doctor starts with a single check (more — runner capacity,
last dispatcher run — slot into its `CHECKS` registry later), the `pr-token` probe
costs one API call per run, and the no-op POST relies on GitHub authorizing
before validating (true today; the 422 OK-path is the safe default if that ever
changed, never a false PASS).

## Context

This is the smallest useful realization of the ADR-051/056 vision, pulled forward
because a real incident showed the cost of having *no* preflight. The doctor's
logic is a pure classifier (`classify_pr_permission`, `parse_http_status`) wrapped
in a thin `gh` probe, so the decision table is unit-tested without network. The
queue-dispatcher runs it after checkout/setup-python and before dispatch, so a
mis-permissioned token fails the job in one step with a fix-it message rather than
after a full pass of opaque per-branch errors.

## Options Considered

### Option 1: Preflight doctor with a no-op PR-create probe (Selected)
**Pros:** detects the exact failure mode (PR-create authorization) with no side
effect; pure, testable core; extensible registry; tiny.
**Cons:** one API call per run; relies on authorize-before-validate ordering
(mitigated: an unexpected status degrades to WARN, never a false PASS).

### Option 2: Infer capability from token scopes (Rejected)
Read `X-OAuth-Scopes` / declared permissions. Rejected: fine-grained PATs do not
expose scopes via headers, and `Contents: write` without `Pull requests: write`
passes a scope check but still cannot create PRs — the incident itself.

### Option 3: Build the full ADR-051/056 dashboard first (Rejected for now)
A control plane surfacing tokens, runners, queue, incidents. Right long-term, but
too large to gate this fix on; the doctor is the first brick of it.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Implements (slice) | ADR-051 | Autonomous Trunk Experience Layer | First diagnostic of the planned `doctor`/health surface |
| Implements (slice) | ADR-056 | Repo-as-OS Control Plane | First operator precondition check |
| Relates To | ADR-058 | Runner Pool Segmentation and Verification Capacity | Dispatcher (the first consumer of the preflight) |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-065-A — Operator preflight doctor | Specification | specs/SPEC-065-A-Operator-Preflight-Doctor.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
| Accepted | unsorry maintainers | 2026-06-17 |
