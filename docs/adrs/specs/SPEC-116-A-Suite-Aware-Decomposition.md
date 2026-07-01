# SPEC-116-A: Suite-Aware Decomposition

Implements: [ADR-116](../ADR-116-Suite-Aware-Decomposition.md) · Status: Proposed · Updated: 2026-07-01

> **Design-only.** Describes the behaviour to build; no code ships with the ADR PR.

## Behaviour

A decomposition sub-goal of a **benchmark obligation** inherits the obligation's **suite verifier
context** (toolchain, mathlib rev, `_verify` dir, build target). Consequently:

1. The sub-goal is **proved at the suite pin** (correct toolchain + mathlib), and its module is
   staged into `targets/<suite>/_verify/library/Unsorry/<Camel>.lean` — a **suite-local helper**,
   kernel-verified by `gate-a-benchmark`'s whole-library build.
2. The sub-goal is **not** added to the suite `skeleton.aisp` `⟦Σ⟧` obligation set, so the curated
   benchmark and its leaderboard obligation count (ADR-110) are unchanged.
3. When the parent obligation is recomposed, `proved-deps` finds the proved sub-modules in the
   **suite** library, surfaces them to the model, and the parent assembles + verifies at the pin.

An **organic** (non-benchmark) goal's decomposition is byte-identical to today (empty suite context →
repo-pin path throughout).

## Components

### `tools/intake/suite_context.py` — `goal_suite_context(root, goal)`
Extend membership from `{top} ∪ obligations` to also include **decomposition-descendants of an
obligation**:
- Build the sub → parent map from the decomposition records (`decompositions/*.aisp`,
  `⟦Σ:Subs⟧` ids), the same graph `tools.gate_b.graph` already parses.
- A goal resolves to suite *S* if walking the sub→parent chain reaches an *S* obligation or the *S*
  `top`. The walk is bounded by the ADR-009 decomposition depth cap (no cycles: decompose is
  idempotent and append-only).
- Return the *inherited* context (the obligation's toolchain/mathlib/`verify_dir`/`build_target`) —
  identical fields to a direct obligation, so `run_proof`/`check_in_proof` need no change.
- Descendants of no obligation still resolve to `None` (organic path unchanged).
- New unit tests: a sub of an obligation resolves to the suite; a sub-of-a-sub resolves; an organic
  sub resolves to `None`; a sub is **not** reported as an obligation by the leaderboard's counter.

### `proved-deps` (embedded py in `swarm/agent.sh`)
`run_proof` currently calls `proved-deps … "$prwt/library" …` (repo library). Make it
suite-context-aware: when `suite_context_for_goal "$goal"` is non-empty, pass the **suite** library
(`<vdir>/library`) as the `library_dir`, so a benchmark recompose finds its sub-modules and index
entries where they actually live. Organic goals keep `$prwt/library`.
- New self-test: `proved-deps` for a benchmark recompose surfaces subs from the suite library; an
  organic recompose still reads the repo library.

### `decompose_goal` (`swarm/agent.sh`)
No routing change required for statements: subs are minted as goal *statements* under `goals/`
(source of truth) as today; their *proof* routing is decided at prove time by the inherited suite
context. The decomposition record already links sub → parent, which is the inheritance edge.
- Confirm the decompose PR does not need to touch `targets/<suite>/` (it does not — only the prove
  step stages into the suite library).

### `gate-a-benchmark` (verification — to confirm, not necessarily change)
Confirm the suite `_verify` build compiles the **whole** `Minif2fV1` lib (`globs = ["Unsorry.+"]`),
so helper sub-modules are kernel-verified and not rejected as unexpected. If it instead verifies
only registered obligations, the design gains a step: mark helper modules for inclusion. **This is
the one open assumption to validate first in implementation.**

## Migration (one-time, for goals decomposed before this change)

`aime-1983-p9` (and any other benchmark obligation already decomposed into repo goals) has sub-lemmas
proved at the **repo** pin, unusable at the suite pin. Per goal:
1. Re-open the sub-goals (`status≜open`, clear the proved `sha`) so the swarm re-proves them.
2. Remove their repo-library modules + index entries (`library/Unsorry/<Sub>.lean`,
   `library/index/<sha>.aisp`) so `proved` no longer resolves to the repo pin.
3. With ADR-116 in effect, the swarm re-proves them at the suite pin (they are trivial), then the
   parent recomposes.
A small migration script (or a documented manual sequence) performs this; it is **not** part of the
mechanism and runs once.

## Properties

- **No benchmark pollution.** The curated `skeleton.aisp` obligation set — and the leaderboard count
  — are never mutated by decomposition. Helpers are library modules, not obligations.
- **Sound.** A sub-lemma used to recompose a benchmark parent is itself kernel-verified at the *same*
  toolchain + mathlib pin as the parent (no cross-pin reuse).
- **Reuses existing plumbing.** Once a sub has suite context, the existing ADR-099 prove/stage path
  (`run_proof` target, `check_in_proof` staging, path policy) handles it unchanged.
- **Organic-goal invariant.** Non-benchmark decomposition is byte-identical (empty context).
- **Bounded.** Inheritance resolution walks the decomposition graph within the ADR-009 depth cap.

## Test Plan (implementation PR)

- `tools/intake/tests/test_suite_context.py`: obligation-descendant inheritance (direct sub,
  sub-of-sub), organic sub → None, leaderboard counter excludes helpers.
- `swarm/agent.sh --self-test`: `proved-deps` reads the suite library under a benchmark context and
  the repo library otherwise.
- End-to-end (manual, on the box): after migration, `aime-1983-p9`'s subs re-prove at the pin and the
  parent recomposes and passes `gate-a-benchmark`.
