# Domain Docs

How the engineering skills should consume and extend this repo's domain documentation.

This repo is **single-context**. It follows the development protocols vendored at [`docs/protocols.md`](../protocols.md) (adopted by [ADR-001](../adrs/ADR-001-Adopt-Development-Protocols.md)). **Those protocols win over any default convention baked into a skill.**

## Before exploring, read these

- **`CONTEXT.md`** at the repo root (does not exist yet — see below)
- **`docs/adrs/`** — read ADRs that touch the area you're about to work in
- **`docs/adrs/specs/`** — the living spec for an ADR that carries implementation
- **`docs/protocols.md`** — the binding development protocols themselves
- **`CLAUDE.md`** — project guidelines and key structural decisions

If `CONTEXT.md` doesn't exist, **proceed silently**. Don't flag its absence; don't suggest creating it upfront. `/domain-modeling` creates it lazily when terms actually get resolved.

`docs/adrs/` does exist and is populated (ADR-001 onward). Never proceed as though it were absent.

## ADR convention (protocol §1 — non-negotiable)

- **Location:** `docs/adrs/`. Not `docs/adr/`.
- **Filename:** `ADR-NNN-Title-In-Title-Case.md` — zero-padded to three digits, e.g. `ADR-019-CI-Supply-Chain-Protection.md`. Not `0001-slug.md`.
- **Numbering:** scan `docs/adrs/` for the highest existing `ADR-NNN` and increment by one.
- **When:** *always* create or update an ADR when an architectural, technical, or significant design decision is made. This repo does **not** use the "offer ADRs sparingly, only if hard-to-reverse and surprising and a real trade-off" heuristic — that bar is lower here, and a skill that suppresses an ADR on those grounds is violating protocol §1.
- **Immutability:** ADRs are immutable once Accepted. To change a decision, write a **new** ADR that supersedes the old one and record the relationship in both Dependencies tables. Never rewrite an approved ADR's decision.
- **Content:** rejected alternatives with the rationale for rejecting them are mandatory, as are tracked dependencies between ADRs.

### Format — enhanced WH(Y)

Every ADR uses this structure. `ADR-001` is the reference example.

```md
# ADR-NNN: {Short title of the decision}

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-NNN |
| **Initiative** | {the workstream this belongs to} |
| **Proposed By** | {author} |
| **Date** | YYYY-MM-DD |
| **Status** | Proposed \| Accepted \| Superseded by ADR-NNN |

## WH(Y) Decision Statement
**In the context of** {the situation and its scope},
**facing** {the concern or forcing function},
**we decided for** {the option selected},
**and neglected** {the options rejected},
**to achieve** {the benefit sought},
**accepting that** {the cost or downside knowingly taken on}.

## Context

{Prose. Why this decision is live now, what constraints bear on it.}

## Options Considered

### Option 1: {name} (Selected)
- **Pros:** …
- **Cons:** …

### Option 2: {name} (Rejected)
{Why it was rejected.}

## Dependencies

| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Enables / Depends on / Supersedes | ADR-NNN | … | … |

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-001 | … | … | … |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Accepted | … | YYYY-MM-DD |
```

The six WH(Y) clauses are the load-bearing part. An ADR that is a single paragraph does not meet this repo's bar.

## Spec convention (protocol §2)

- Every ADR that involves implementation details must have a spec in **`docs/adrs/specs/`**.
- Filename: `SPEC-{ADR-number}-{letter}-{Title}.md` — uppercase letter, title mirroring the ADR's, e.g. `SPEC-019-A-CI-Supply-Chain-Protection.md` implements `ADR-019-CI-Supply-Chain-Protection.md`. The letter allows several specs per ADR (`SPEC-003-A` … `SPEC-003-D`).
- Each spec must reference the ADR(s) it implements.
- ADRs are stable decision records; **specs are the living documents** and evolve with the implementation. Update the spec, not the ADR.

Note the name collision: `/to-spec` produces a *product* spec (a PRD) and publishes it to the issue tracker. That is a different artifact from a protocol §2 implementation spec. When work implements an ADR, the `docs/adrs/specs/` file is required regardless of whether a tracker PRD also exists.

## Use the glossary's vocabulary

When your output names a domain concept (an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

Until `CONTEXT.md` exists, take domain vocabulary from `CLAUDE.md`, `README.md`, and `docs/proposals/distributed-research-swarm-plan.md` — `goal`, `claim`, `sorry`, `Gate A` / `Gate B`, `swarm`, `decomposition`, `affinity` are established terms and should not be paraphrased.

If the concept you need isn't recorded anywhere yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-010 (affinity-gap selection) — but worth reopening because…_

Because ADRs here are immutable, "reopening" means proposing a superseding ADR, not editing the original.

## Other binding protocols worth knowing

These bite during ordinary skill work, so read `docs/protocols.md` before assuming a default:

- **TDD** (§3) — tests before implementation, red → green → refactor.
- **Feature branches** (§4) — `feature/`, `fix/`, `docs/`; one logical change per branch; no direct commits to `main`; branches deleted after merge.
- **Merge gates** — nothing merges without Gate A (soundness) and Gate B (hygiene) green. Paths in `.github/CODEOWNERS` additionally require human code-owner review (ADR-019).
- **Changelog** (§5) — Keep a Changelog + semver, with a GitHub release per tag. Fragments live in `changelog.d/`.
- **Production-ready code only** — no mocks or stubs in application code.
