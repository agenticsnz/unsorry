# ADR-006: Gate A Soundness Enforcement

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-006 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** Gate A — the CI trust boundary that makes untrusted contribution safe by re-verifying every PR against the Lean kernel and rejecting every escape hatch,
**facing** the facts (verified on Lean v4.30.0) that a plain `lake build` only *warns* on `sorry`, that `axiom` declarations and `native_decide` compile cleanly, and that source-level pattern matching is structurally bypassable via macros and metaprogramming,
**we decided for** a layered gate whose authoritative check is an axiom-footprint audit: (1) full `lake build` of both packages with `--wfail` on the verified library (converts the sorry warning into failure, fresh or replayed from Lake's cache); (2) `lake exe axiom_audit` — per-declaration transitive axiom collection via `Lean.collectAxioms`, failing on anything outside the whitelist {`propext`, `Classical.choice`, `Quot.sound`} (which uniformly catches `sorry`/`admit`/macro-hidden sorries as `sorryAx`, injected `axiom`s by name, and `native_decide` via its generated per-theorem axiom), with goals audited under whitelist ∪ {`sorryAx`}; (3) `lake env leanchecker` kernel-replay of the built environment to defeat metaprogramming that never appears in source; (4) a fast textual lint on the PR diff as a belt only,
**and neglected** grep-only enforcement, trusting `lake build` alone, and human review of proofs,
**to achieve** a soundness bar that holds against careless and adversarial contributors alike, with a per-proof axiom-footprint report for auditability,
**accepting that** Gate A costs a Lean toolchain in CI (minutes with the mathlib binary cache, kept structurally cheap by the ADR-002 release-tag pin), that `--wfail` is stricter than sorry alone (any warning fails the library — accepted as a quality bar), and that the whitelist must be revisited deliberately if the library ever legitimately needs another axiom (that change is itself a new ADR).

## Context

The project's entire safety argument is that the kernel, not goodwill, protects the library. That argument is only as strong as the CI policy that invokes the kernel: Lean deliberately compiles `sorry` (with a warning) so humans can iterate, axioms are a legitimate language feature, and `native_decide` trusts the compiler rather than the kernel. Each is a soundness escape hatch in an adversarial setting.

Sandbox verification on the pinned toolchain established the mechanics this decision relies on: `lake build --wfail` exits 1 on a sorried module on both fresh builds and cached-warning replays (exit 0 clean); `Lean.collectAxioms` reports `sorryAx` for sorried declarations, reports injected axioms for themselves and every dependent, and reports `native_decide` usage as a generated `<decl>._native.native_decide.ax_*` axiom — all outside the whitelist, all caught by one rule. `leanchecker` (in Lean core since v4.28) replays the compiled environment against the kernel, closing the gap where an environment is tampered with by metaprogramming without any source-level trace.

The two-package split (`UnsorryLibrary` with the zero-sorry bar, `UnsorryGoals` where statements legitimately carry `sorry`) exists so the gate can be absolute about the library without rejecting every new goal. Goals still may not smuggle axioms: they are audited with only `sorryAx` additionally allowed.

The whitelist {`propext`, `Classical.choice`, `Quot.sound`} is mathlib's standard axiom footprint. The audit reports every declaration's footprint regardless of pass/fail, as a CI artifact and PR comment, so reliance on classical choice (for example) is visible per proof, not just policy-permitted.

## Options Considered

### Option 1: Layered gate, axiom audit authoritative (Selected)
Pros: the authoritative check operates on the compiled environment, where macros and syntax tricks have already been erased — bypassing it requires defeating the kernel itself; one whitelist rule covers all known escape hatches uniformly; per-proof footprints are an auditability win. Cons: CI needs the Lean toolchain (mitigated by ADR-002's cache guarantee); four layers to keep in lockstep with CI job configuration.

### Option 2: Textual lint only (Rejected)
Grep for `sorry|admit|axiom|native_decide` is fast but structurally bypassable: macros, `sorryAx` term-level spellings, Unicode tricks, generated code. Kept only as a fast-fail belt; it can never be the bar.

### Option 3: Trust `lake build` alone (Rejected)
Verified false: a sorried library builds successfully with a warning, and axiom injection plus `native_decide` build with no warning at all.

### Option 4: Human proof review (Rejected)
Contradicts the design doc's contributor model (humans review naming/duplication, never correctness) and cannot outperform the kernel at the only question that matters.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-002 | Lean 4 + mathlib4 Pinned to Release Tags | The cache guarantee that makes per-PR builds affordable |
| Depends On | ADR-001 | Adopt Development Protocols | Process governing this decision |
| Relates To | ADR-005 | Autonomous Merge Policy | Gate A is the required check that policy leans on |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-006-A — Axiom Audit Executable | Specification | specs/SPEC-006-A-Axiom-Audit-Executable.md |
| REF-2 | SPEC-006-B — Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-3 | Design doc §Verification gates, §Soundness | Design document | ../proposals/distributed-research-swarm-plan.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
