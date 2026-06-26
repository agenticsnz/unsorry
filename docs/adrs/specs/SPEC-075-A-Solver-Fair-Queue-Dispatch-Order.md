# SPEC-075-A: Solver-Fair Queue Dispatch Order

Implements [ADR-075](../ADR-075-Solver-Fair-Queue-Dispatch-Order.md).

## 1. Goal

Re-order the queued proof branches the dispatcher considers so that every *active*
solver gets one branch per round (round-robin / max-min fairness), instead of the pure
lexical-by-goal order that let a high-volume early-alphabet contributor starve the rest
— without changing what actually merges (dedup, the governor, and Gate A are untouched).

## 2. Components

### 2.1 `swarm/agent.sh` :: `fair_dispatch_order` (stdin → stdout filter)

A pure re-ordering filter: it reads queued branch refs on stdin (one per line, as
`queued_branch_refs` emits them, with or without an `origin/` prefix) and writes the
same refs to stdout, reordered, **verbatim** (no ref is added, dropped, or rewritten).

- **Disabled fast-path.** `UNSORRY_FAIR_DISPATCH=0` ⇒ `cat` (identity); dispatch reverts
  to the prior lexical order with no other change.
- **Solver key per branch**, in priority order:
  1. **Board** — `docs/queue.json` on `origin/main` (read once via `git show`, the
     authoritative solver resolution of ADR-066). Branch → `solver:<key>` where `<key>`
     is the group's `github` (else `solver`, else `unknown`). A re-routed branch is
     authored by the operator, so the board's provenance — **not** the commit author —
     is the only correct solver key.
  2. **Agent-id token** — for a branch absent from the board (pushed since the last
     board refresh): `agent:<token>`, where `<token>` is the last path segment with its
     trailing `-<hex>` removed (`…/<goal>/mac-3f2a` → `agent:mac`,
     `…/<goal>/reroute-35d094` → `agent:reroute`).
  3. **Unreadable board** ⇒ every branch falls to rule 2; if even that is degenerate the
     output is the input order (lexical) — never an error, never empty when input is
     non-empty.
- **Round-robin emission.** Buckets are visited in deterministic sorted-key order; round
  `i` emits the `i`-th branch of every bucket that still has one, until all are drained.
  Within a bucket the input (lexical) order is preserved, so the result is stable.

The script is supplied to `python3` via **process substitution** (`python3 <(cat
<<'PY' … PY)`), *not* a stdin heredoc — the heredoc would otherwise occupy `python3 -`'s
stdin and the piped refs would never be read.

### 2.2 `swarm/agent.sh` :: `dispatch_queue` wiring

The single change to the dispatch loop is its input source:

```sh
done < <(queued_branch_refs | fair_dispatch_order)
```

Everything downstream — the per-pass `seen_goals` dedup, `goal_already_proved`, the
open-PR set, `submission_governor_allows`, the ADR-071 `goal_taken_fresh` re-check, and
the `UNSORRY_DISPATCH_LIMIT` cap — is unchanged and order-independent in outcome.

## 3. Behaviour / invariants

- **Permutation invariant.** `fair_dispatch_order` output is a permutation of its input
  (same multiset of refs). It never affects *whether* a branch is dispatched, only the
  *order* in which candidates are considered.
- **Anti-starvation.** Given buckets of sizes `n₁ ≥ n₂ ≥ … ≥ n_k`, every bucket
  contributes one ref to each of the first `min(nᵢ, rounds)` rounds, so a minority
  bucket's refs appear within the first `k` positions — reachable under any
  `UNSORRY_DISPATCH_LIMIT ≥ k`.
- **Soundness independence.** No fairness decision is trust-bearing; Gate A re-verifies
  every dispatched proof from scratch regardless of order.

## 4. Configuration

| Knob | Default | Meaning |
|---|---|---|
| `UNSORRY_FAIR_DISPATCH` | `1` (on) | `0` reverts dispatch to the prior lexical order. |

## 5. Tests

`swarm/agent.sh --self-test`:

- `test_dispatch_solver_fairness` — five branches from token `big` (early-sorting
  goals) and one from token `small` (a last-sorting goal); with
  `UNSORRY_DISPATCH_LIMIT=2`, the round-robin dispatches the lone `small` branch (it
  would never appear under lexical order), and `UNSORRY_FAIR_DISPATCH=0` falls back to
  lexical (two `big` goals, no `small`).
- `test_dispatch_goal_dedup` / `test_dispatch_skips_taken_midpass` — unchanged: confirm
  the reordering does not perturb the ADR-064/071 dedup outcomes.
