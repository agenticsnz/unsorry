# SPEC-113-A: multiple batches per dispatch pass

Implements: [ADR-113](../ADR-113-Multiple-Batches-Per-Dispatch-Pass.md) · amends ADR-107 · Status:
Draft · Updated: 2026-06-29

Contract for the A1/A2 batch loop in `swarm/agent.sh`. Self-tested via `--self-test`.

## 1. `dispatch_batch_pass [pass_exclude_file]`

- Sets global `BATCH_DISPATCHED` = `1` iff it opened a batch PR this call, else `0` (first line, so
  it is always defined on return).
- Optional `$1` = a file of goals already batched THIS pass. Its contents are unioned into the
  selection exclude set alongside `dispatch_open_pr_goals` and `dispatch_open_batch_goals`.
- On a successful `assemble_and_dispatch_batch`, appends the dispatched goals to `$1` (when given).
- Otherwise unchanged from ADR-107: gated on `UNSORRY_BATCH_SIZE>1`; governor-paused / `<2`
  batchable / assembly-failed all return 0 with `BATCH_DISPATCHED=0` so singleton dispatch proceeds.

## 2. `dispatch_batch_passes`

- No-op (return 0) when `UNSORRY_BATCH_SIZE <= 1`.
- Creates one pass-scoped temp exclude file, then loops: `dispatch_batch_pass <file>`; **break** when
  `BATCH_DISPATCHED != 1` (governor paused or `<2` batchable) or after
  `UNSORRY_MAX_BATCHES_PER_PASS` (default 8, validated `>=1`) iterations. Removes the temp file.
- Invariants: monotonic progress (each successful iteration appends its goals to the exclude, so the
  same goal is never re-selected within the pass); bounded (governor re-checked every iteration is
  the real limiter, the cap is a runaway backstop); fail-open (a `dispatch_batch_pass` that opens
  nothing simply ends the loop and yields to `dispatch_queue`).

## 3. Main dispatch flow

`main()` `--dispatch-queue` loop calls `dispatch_batch_passes` (replacing the single
`[ BATCH_SIZE>1 ] && dispatch_batch_pass`) **before** `dispatch_queue`. So batches claim every
free Gate-A slot first; singletons handle only the `<2`-batchable remainder.

## 4. Tests (`swarm/agent.sh --self-test`)

- `test_dispatch_batch_loop_multiple`: 3 successful batches then stop ⇒ exactly 4 calls.
- `test_dispatch_batch_loop_caps`: always-succeeds ⇒ stops at `UNSORRY_MAX_BATCHES_PER_PASS`.
- `test_dispatch_batch_loop_disabled_at_size_one`: `UNSORRY_BATCH_SIZE=1` ⇒ 0 calls.

## 5. Out of scope / invariants preserved

No change to soundness (Gate A re-verifies every proof), batch selection (file-disjointness,
ADR-075/106 ordering), the governor caps, or the `UNSORRY_BATCH_SIZE=1` default behaviour.
