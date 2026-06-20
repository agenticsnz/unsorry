# SPEC-076-A: Sharded Fork Goal Selection

Implements: [ADR-076](../ADR-076-Sharded-Fork-Goal-Selection.md) · Status: Living · Updated: 2026-06-20

Phase-2 **step 2c** (SPEC-053-A §8.3): a claimless, coordination-free reorder of
the fork prover's ranked candidate list so independent forks prefer different
goals. Everything not restated here is unchanged from SPEC-007-A / SPEC-068-A.

## 1. Scope

Active **only when `FORK_MODE=1`**. The canonical (write-access) selection path is
byte-for-byte unchanged. Advisory: it reorders equal-priority candidates; it never
filters, never blocks, and is never a correctness input (the kernel, first-merge-
wins, and the #3164 goal lock remain the backstops).

## 2. Shard function

```
fork_shard <string> <K>  ->  cksum(<string>) mod K       # 0 .. K-1
```

`cksum` (CRC-32) is deterministic and portable (Linux + macOS), so every machine
computes the **same** shard for a given string — that cross-machine stability is
what lets two uncoordinated forks prefer disjoint slices. `K = UNSORRY_FORK_SHARDS`
(default **8**); a non-positive-integer value falls back to the default.

## 3. Reorder

```
shard_reorder <agent_id> <K>            # ranked candidates on stdin, reordered on stdout
```

- `mine = fork_shard(agent_id, K)`.
- Emit, **in input (rank) order**: first every candidate with
  `fork_shard(goal, K) == mine`, then every remaining candidate.
- Stable within each group, so the ADR-010 affinity/gap priority is preserved
  inside a shard and across the fall-through tail. Pure (a function of stdin +
  args), so it is hermetically unit-tested.

## 4. Wiring

`select_prove_candidates` and `select_recovery_candidates` pipe their
scope/HANDLED-filtered output through:

```
fork_maybe_shard      # FORK_MODE=1 -> shard_reorder "$AGENT_ID" "$K" ; else cat
```

`AGENT_ID` is the distinct per-runner identity already resolved before selection
(`claim_agent_identity`, #3140) — it differs between independent forks and between
co-located runners, which is exactly the divergence key. `claim_from_pool` consumes
the reordered list unchanged, so the goal lock (#3164) and the open-PR / queued
dedup are untouched.

## 5. Environment

| Variable | Default | Purpose |
|---|---|---|
| `UNSORRY_FORK_SHARDS` | `8` | Number of shards `K`. Larger ⇒ finer slices (lower same-shard probability `1/K`) but more fall-through when a slice is dry. Non-positive-integer ⇒ default. |

## 6. Quality bar

- `shellcheck` / `bash -n` clean.
- Hermetic self-tests: `test_fork_shard` (deterministic, in `0..K-1`, default-on
  bad `K`) and `test_shard_reorder` (in-shard goals first, rank order preserved
  within each group, fall-through tail present, empty input safe). The existing
  `test_fork_goal_lock` and canonical selection tests stay green.

## 7. Out of scope

- The fork-writable **lease** (SPEC-053-A §8.4) — the heavier mechanism that would
  *eliminate* (not just reduce) cross-fork collisions, still gated on the ADR-070
  metric.
- Adaptive `K` from the live fork count.
- Identity/quota policy (SPEC-054-A §7).
