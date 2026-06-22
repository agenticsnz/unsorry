# SPEC-080-A: Domain-Admission Registry and the Gating Predicate

Implements: [ADR-080](../ADR-080-Platform-Generalisation-And-Domain-Neutrality.md) · Status: Draft · Updated: 2026-06-20

> **DRAFT.** ADR-080 is a mission-scope policy for founder ratification; this spec is
> its *enforcement mechanism* — how the gating invariant becomes machine-checkable.

## What this adds

ADR-080's gating invariant ("admissible to the trustless commons iff a cheap,
deterministic, kernel-grade self-verifier") is a policy. This makes it operational:
a **registry** of admitted domains/targets and a **pure predicate** the intake path
consults, so the policy is enforced at the door rather than asserted in prose.

## The registry

A single auditable file, `docs/governance/admitted-domains.json` (schema-versioned),
recording founder-ratified decisions:
```jsonc
{
  "schema_version": 1,
  "domains": [
    { "id": "lean-math",        "verifier": "lean-kernel",  "tier": "VERIFIED", "ratified": "..." },
    { "id": "lean-software",    "verifier": "lean-kernel",  "tier": "VERIFIED", "ratified": "..." }
  ],
  "targets": [
    { "package": "lion", "domain": "lean-software", "supplier": "khive", "ratified": "..." }
  ]
}
```
A domain carries a declared `verifier` and a `tier`. **Only `tier: VERIFIED`
(kernel-grade) domains join the trustless commons** — softer ADR-052 tiers
(SCORED/CONSENSUS/APPROVAL) may appear but are advisory-only and never merge into the
commons (ADR-080 clause 3). `targets` records each curated package's vetted supplier
(consumed by SPEC-081-A check 2 and SPEC-078-A's "curated-only" rule).

## The predicate (pure, stdlib-only)

`tools/governance/admission.py`:
- `domain_admissible(domain_id, registry) -> bool` — true iff the domain is present
  and `tier == "VERIFIED"`.
- `target_curated(package, registry) -> Supplier | None` — the vetted supplier for a
  package, else `None` (self-minted → not curated).

These are the single source of truth consumed by **SPEC-081-A** (`skeleton-validate`
checks 2 and 6) and **SPEC-078-A** (structural weight only for curated targets). The
predicate makes the founding "ranks 4–9 are out" line a test, not a footnote.

## Governance flow (human → record)

Admitting a new domain or target is a **founder/maintainer decision** (ADR-080
governance + ADR-054 trust tiers). The decision is recorded by adding a registry
entry in a PR — itself code-owner-gated — so every admission is auditable and
reviewable. No code path admits a domain/target that isn't in the registry.

## Reuse
The registry is plain JSON parsed with stdlib `json`; provenance/tier concepts align
with ADR-052 / ADR-054. No new infra.

## Tests (`tools/governance/tests/`)
- a `VERIFIED` domain is admissible; a `SCORED`/absent domain is not (ranks 4–9
  rejected);
- a package with a registry `targets` entry → curated supplier returned; a
  self-minted package → `None`;
- registry parse: bad schema_version / malformed entry → rejected cleanly.

## Out of scope
- The *ratification* itself (a human/founder act — this only records and enforces it).
- The intake structural checks (SPEC-081-A) and the scoring (SPEC-078-A) — this spec
  only provides the admissibility source of truth they consult.
