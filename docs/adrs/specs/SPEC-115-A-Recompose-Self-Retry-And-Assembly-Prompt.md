# SPEC-115-A: Recompose Self-Retry and Assembly Prompt Hardening

Implements: [ADR-115](../ADR-115-Recompose-Self-Retry-And-Assembly-Prompt.md) · Status: Living · Updated: 2026-07-01

## Behaviour

A `--prove` run that finds no claimable viable goal **and** no recoverable parked goal does not
immediately idle. If it has already attempted a **recompose-candidate** this session (a decomposed
parent whose sub-lemmas are all proved — ADR-034's `recompose-candidate` predicate), it re-arms one
such goal — clears it from the per-session `HANDLED` set — so the next pass re-selects and retries
the assembly. Each re-arm is counted per goal and capped at `UNSORRY_RECOMPOSE_RETRIES` (default 2);
past the cap the goal stays `HANDLED` and the run idles as before. Because retries are fresh
`prove_goal` attempts, they climb the ADR-015 effort ladder (high→xhigh→max).

Independently, whenever `prove_goal` proves a recompose-candidate, the attempt prompt gains a
**RECOMPOSITION** block instructing the model that the sub-lemmas already surfaced as PROVED
DEPENDENCIES (ADR-014) are sufficient and should be assembled — instantiate each at the matching
term, reconcile syntactic differences with `ring`/`ring_nf`, and close with
`exact`/`linarith`/`nlinarith` — rather than proving from scratch. The block is advisory: it never
gates a proof and is absent for ordinary (non-decomposed) goals.

## Components (`swarm/agent.sh`)

- **`recompose_prompt_block <goal>`** — prints the RECOMPOSITION prompt block iff
  `py_helper recompose-candidate <goal> decompositions library` succeeds (run from the proof
  worktree root, where `decompositions`/`library` resolve), else nothing. Extracted from
  `run_proof` so `--self-test` can exercise it hermetically.
- **`run_proof`** — after building the ADR-014 `deps_prompt`, sets
  `recompose_prompt="$(recompose_prompt_block "$goal")"` when any proved dependency was surfaced,
  and appends it to the attempt prompt (`…$deps_prompt$recompose_prompt$lessons_prompt`).
- **`rearm_recompose_candidate`** — reads/writes `main`'s `HANDLED` and `RECOMPOSE_RETRIES` maps via
  bash dynamic scope. Iterates `HANDLED`; for the first entry that is in `--goal` scope
  (`goal_in_scope`), under its per-goal retry cap, is a `recompose-candidate`, and has no open prove
  PR / queued branch (that work is already in flight), it increments `RECOMPOSE_RETRIES[<goal>]`,
  clears `HANDLED[<goal>]`, logs the re-arm, and returns 0. Returns 1 if nothing is eligible or
  `UNSORRY_RECOMPOSE_RETRIES` ≤ 0.
- **`main` step 4** — when both the viable and recovery pools yield no `CLAIMED_GOAL`, and this is
  not a `--once` run, call `rearm_recompose_candidate`; on success `continue` (the next pass
  re-selects the re-armed goal) instead of logging "no viable or recoverable prove work this pass"
  and sleeping.
- **`RECOMPOSE_RETRIES`** — `declare -A` alongside `HANDLED`/`SWEPT` in `main`; goal → re-arms
  spent this session.
- **`UNSORRY_RECOMPOSE_RETRIES`** — integer knob (default 2), validated by `validate_integer_knob`;
  0 disables self-retry (one attempt per session, the pre-ADR-115 behaviour).

## Properties

- **Realises ADR-034's intent in-session.** The τ_v-floored recompose-candidate that ADR-034 keeps
  "viable for the sweep to retry" is now actually retried by the same process, not only by a fresh
  restart or a different agent.
- **Bounded.** At most `UNSORRY_RECOMPOSE_RETRIES` re-arms per goal per session; a truly-unprovable
  assembly then idles rather than looping. A fresh process resets the counter (one more bounded
  round), which is the intended `run.sh --prove --goal <parent>` "restart to retry" behaviour.
- **Non-interfering.** Re-arm runs only when no viable and no recoverable goal is claimable, so real
  work always precedes it; it never competes with normal proving or ADR-044 recovery.
- **In-flight-safe.** A recompose-candidate whose retry already produced an open PR or queued branch
  is not re-armed (the same `open_prove_pr_exists`/`queued_prove_branch_exists` skips
  `claim_from_pool` applies).
- **Advisory prompt.** The RECOMPOSITION block only shapes the model's approach; Gate A / local
  `--wfail` verification and the ADR-011 statement binding are unchanged, so a wrong assembly still
  fails exactly as before.
- **Opt-out.** `UNSORRY_RECOMPOSE_RETRIES=0` restores single-attempt-per-session behaviour; the
  prompt block has no knob (it is pure guidance and cannot reduce success).

## Tests (`swarm/agent.sh --self-test`)

- **`test_recompose_prompt_hint`** — `recompose_prompt_block` emits the RECOMPOSITION steer for a
  recompose-candidate (all subs proved) and nothing for a non-decomposed goal.
- **`test_recompose_self_retry_rearm`** — re-arms a HANDLED recompose-candidate (clearing it from
  HANDLED) up to the cap, increments the per-goal counter, never re-arms a non-candidate, stops at
  the cap, and is a no-op when `UNSORRY_RECOMPOSE_RETRIES=0`.
