# ADR-076: Sharded Fork Goal Selection

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-076 |
| **Initiative** | volunteer-scale orchestration / Phase-2 step 2c |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-20 |
| **Status** | Proposed |

## Context

ADR-068 fork-native proving is **claimless** with a fully deterministic
`_rank()` (ADR-010), so every fork prover independently picks the identical
top-ranked goal and grinds it in parallel. #3164 added a per-machine **goal lock**
that fixes this for **co-located** provers (same host + user — the lock dir keys
off `$HOME`). But two **independent forks on different machines** share no lock,
so they still both select the same top goal — the cross-fork duplication the
ADR-070 metric is there to catch.

SPEC-053-A §8.3 already names the mitigation: **sharded fork selection** — Phase-2
step 2c, a *claimless, coordination-free* way to make different forks prefer
different goals. The lease (§8.4) is the heavier, operational alternative, still
gated on the metric; sharding needs no shared substrate at all, so it is the
right first cross-fork mitigation to land preemptively — before a second
independent fork contributor appears.

## WH(Y) Decision Statement

**In the context of** claimless fork proving with deterministic ranking, where
#3164's goal lock only coordinates co-located same-host provers and leaves
independent cross-fork provers to all pick the same top-ranked goal and duplicate
verifier work,

**facing** the need to reduce cross-fork collisions **without any shared
coordination substrate** (a lease is Phase-2 §8.4, still evidence-gated; forks on
different machines cannot share a lock), while never starving a goal (a fork whose
preferred slice is dry must still work the rest of the pool),

**we decided for** **deterministic goal-space sharding keyed on agent identity**:
each fork prover computes `shard = cksum(AGENT_ID) mod K`
(`K = UNSORRY_FORK_SHARDS`, default 8) and **reorders** its ranked candidate list
to prefer goals whose own `cksum(goal) mod K` matches its shard, **falling through**
to every other goal in rank order when its slice is dry; it is **advisory only**
(`FORK_MODE`-gated, never a correctness input — the kernel, first-merge-wins, and
the #3164 goal lock remain the backstops) and **fully claimless / coordination-
free**, so two forks on different machines compute the same stable map and prefer
disjoint slices with no round-trip,

**and neglected** a shared lease/lock for cross-fork (rejected here — that is
Phase-2 §8.4, an operational dependency the ADR-070 metric has not yet justified;
sharding is the zero-infra mitigation), **hard** partitioning where a fork works
*only* its shard (rejected — it starves goals when a fork's slice is empty and
idles a willing prover; soft preference + fall-through keeps the whole pool
worked), randomising selection per cycle (rejected — non-deterministic selection
breaks reproducibility and discards the affinity/gap priority `_rank` encodes; a
stable identity→shard map preserves rank order *within* each shard), and keying
the shard on anything other than identity (rejected — identity is exactly what
differs between independent forks, and between co-located runners post-#3140, so
it is the natural divergence key),

**to achieve** a preemptive, zero-coordination reduction in cross-fork duplicate
proving — so a second independent fork contributor mostly prefers disjoint goals
— composing with #3164 (the co-located lock) and first-merge-wins, without
building the Phase-2 lease,

**accepting that** sharding **reduces, never eliminates** collisions (two forks in
the same shard, or one that has fallen through its dry slice, can still collide —
first-merge-wins and the metric handle the residue), that it changes which goal a
fork *prefers* (an intentional advisory reorder of equal-priority work, not a
correctness change), and that `K` is a static knob rather than adaptive to the
live fork count (a future refinement — the metric shows ≈1 active fork today, so a
fixed default suffices).

## What it does (summary; full contract in SPEC-076-A)

In fork mode only, after `select_prove_candidates` / `select_recovery_candidates`
produce the ranked, scope/HANDLED-filtered list, the list is reordered:
goals in this agent's shard first (in rank order), then the rest (in rank order).
`claim_from_pool` then walks the reordered list exactly as before, so the #3164
goal lock and the open-PR/queued dedup are unchanged. Non-fork selection is
byte-for-byte untouched.

## Consequences

- **Positive.** Independent forks mostly prefer disjoint goals with **no shared
  infrastructure** — the cheapest cross-fork mitigation, landed before it's
  acutely needed.
- **Positive.** Composes with #3164 (co-located lock) and first-merge-wins;
  preserves the ADR-010 rank order within each shard; default-on in fork mode,
  inert (and unchanged) on the canonical path.
- **Negative.** Probabilistic — same-shard forks still collide (~`1/K`), and
  fall-through re-introduces overlap when a slice is dry; the residue is what the
  Phase-2 lease (§8.4) would remove if the metric ever justifies it.
- **Negative.** `K` is static, not adaptive to the live fork population.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Sharded fork goal selection spec | Specification | specs/SPEC-076-A-Sharded-Fork-Goal-Selection.md |
| REF-2 | Fork-Native Contribution Mode | Decision | ADR-068-Fork-Native-Contribution-Mode.md |
| REF-3 | Volunteer-Scale Claim Substrate (SPEC-053-A §8.3, the prior framing) | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-4 | Duplicate-Verifier-Waste Metric (the gate) | Decision | ADR-070-Duplicate-Verifier-Waste-Metric.md |
| REF-5 | Affinity-Gap Selection (the ranking preserved within shards) | Decision | ADR-010-Affinity-Gap-Selection.md |
| REF-6 | Fork-local goal lock (co-located coordination it composes with) | PR | https://github.com/agenticsnz/unsorry/pull/3164 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-20 |
