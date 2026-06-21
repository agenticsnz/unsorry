# SPEC-063-A: Sharded Gate A Kernel Replay

Implements: [ADR-063](../ADR-063-Sharded-Gate-A-Kernel-Replay.md) · Status: Living · Updated: 2026-06-17

Shard the Gate A kernel replay across N parallel runners to cut the full-replay
long pole (#1909) without weakening the every-olean-replayed-once invariant
(ADR-048/049). Two deliverables ship now — the `plan`/`replay-shard` tooling and a
non-required `gate-a-shard-pilot` workflow — and the required-gate promotion is a
pilot-gated follow-up (§5).

## 1. The driver (`tools/gate_a/parallel_modules.py`)

The shard logic **reuses the existing scope machinery verbatim**; it adds three
small surfaces and changes none of `scoped_targets` / `replay_scope` /
`split_evenly` / the serial `replay` semantics.

- **`compute_replay_targets(root, base) -> (targets, mode)`** — the single source
  of truth for *what to replay*, factored out of `replay`:
  - `mode "full"` — `base is None`, or the diff is untrusted / global-impact
    (fail-closed: an unscopeable base yields the FULL set, never empty);
  - `mode "incremental"` — changed modules + reverse-import closure (ADR-033);
  - `mode "none"` — `base` given, no library module changed (empty).
  `plan`, `replay-shard`, and the serial `replay` all read it, so **a shard can
  never check a different set than a full replay would**.
- **`plan_shards(root, shards, base) -> {shards, count, mode}`** — emits the
  matrix index list `[0 … effective-1]` where `effective = min(shards,
  len(targets))`, plus `count = len(targets)`. `count == 0` ⇒ `shards == []`
  (empty matrix ⇒ matrix job skipped). CLI: `parallel_modules plan --shards N
  [--base B]` prints the JSON object.
- **`replay_shard(root, shard_index, shard_total, base) -> int`** — recomputes
  `targets` from source (same SHA ⇒ identical set), partitions with
  `split_evenly(targets, shard_total)`, and serially kernel-replays slice
  `shard_index` (the existing chunked `leanchecker` loop, one process at a time).
  Out-of-range index ⇒ no-op exit 0. CLI: `parallel_modules replay-shard
  --shard-index i --shard-total N [--base B]`.

**No module list crosses a job boundary** — each leg re-derives its slice from the
shared git SHA, so `leanchecker`'s inputs stay locally-derived (the ADR-049
invariant is preserved trivially).

## 2. The soundness invariant (must hold for every shard plan)

`split_evenly` produces **disjoint, covering** contiguous partitions of a
deterministically-`sorted` target list. Therefore, for a fixed SHA:

1. **Coverage:** `⋃ over i of split_evenly(targets, N)[i] == targets` — no module
   skipped.
2. **Exactly-once:** the slices are pairwise disjoint — no module replayed twice
   (and, with the cover assert, no gap hidden by overlap).
3. **Trusted inputs:** every shard rebuilds oleans on trusted CI and feeds
   `leanchecker` only local module names (no `download-artifact` into the gate).
4. **Same pinned toolchain:** all shards check out the same SHA and restore the
   same cache (ADR-002).
5. **Fail-closed:** an unscopeable base ⇒ the FULL set; a non-green shard ⇒ red.

Across all shards green, (1)+(2) give: **every olean kernel-replayed exactly
once** — the same guarantee a single serial replay gives.

## 3. Tests (unit, hermetic — `tools/gate_a/tests/test_parallel_modules.py`)

- **`test_shards_partition_covers_every_module_exactly_once`** — the invariant:
  run every shard, assert the slices are pairwise disjoint and their union is the
  full target set.
- **`test_shards_partition_covers_incremental_scope_exactly_once`** — same on the
  incremental path (the changed + reverse-import closure, nothing outside it).
- **`test_plan_shards_*`** — full plan; cap at module count (no empty shards);
  empty matrix on no library change; **fail-closed to full** on git failure and on
  a global-impact change.
- **`test_replay_shard_*`** — runs only its slice; out-of-range no-op; failure
  propagation; fail-closed-to-full on git failure.

The existing 23 replay/audit tests still pass — the `replay` refactor is
behaviour-preserving.

## 4. Pilot workflow (`gate-a-shard-pilot.yml`, NON-REQUIRED, manual)

`workflow_dispatch` only (inputs: `shards` default 8, optional `base`). Three
jobs:

1. **`plan`** (ubuntu) — `parallel_modules plan` (reads source + git only, no
   build); outputs `matrix` (the index array) and `count`.
2. **`replay`** (`namespace-profile-unsorry-1`, `if: count != '0'`,
   `strategy.matrix.shard: fromJSON(plan.matrix)`, `fail-fast: false`) — each leg
   restores the `.lake` cache, builds the library (`lean-action` + statement
   bindings + `lake build UnsorryLibrary --wfail`), and runs `replay-shard` for
   its index, with `UNSORRY_REPLAY_CHUNK=6`.
3. **`cover`** (`if: always()`) — passes when `count == 0`, else fails closed
   unless `needs.replay.result == 'success'` (with `fail-fast: false`, success ⟺
   every leg green ⟺ every module replayed once).

It gates nothing; it is the ADR-058-required real-runner validation before
promotion.

## 5. Promotion (landed — required `gate-a.yml`)

After the `gate-a-shard-pilot` validated the matrix on real runners, the required
`gate-a.yml` replay was promoted to the same three-job shape:

- **`gate_a_replay_plan`** (`ubuntu-latest`, `needs: [detect, gate_a_prepare]`) —
  runs `plan --shards ${{ vars.UNSORRY_REPLAY_SHARDS || 8 }} [--base BASE_SHA]`
  (the incremental BASE_SHA logic the serial replay used) and outputs `matrix`
  (the shard index list) + `count`.
- **`gate_a_replay`** (`needs: […, gate_a_replay_plan]`, `if: … && count != '0'`,
  `strategy.fail-fast: false`, `matrix.shard: fromJSON(plan.matrix)`) — each leg
  keeps the existing replay setup (Namespace volume / GitHub-cache restore of
  gate-a-prepare's oleans, the `--wfail` build skipped on the exact-sha cache hit)
  and runs `replay-shard --shard-index ${{ matrix.shard }} --shard-total N
  [--base BASE_SHA]`.
- **`gate_a_replay_cover`** (`if: always() && active`) — fails closed unless the
  plan succeeded **and** (`count == 0`, replay skipped → vacuous) **or** the
  replay matrix is `success` (every leg green). This is the single replay signal.

The aggregator `gate-a` adds the three jobs to `needs:` and reads
`gate_a_replay_cover.result` for the replay outcome; the required context name
`gate-a` is **unchanged** (ADR-058: do not rename required contexts). `N` is the
operator capacity knob `vars.UNSORRY_REPLAY_SHARDS` (default 8). The daily
`gate-a-full-replay` backstop is retained (and may itself shard later). The
`gate-a-shard-pilot` workflow stays as the ongoing experimentation surface.

## 6. Out of scope (fast-follow)

- Sharding `gate-a-audit` (already `--jobs`-parallel and order-independent; the
  cover job concatenates per-shard `axiom-report.json` fragments — same planner).
- Intra-runner `--jobs > 1` on a fat shard profile.
- Operator runner-pool scaling (ADR-058) — orthogonal capacity, not a repo change.
