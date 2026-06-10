# ADR-001: Adopt Development Protocols

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-001 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** building unsorry — a distributed swarm of autonomous AI agents producing kernel-verified Lean 4 proofs — from a pre-Phase-0 repository up to its Gate A contributor-readiness milestone,
**facing** the need for every decision and change to be auditable and machine-checkable before untrusted public contributors are invited into a project whose entire safety argument is "machine-checked gates, not goodwill",
**we decided for** adopting the cgbarlow development protocols, vendored verbatim at `docs/protocols.md`, as binding for all unsorry development (core protocols 1–12; optional protocol 13 does not apply),
**and neglected** an ad-hoc process, a bespoke process invented for this project, and heavyweight enterprise frameworks such as TOGAF-style governance,
**to achieve** a complete paper trail for every significant decision (ADRs), living implementation detail (specs), test-first correctness discipline (TDD), reviewable change history (feature branches, no direct commits to main), traceable releases (Keep a Changelog, semver, tagged GitHub releases), and a README that tracks reality — all in place before strangers arrive,
**accepting that** every change, however small, carries process overhead (branch, PR, ADR, spec, changelog), and that the vendored protocol copy can drift from its upstream source and must be re-vendored deliberately.

## Context

unsorry is a self-coordinating research swarm for formal mathematics: autonomous agents claim open goals (Lean statements carrying a `sorry`), attempt proofs, verify them locally against the Lean kernel, and merge them into a shared machine-verified library with no human in the correctness path. The design (see `docs/proposals/distributed-research-swarm-plan.md`) rests on three commitments: the kernel is the only truth oracle, the repository is the only infrastructure, and coordination artifacts are machine-validated rather than prose.

At the time of this decision the repository is pre-Phase-0 — it consists of two markdown files, the README and the design proposal. It is being built up to its Gate A contributor-readiness milestone, after which untrusted public contributors (human and agent alike) are invited to claim goals and open pull requests, with CI gates rather than human review deciding what merges.

A project that asks contributors to trust machine-checked gates rather than maintainer goodwill cannot credibly govern its own construction by informal habit. The same trust-through-verification ethos that shapes the swarm architecture applies to the development of the swarm itself: decisions must be recorded, alternatives must be visible, changes must arrive through reviewable branches, and releases must be versioned and traceable. Adopting an established, written protocol set gives every decision a paper trail before the first stranger arrives.

The protocols adopted are the cgbarlow development protocols, vendored verbatim at `docs/protocols.md`. Core protocols 1–12 are binding: ADRs for every significant decision (in this format), a spec for every implementation ADR, TDD, feature branches with no direct commits to main, Keep-a-Changelog plus semantic versioning plus tagged GitHub releases, Context7 for language research, production-ready code only (no mocks or stubs in application code), Claude agent teams for parallelisable work, latest stable dependencies, README accuracy, and DRY. The README currently says "pre-Phase-0" honestly; protocol 11 obliges it to keep tracking reality as phases land. Optional protocol 13 (Svelte `{@html}` security) is conditional on the project using Svelte; unsorry contains no Svelte, so it does not apply.

## Options Considered

### Option 1: Adopt the cgbarlow development protocols, vendored verbatim (Selected)
- **Pros:** A proven, already-documented protocol set the maintainer uses across projects; adopting it is DRY applied to process. Provides ADR, spec, TDD, branching, changelog, and release discipline as a coherent whole rather than piecemeal. Vendoring the text into the repository makes the binding rules self-contained and auditable by any contributor without following external links. The protocols are written to be checkable (ADR presence, branch naming, changelog format, test coverage), matching the project's machine-checkable-gates ethos.
- **Cons:** Process overhead on every change, including trivial ones. The vendored copy is a snapshot and can drift from upstream; keeping it current requires deliberate re-vendoring.

### Option 2: Ad-hoc process (Rejected)
No written process; the maintainers commit as convenient and document when it seems worthwhile. Rejected because it leaves no decision trail — exactly the audit gap that becomes untenable once untrusted contributors arrive — and because it directly contradicts the project's own trust-through-verification ethos. A project arguing that goodwill is insufficient for proof contributions cannot rely on goodwill for its own governance.

### Option 3: Invent a bespoke process for this project (Rejected)
Write a new, unsorry-specific development process from scratch. Rejected because it duplicates a proven, already-documented protocol set with no offsetting benefit — a violation of DRY applied to process. The effort of authoring, debugging, and socialising a novel process is better spent on the swarm itself.

### Option 4: Heavyweight enterprise framework (Rejected)
Adopt a formal enterprise architecture governance framework (TOGAF-style architecture boards, formal review cycles, stage gates). Rejected because the ceremony would slow a fast-moving pre-1.0 project out of proportion to its risk profile. The vendored protocols deliver the auditability that matters (decision records, reviewable changes, versioned releases) without standing committees or multi-stage approval queues.

## Dependencies

| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Enables | ADR-002 | Lean 4 + mathlib4 Pinned to Release Tags | Dependency-management decision made under these protocols |
| Enables | ADR-003 | AISP Coordination Format with In-Repo Validation | Coordination-format decision made under these protocols |
| Enables | ADR-004 | Claims on a Dedicated Branch, First-Push-Wins | Claim-mechanism decision made under these protocols |
| Enables | ADR-005 | Autonomous Merge Policy | Merge-policy decision made under these protocols |

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-001 | Distributed Autonomous Research Swarm: Architecture and Plan | Design document | `docs/proposals/distributed-research-swarm-plan.md` |
| REF-002 | Development Protocols (vendored verbatim) | Protocol set | `docs/protocols.md` |
| REF-003 | Keep a Changelog | External standard | <https://keepachangelog.com/> |
| REF-004 | Semantic Versioning | External standard | <https://semver.org/> |

This ADR is a process decision and carries no implementation of its own; per protocol 2, specs accompany implementation ADRs, and each such spec lands with its implementation PR.

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
