# ADR-113: Multiple batches per dispatch pass, prefer batches over singletons (amends ADR-107)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-113 |
| **Initiative** | throughput / verifier amortisation (amends ADR-107; #6751 A1/A2) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-29 |
| **Status** | Proposed |

## Context

ADR-107 batch verification combines up to `UNSORRY_BATCH_SIZE` file-disjoint queued proofs into one
PR so Gate A pays its dominant ~12–20 GB mathlib env-load **once** for K proofs. But the dispatcher
opened **exactly one batch per pass** and then let `dispatch_queue` fill *every other* free Gate-A
slot with **1-proof singletons** (`agent.sh`: `dispatch_batch_pass` once, then `dispatch_queue`).

A live probe (2026-06-29, draining `@ohdearquant`'s un-stranded template flood) showed the cost:
of the proofs landing, ~30% came through singletons — each paying a **full mathlib env-load for a
single proof**, the exact waste batching exists to avoid. The branches were perfectly batchable
(pairwise file-disjoint); they were singletoned only because the dispatcher caps batches at one per
pass while singletons fill the rest. The binding constraint is the Gate-A in-flight cap
(`UNSORRY_MAX_GATE_A_IN_FLIGHT`, default 8); when those slots are held by singletons the batch pass
gets `batch: governor paused` and can't get a slot. This is exactly the deferred roadmap items
**A1** (multiple batches per pass) and **A2** (prefer batches over singletons) from #6751.

## Decision

**Open as many batch PRs as the gate budget allows BEFORE any singleton, each pass.** Loop
`dispatch_batch_pass` (new `dispatch_batch_passes`) until it stops opening batches — the submission
governor pauses (gate full) or fewer than 2 batchable branches remain — then `dispatch_queue`
singleton-dispatches only that `<2`-batchable remainder.

- `dispatch_batch_pass` sets a global `BATCH_DISPATCHED` (1 iff it opened a batch) so the loop knows
  when to stop, and accepts a **pass-scoped exclude file** of goals already batched this pass. That
  file is added to the dedup set each iteration so the loop never re-selects a goal whose
  just-opened batch PR is not yet visible to `dispatch_open_batch_goals` (GitHub read-after-write
  lag — the class of bug that bit batching before).
- A runaway backstop `UNSORRY_MAX_BATCHES_PER_PASS` (default 8) caps batches per pass even if the
  governor's gate-count read lags; the governor (re-checked every iteration) is the real limiter.
- Unchanged: soundness (reorder/repackage only — Gate A still verifies every proof from scratch),
  the governor caps, batch selection's file-disjointness + ADR-075/106 ordering, and the
  `UNSORRY_BATCH_SIZE=1` default (the loop is a no-op at size 1 — byte-for-byte the old singleton
  path).

## Consequences

- A homogeneous backlog drains almost entirely via K-proof batches: the per-slot env-load is
  amortised over K instead of spent per proof, multiplying realised throughput on the fixed Gate-A
  budget without raising the in-flight cap.
- Singletons are reserved for genuinely un-batchable work (a lone goal, or one whose siblings share
  a changed file), which is correct — there is nothing to amortise against.
- `swarm/agent.sh` is CODEOWNERS-gated → rides the code-owner review path (ADR-019). Reversible by
  `UNSORRY_BATCH_SIZE=1` (disables batching entirely) or `UNSORRY_MAX_BATCHES_PER_PASS=1` (restores
  the prior one-batch-per-pass behaviour).

## Alternatives considered

- **Raise `UNSORRY_MAX_GATE_A_IN_FLIGHT`.** Buys linear capacity ($), doesn't fix the amortisation
  waste — singletons would still squander the extra slots. Orthogonal.
- **Make the dispatcher fair-share / per-author aware before batching.** Larger; the loop + the
  governor already bound it, and ADR-109 handles per-contributor fairness.

REF: ADR-107 (batch verification, amended here), ADR-058 (governor), ADR-075/106 (dispatch order),
ADR-071 (fresh re-check), ADR-019 (gated tooling), #6751 (roadmap A1/A2). Implemented in
`swarm/agent.sh` (`dispatch_batch_pass`, `dispatch_batch_passes`). See
[SPEC-113-A](specs/SPEC-113-A-Multiple-Batches-Per-Dispatch-Pass.md).
