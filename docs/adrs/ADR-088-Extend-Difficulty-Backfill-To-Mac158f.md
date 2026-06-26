# ADR-088: Extend the Honest-Difficulty Backfill to mac-158f Template Goals

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-088 |
| **Initiative** | corpus & attribution integrity |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-23 |
| **Status** | Accepted |

## Context

[ADR-087](ADR-087-Backfill-Historical-Seedkit-Records.md) corrected seedkit's
inflated goal difficulty to the honest `1`, and its Consequences flagged a
**discovered, out-of-scope** parallel: ~306 `gzmod-` goals (and, on closer
inspection, **~493 in total** across `gzmod`, `sum`, `dvd`, `gbinom`, `sq`, … )
are proved by the **separate** `mac-158f` pipeline — ohdearquant's deterministic
Python/sympy template engine ([ADR-079](ADR-079-Deterministic-Solver-Provider.md))
— and were equally self-tagged at difficulty 3–5.

This left a **cross-prover inconsistency**: two `gzmod` divisibility goals of
identical triviality sit at difficulty `1` (proved by seedkit) versus `3` (proved
by mac-158f), differing only by *who* proved them. Difficulty is meant to reflect
a goal's hardness, not the prover's identity — and by ADR-086's principle, a goal
closed by a deterministic template (Lean `decide`/`ring` **or** a sympy template)
is trivial.

mac-158f's **provenance is already honest** — the existing relabel sweep's ADR-079
rule records it as `provider≜python; model≜sympy`. Only its goal *difficulty* is
inflated. The maintainer asked to extend the same correction to mac-158f,
accepting that it lowers ohdearquant's difficulty-weighted standing.

## WH(Y) Decision Statement

**In the context of** ADR-087 correcting seedkit's difficulty while leaving
ohdearquant's ~493 equally-trivial `mac-158f` template goals at inflated `2–5` — a
cross-prover inconsistency where an identical-triviality goal's difficulty depends
on which deterministic pipeline proved it,

**facing** the principle (ADR-086) that difficulty must reflect goal hardness, not
prover identity; `mac-158f` being a deterministic Python/sympy template engine
(ADR-079) whose proofs are template-closeable and therefore difficulty `1`; and
the maintainer's decision to extend the same correction, accepting that it lowers
ohdearquant's `difficulty_points` and score on a public board,

**we decided for** widening the difficulty backfill's fixture identification from
seedkit-only to **any deterministic-template proof** — adding `mac-158f`
(`agent≜mac-158f` with a `template-*` model or the relabelled `provider≜python;
model≜sympy`, with genuine LLM proofs under that agent excluded) via an
`index_is_mac158f` predicate unioned with `index_is_seedkit` into
`index_is_template_fixture` — and correcting those goals to `difficulty≜1`,
**reusing ADR-087's exact mechanism**: provenance-driven identification,
idempotent and self-healing, `solver≜` credit never changed, and **no provenance
rewrite** for mac-158f (the ADR-079 sweep already records it honestly),

**and neglected** leaving the inconsistency (rejected — difficulty would stay
prover-dependent, the dishonesty ADR-086 set out to remove); touching mac-158f
*provenance* (unnecessary — already `python/sympy`); and a separate one-shot
migration (rejected — same live-corpus reasoning as ADR-079/087: only an
idempotent sweep survives).

## What this changes (full contract in SPEC-088-A)

- `tools/repo/relabel_attribution.py`: add `index_is_mac158f` and
  `index_is_template_fixture` (= seedkit ∪ mac-158f); Pass B's difficulty
  collection uses the union. No `_RULES` (provenance) change.
- First-run effect: the difficulty backfill grows from ~561 (seedkit) to **~1,063
  goal records** (seedkit + mac-158f); provenance relabel is unchanged in kind.
- Tests for `index_is_mac158f`, the union, and a mac-158f end-to-end correction.

## Consequences

- **Positive.** Difficulty is now consistent across provers — identical-triviality
  template goals carry the same honest difficulty `1` regardless of who proved
  them.
- **Positive.** Reuses ADR-087's idempotent, `solver≜`-neutral mechanism; no new
  tool, no provenance churn for mac-158f, no CODEOWNERS surface.
- **Negative — owned.** ohdearquant's `difficulty_points` and score **drop
  retroactively** (~493 goals). This is the honest correction the maintainer
  approved; announced in the changelog so the board movement is not read as a bug.
- **Negative.** Larger one-time settling churn (~1,063 goal records total on the
  first sweep), converging to a no-op thereafter.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | mac-158f difficulty-extension spec | Specification | specs/SPEC-088-A-Extend-Difficulty-Backfill-To-Mac158f.md |
| REF-2 | Backfill Historical seedkit Records | Decision | ADR-087-Backfill-Historical-Seedkit-Records.md |
| REF-3 | seedkit Fixture-Generation Path | Decision | ADR-086-Seedkit-Fixture-Generation-Path.md |
| REF-4 | Deterministic Solver Provider (mac-158f = python/sympy) | Decision | ADR-079-Deterministic-Solver-Provider.md |
| REF-5 | Optional Proof Provenance and Leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Chris Barlow | 2026-06-23 |
| Accepted (implemented with SPEC-088-A in the same change) | Chris Barlow | 2026-06-23 |
