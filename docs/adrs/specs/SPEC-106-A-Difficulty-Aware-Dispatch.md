# SPEC-106-A: difficulty-aware dispatch ordering

Implements: [ADR-106](../ADR-106-Difficulty-Aware-Dispatch.md) · builds on
[SPEC-075-A](SPEC-075-A-Solver-Fair-Queue-Dispatch-Order.md) · Status: Draft · Updated: 2026-06-26

Contract for ordering queued `queued/prove/*` branches in the governed dispatcher. Pure logic in
`tools/dispatch/fair_order.py` (unit-tested without git); `swarm/agent.sh::fair_dispatch_order`
is the thin caller (`python3 -m tools.dispatch.fair_order`, refs on stdin → reordered on stdout).

## 1. Difficulty classification

`is_low_difficulty(model)` — True iff `model` is non-empty and contains (case-insensitive) any of
`LOW_DIFFICULTY_MARKERS = (template, decide, sympy, ring, norm_num, norm-num)`. An empty/absent or
unrecognised model → False (HIGH). This is **fail-safe**: only KNOWN-trivial template/tactic
models are deprioritised; a genuine LLM model or any new/unknown label is never blindly demoted.
The marker list is one documented constant, kept in step with the leaderboard's difficulty
discounting; extend it when a new template model appears.

## 2. Solver key (ADR-075, unchanged)

`solver_key(ref, solver_map)` = the queue board's `solver:<github>` for the normalised branch
(`docs/queue.json` on origin/main, ADR-066), else the branch token `agent:<agent-id>` parsed from
`queued/prove/<goal>/<agent-id>-<hex>`. A re-routed branch is authored by the operator, so the
board's provenance — not the commit author — is the only correct key.

## 3. Ordering

`order_refs(refs, solver_map, model_map, difficulty=True)`:
- `difficulty=False` → a single `round_robin(refs)` (ADR-075 only).
- `difficulty=True` → partition into `high = [r for r if not is_low_difficulty(model_map[r])]`
  and `low = [...]`, then return `round_robin(high) + round_robin(low)`.

`round_robin(refs, solver_map)` (ADR-075): bucket by solver key preserving input order within a
bucket; visit buckets in **sorted-key** order; round `i` emits the `i`-th branch of every bucket
that still has one — so each active solver gets exactly one branch per round until drained.
Deterministic (reproducible trials).

## 4. Invariants

- **Permutation.** The output is a permutation of the input refs (nothing dropped or duplicated).
- **High before low.** No low-difficulty branch is emitted before any high-difficulty branch.
- **Fairness within tier.** ADR-075 round-robin holds inside each tier (no solver starves a tier).
- **Fail-safe difficulty.** Unknown/absent model ⇒ high tier (never deprioritised on a guess).
- **Reversible.** `UNSORRY_DIFFICULTY_DISPATCH=0` → fairness-only; `UNSORRY_FAIR_DISPATCH=0` →
  verbatim lexical passthrough (handled in `agent.sh` before the module).
- **EPIPE-safe.** The dispatch loop closes the pipe once its limit/governor stops it; the module
  catches `BrokenPipeError` (unread refs are exactly the ones not acted on — a normal short read).
- **Soundness-neutral.** Reordering only; dedup (ADR-064/071), governor (ADR-058) and Gate A are
  the deciders. `model` is advisory metadata, never trusted.

## 5. Conformance (tools/dispatch/tests/test_fair_order.py)

`is_low_difficulty` over template/tactic models (low) vs genuine/unknown (high); `token_key` /
`solver_key` (board-preferred, token fallback); `round_robin` interleaves solvers + small backlog
served round 0; `order_refs` high-before-low, fairness-within-tier, unknown-model-is-high,
difficulty-disabled-equals-round-robin, output-is-a-permutation. Plus the existing `agent.sh
--self-test` (`test_dispatch_solver_fairness`, `test_fair_dispatch_order_survives_early_reader_
close`) still green.

## 6. References

ADR-106, ADR-075/SPEC-075-A (fairness), ADR-066 (queue board / model), ADR-064/071 (dedup),
ADR-058 (governor). Module `tools/dispatch/fair_order.py`; caller `swarm/agent.sh`.
