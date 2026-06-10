# ADR-003: AISP Coordination Format with In-Repo Validation

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-003 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a self-coordinating swarm of heterogeneous, untrusted AI agents whose only infrastructure is a git repository, where coordination artifacts (goal records, claims, decomposition records, and the swarm contract) must carry meanings — "claimed", "blocked", "expired" — that cannot drift across agents and model versions,
**facing** the fact that the only published validator for the chosen notation (aisp-validator, pinned at 0.3.0) is a v0.x, single-maintainer package that validates generic AISP syntax and tiers only, knows nothing of unsorry's document types, and has undocumented JSON output and exit codes,
**we decided for** writing all coordination artifacts in AISP (AI Symbolic Protocol, per the upstream AI_GUIDE.md grammar) while performing all load-bearing validation with an in-repo deterministic validator (Python 3.12, stdlib-only, in `tools/gate_b/`) that encodes unsorry's domain schemas — `.aisp`/`.lean` pairing, claim filename grammar, per-type schemas, TTL freshness, and SHA-256 index integrity — with the upstream aisp-validator running only as a separate advisory CI job (continue-on-error),
**and neglected** JSON/YAML with JSON Schema validation, trusting the upstream aisp-validator as the required Gate B check, and prose coordination files,
**to achieve** drift-free, machine-validated coordination consistent with the published design commitment, deterministic validation with no external dependency in the required CI path, and domain-aware hygiene checks the generic validator cannot provide,
**accepting that** we maintain our own validator, human contributors face an AISP learning curve, and the upstream validator may diverge from our usage — a divergence whose blast radius is contained by its advisory status, so that an upstream outage or behaviour change degrades hygiene reporting but never queue operation and never soundness.

## Context

The design document (docs/proposals/distributed-research-swarm-plan.md) makes "coordination artifacts are machine-validatable, not prose" a design principle, on the argument that prose metadata in a heterogeneous, untrusted swarm drifts by default. It commits the project to AISP, a fixed-alphabet symbolic specification notation with a deterministic grammar, for all coordination artifacts: goal records (`goals/<id>.aisp`), claims (`claims/<goal-id>.<agent-id>.aisp`), decomposition records, and the swarm contract (`swarm/protocol.aisp`). Agents load the ~19 KB upstream grammar reference (AI_GUIDE.md) at session start; the format costs one context file per session and no fine-tuning, because its alphabet is drawn from the same formal-logic distribution frontier models already parse.

Validation of these artifacts is Gate B, which is hygiene-only by construction: it keeps the queue clean and can never admit anything into the library. Only Gate A (the Lean kernel) decides truth. This bounds what Gate B validation must be — deterministic, fast, and always available — and what it need not be: it carries no mathematical authority, so its failure modes are operational, not soundness-related.

The question this ADR settles is who performs the load-bearing Gate B checks. Verified at decision time: aisp-validator@0.3.0 exists on npm (published January 2026), but it is a v0.x package with a single maintainer; it validates generic AISP syntax and quality tiers only; it knows nothing of unsorry's document types or domain rules (the `.aisp`/`.lean` pairing of goal records, the claim filename grammar, per-type schemas, claim TTL freshness, SHA-256 integrity of library index entries); and its JSON output format and exit codes are undocumented. Making it the required check would place a young external dependency on the critical path of every PR — the design document's own risk register flags exactly this toolchain bus-factor.

One honest note belongs in the record: for the load-bearing checks alone, a boring JSON Schema over JSON or YAML artifacts would have been functionally equivalent. AISP is chosen for the published design-document commitment and for its notation-native readability to the frontier models that are the format's primary readers and writers, and it costs only one context file. The decision is a commitment kept at low cost, not a claim that AISP is the only workable validation substrate.

## Options Considered

### Option 1: AISP artifacts, in-repo deterministic validator as the required check, upstream validator advisory (Selected)
All coordination artifacts are written in AISP per the upstream AI_GUIDE.md grammar. All load-bearing Gate B validation is performed by an in-repo deterministic validator (Python 3.12, stdlib-only, in `tools/gate_b/`) that encodes unsorry's domain schemas: `.aisp`/`.lean` pairing, claim filename grammar, per-type schemas, TTL freshness, and SHA-256 index integrity. The upstream aisp-validator npm package, pinned at 0.3.0, runs as a separate advisory CI job with continue-on-error, providing a generic-syntax cross-check without blocking anything.

Pros: honours the published design commitment; the required CI path has zero external dependencies (stdlib-only, no npm, no network); domain rules the generic validator cannot express are enforced deterministically; upstream divergence or outage is contained to a non-blocking job. Cons: we own and maintain a validator; two validators can disagree, and the advisory job's findings need occasional triage; human contributors must learn AISP to author artifacts by hand.

### Option 2: JSON/YAML artifacts with JSON Schema validation (Rejected)
Functionally adequate — the load-bearing checks reduce to schema validation plus a few custom rules either way, and mature off-the-shelf tooling exists. Rejected because it abandons the published design-document commitment to AISP and forfeits the symbolic-notation properties the plan selects it for: a deterministic grammar with a unique AST per document, and an alphabet native to the frontier-model consumers, at a cost of one ~19 KB context file. Reversing a published architectural commitment for no functional gain would also undercut the project's credibility on its own anti-drift principle.

### Option 3: Upstream aisp-validator as the required Gate B check (Rejected)
Uses the format's own published tooling and avoids maintaining a validator. Rejected because aisp-validator@0.3.0 is v0.x with v0.x semantics (breaking changes permitted at any minor release), has a single maintainer, validates only generic AISP syntax and tiers — none of unsorry's domain rules — and has undocumented JSON output and exit codes, making CI integration brittle. As a required check it would put an upstream outage or behaviour change on the critical path of every PR, blocking the queue. The package still earns a place as an advisory cross-check, where its failure costs nothing.

### Option 4: Prose coordination files (Rejected)
Markdown or free-text claims and goal records require no notation learning and no validator. Rejected because this is exactly the failure mode the design document rules out as a design principle: prose metadata in a heterogeneous swarm drifts, and the meaning of "claimed", "blocked", and "expired" must not depend on how a given model version happens to paraphrase it. Deterministic machine validation of prose is not achievable.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-001 | Adopt Development Protocols | The protocols (ADRs, specs, TDD, production-ready code) govern this decision and the development of the in-repo validator |
| Relates To | ADR-004 | Claims on a Dedicated Branch, First-Push-Wins | Claim files are AISP artifacts; ADR-004 depends on the claim format and validation established here |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed Autonomous Research Swarm: Architecture and Plan (design principle 3, Components §3–4, Appendix A, Risks) | Design document | docs/proposals/distributed-research-swarm-plan.md |
| REF-2 | AISP (AI Symbolic Protocol) — authoritative grammar reference AI_GUIDE.md (~19 KB) | External specification | https://github.com/bar181/aisp-open-core |
| REF-3 | aisp-validator 0.3.0 (pinned; advisory CI job only) | External package (npm) | https://www.npmjs.com/package/aisp-validator |
| REF-4 | SPEC-003-A — Gate B in-repo validator specification | Specification | docs/adrs/specs/ — lands with its implementation PR |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
