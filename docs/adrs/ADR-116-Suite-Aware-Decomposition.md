# ADR-116: Suite-Aware Decomposition (Sub-Lemmas Inherit the Benchmark Pin)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-116 |
| **Initiative** | unsorry swarm reliability — benchmark decomposition |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-07-01 |
| **Status** | Proposed |

> **Design-only ADR.** This records the decision and its spec (SPEC-116-A) for review. No
> behaviour ships with this PR; implementation follows in a separate PR once the design is
> signed off.

## Context

A **benchmark obligation** (ADR-099) is proved in its suite's isolated `_verify` lake project,
pinned to the suite's *own* toolchain and mathlib rev — not the repo-wide pin. For `minif2f-v1`
that pin is `lean4:v4.24.0` + mathlib `f897ebcf…`; the repo is `lean4:v4.30.0` + mathlib
`c5ea0035…`. `suite_context_for_goal` (`tools.intake.suite_context`) resolves a goal to that
context iff it is the suite `top` or appears in the suite `skeleton.aisp` `⟦Σ⟧` obligation list;
`run_proof`/`check_in_proof` then route the proof module to `targets/<suite>/_verify/library/
Unsorry/<Camel>.lean` and verify it at the suite pin.

The ADR-009 **decompose-on-failure** fallback is *not* suite-aware. When a benchmark obligation's
direct prove is exhausted, decompose fires and mints the sub-lemmas as **plain repo goals**
(`goals/<parent>-sN`), which are proved into the *repo* library against the *repo* pin. The
benchmark parent can then never recompose them: the suite `_verify` package cannot see the repo
library, and — decisively — the sub-proofs were built on a *different Lean and mathlib*, so they
would not even compile at the suite pin. Every recompose attempt writes to a forbidden path
(`prove_target_only_changed` only admits the suite-pin parent module) and fails; ADR-115 then
retries a recompose that can never succeed.

Observed: `aime-1983-p9` (a minif2f-v1 obligation) decomposed into `-s1/-s2/-s3`, all proved into
the repo library, and the parent has been stuck in a recompose→floor→retry loop ever since.

A tempting fix — register the sub-lemmas as suite obligations so they prove at the pin — is wrong:
the `skeleton.aisp` obligation set is the *curated, native-pinned* benchmark (ADR-110), counted by
the leaderboard. Injecting agent-invented sub-lemmas would corrupt the benchmark's meaning (the
"244 minif2f obligations" would include decomposition artifacts). Equally, *staging* the
repo-pinned sub-modules into the suite `_verify` library is unsound — different toolchain + mathlib.

## WH(Y) Decision Statement

**In the context of** ADR-099 benchmark obligations that prove at a suite-specific toolchain+mathlib
pin and the ADR-009 decompose-on-failure fallback that mints sub-lemmas and proves them,
**facing** the fact that decompose is not suite-aware — it mints a benchmark obligation's sub-lemmas
as repo goals proved at the *repo* pin, which the benchmark parent can never recompose (the suite
package can't see the repo library, and the sub-proofs were built on a different Lean+mathlib so they
wouldn't compile at the suite pin), leaving the parent permanently stuck (observed: `aime-1983-p9`),
**we decided for** making a decomposition sub-goal **inherit its parent's suite verifier context via
the decomposition graph** — `suite_context_for_goal` resolves a goal to a suite if it is the `top`, a
skeleton obligation, **or a decomposition-descendant of one** — so the sub proves at the suite pin
(correct toolchain+mathlib) and its module stages into `targets/<suite>/_verify/library/Unsorry/` as a
**suite-local helper**, importable by the parent recompose and kernel-verified by `gate-a-benchmark`'s
whole-library build, while `proved-deps` for a benchmark recompose reads the suite library,
**and neglected** registering subs in `skeleton.aisp` as obligations (pollutes the curated benchmark
and the leaderboard count), staging repo-pinned modules into the suite pin (unsound across
toolchain+mathlib), and forbidding benchmark decomposition (loses decomposition as a tool for hard
benchmark problems),
**to achieve** a benchmark obligation whose sub-lemmas are proved at the *same* pin as the parent, so
recompose is possible and Gate-A-consistent, without altering the curated obligation set,
**accepting that** sub-lemmas proved at the repo pin *before* this change (e.g. `aime-1983-p9`'s) are
unusable at the suite pin and require a one-time re-open + re-prove migration, that a helper module
lives in the suite `_verify` library without being a counted obligation (so `gate-a-benchmark` must
verify the whole suite library, not only registered obligations — confirmed during implementation),
and that decomposition depth stays bounded by the existing ADR-009 cap.

## Options Considered

### Option 1: Sub-goals inherit the parent's suite pin via the decomposition graph (Selected)
`suite_context_for_goal` resolves decomposition-descendants of an obligation to the obligation's
suite; subs prove at the pin and stage as suite-local helpers; `proved-deps` reads the suite
library. **Pros:** sound (same pin as parent), no benchmark/leaderboard pollution, reuses the
existing suite-pin prove/stage plumbing, organic goals byte-identical. **Cons:** requires a one-time
migration of already-repo-proved subs; helper modules live in the suite lib without being obligations.

### Option 2: Register sub-lemmas as suite obligations (Rejected)
Add subs to `skeleton.aisp` `⟦Σ⟧`. **Rejected:** corrupts the curated native-pinned benchmark
(ADR-110) and inflates the leaderboard's obligation count with agent-invented lemmas.

### Option 3: Stage the repo-proved sub-modules into the suite pin (Rejected)
Copy `library/Unsorry/<Sub>.lean` into `targets/<suite>/_verify/library/`. **Rejected:** the subs
were built on a different toolchain + mathlib rev; they may not compile at the suite pin, and a proof
that is not itself verified at the pin is not sound benchmark evidence.

### Option 4: Forbid decomposing benchmark obligations (Rejected)
Guard decompose-on-failure to skip suite goals. **Rejected here** (it is the safe *fallback* if
Option 1 proves infeasible): sound and minimal, but abandons decomposition for benchmark problems a
model cannot prove whole — the exact case decomposition exists for.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Refines | ADR-009 | Goal Decomposition | Makes decompose/recompose suite-aware |
| Refines | ADR-099 | Suite-Pin Benchmark Verification | Sub-lemmas inherit the obligation's pin |
| Relates To | ADR-110 | Native-Pin Benchmark Ingestion | Must NOT mutate the curated `skeleton.aisp` obligation set |
| Relates To | ADR-115 | Recompose Self-Retry | Its retry becomes productive for benchmark recompose once assembly is possible |
| Relates To | ADR-010 | Affinity-Gap Selection | Unchanged; helper subs rank like ordinary goals |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Suite-aware decomposition spec | Specification | specs/SPEC-116-A-Suite-Aware-Decomposition.md |
| REF-2 | Per-suite mathlib pin for benchmark ingestion | ADR | ADR-099-Per-Suite-Mathlib-Pin-For-Benchmark-Ingestion.md |
| REF-3 | Stuck benchmark recompose (motivating case) | Issue | <https://github.com/agenticsnz/unsorry/issues/388> |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-07-01 |
