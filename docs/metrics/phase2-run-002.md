# Phase-2 hard-target run — run 002 (decompose → recompose stress test)

**run_id:** `phase2-run-002` · **date:** 2026-06-10 (UTC) · **trial:** Second Phase-2 target run (Stage E) — a deliberately **hard-target** run whose whole purpose was to exercise **decompose → recompose** end-to-end. Four prover agents (`h1`–`h4`) attacked four targets in parallel: `not-prime-pow-four-add-four`, `platonic-schlafli-core`, `alternating-sum-naturals`, `sum-range-pow-four-closed-form`.

Machine record: [`phase2-run-002.json`](phase2-run-002.json).

## Headline verdict (read this first)

**The headline question this run was built to answer: did the decompose → recompose chain complete end-to-end for at least one hard target?**

**NO — decompose → recompose was NOT demonstrated.** Zero targets decomposed; zero sub-goals created; zero `decomposed` telemetry events; zero decomposition PRs. The single target that landed (`sum-range-pow-four-closed-form`, PR #140) was proved **directly as a leaf** — it never went near the decompose path. The three targets most likely to have stressed decomposition never reached a terminal event at all.

| Dimension | Value |
|---|---|
| targets attacked | **4** |
| targets proved | **1** (`sum-range-pow-four-closed-form`) |
| proved **via decomposition** | **0** |
| proved **directly** | **1** |
| targets **decomposed** | **0** |
| targets **not reached** | **3** |
| sub-goals total / proved | **0 / 0** |
| `decompose_recompose_demonstrated` | **false** |
| decomposition PRs | **0** |
| open PRs remaining | **0** |
| gate-a failures on merged path | **0** |

**Exactly where it stalled:** *before* decomposition. Decomposition (ADR-009, `decompose_goal` in `swarm/agent.sh`) only fires on **budget exhaustion after the direct `claude` attempts fail/time out**. For `h4` the direct attempt succeeded first, so decomposition was correctly never needed. For `h1`/`h2`/`h3` the direct attempt **had not returned** when the stop hook forced the run to end — so the budget-exhaustion → decompose branch was never reached. This means the stall is **not** claude's decomposition quality (no decomposition was ever attempted), **not** a sub that failed to prove (no subs were created), and **not** a broken recompose step (never reached). It is simply the direct-prove attempt not terminating inside the observation window.

## Per-target outcomes

### 1. `sum-range-pow-four-closed-form` — **proved-direct** (the only landed target)

```
theorem sum_range_pow_four_closed (n : ℕ) :
    30 * (∑ k ∈ Finset.range (n + 1), (k : ℤ) ^ 4)
      = n * (n + 1) * (2 * n + 1) * (3 * n ^ 2 + 3 * n - 1)
```

The Faulhaber `p = 4` identity. Agent `h4` claimed it (claim push lost the release-branch race on attempt 1, succeeded on attempt 2 after rebase — the familiar optimistic-concurrency pattern, not a collision), then proved it on the **first** `claude` attempt with a genuine 8-line Mathlib induction:

```
induction n with
| zero => simp
| succ n ih =>
  rw [Finset.sum_range_succ, mul_add, ih]
  push_cast
  ring
```

PR **#140** opened with auto-merge (squash) enabled; it sat ~9 min blocked on gate-a (full Mathlib build, 9m8s), all five checks (`detect`, `gate-b`, `agent-lint`, `aisp-advisory`, `gate-a`) passed, and it **MERGED at 2026-06-10T23:44:51Z** by the repo's auto-merge — not by the observer. Post-merge on main: `goals/sum-range-pow-four-closed-form.aisp` is `status≡proved`, `aff≡1`, `sha≡1a7aa8ab…`; index entry `library/index/1a7aa8ab…aisp` binds `goal≡sum-range-pow-four-closed-form`, `name≡sum_range_pow_four_closed`.

**Decomposition: not exercised.** `subs_total = 0`, `subs_proved = 0`. Direct leaf kill on attempt 1.

> Note: the `.aisp` records `difficulty≡2` for this target, although the run treated all four as hard targets. It was the easiest of the four and the only one that landed.

### 2. `not-prime-pow-four-add-four` — **not-reached**

```
theorem not_prime_pow_four_add_four {n : ℕ} (hn : 1 < n) : ¬ Nat.Prime (n ^ 4 + 4)
```

`status≡open` on main, `difficulty≡3`, `deps≡⟨⟩`. No index entry, no subgoals, no decomposition. The Sophie-Germain factorization target (`n^4 + 4 = (n^2 - 2n + 2)(n^2 + 2n + 2)`); the backlog flags ℕ-subtraction in the left factor as the friction. Agent `h1` ran in the sibling swarm and is not in this report's prover telemetry, but the settle pass independently confirms the target was never proved and never decomposed. Neither a direct proof nor a decomposition L1 was reached.

### 3. `platonic-schlafli-core` — **not-reached** (hardest of the four)

```
theorem platonic_schlafli_pairs (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹) :
    (p, q) ∈ ({(3,3),(3,4),(4,3),(3,5),(5,3)} : Finset (ℕ × ℕ))
```

`status≡open` on main, `difficulty≡4`, `deps≡⟨⟩`. No index entry, no subgoals, no decomposition. This is the Freek 100 #50 bounded-arithmetic core ("exactly five Platonic solids"). Agent `h2` emitted **only** the `claimed` event; the direct `claude` proof attempt (PID 6887 in h2's telemetry) was **still running** when the stop hook forced the return. The decompose-on-budget-exhaustion branch — which would have emitted `decomposed` and created `platonic-schlafli-core-s1..sN` — was never reached. Backlog decomposition sketch (had it run): **L1** derive `p < 6` and symmetrically `q < 6`; **L2** `interval_cases` on `3 ≤ p, q ≤ 5`; **L3** keep the five pairs. None of L1–L3 was reached.

### 4. `alternating-sum-naturals` — **not-reached**

```
theorem alternating_sum_naturals (n : ℕ) :
    ∑ i ∈ Finset.range n, (-1 : ℤ) ^ i * (i + 1)
      = if Even n then - (n / 2 : ℤ) else (n / 2 : ℤ) + 1
```

`status≡open` on main, `difficulty≡3`, `deps≡⟨⟩`. No index entry, no subgoals, no decomposition. Agent `h3` emitted **only** the `claimed` event (claimed `2026-06-10T23:29:58Z`); the direct proof attempt (PID 6887/6888) was mid-flight at forced return — **before** any decomposition would trigger. Backlog decomposition sketch (had it run): two-step induction `n → n+2` collapsing each pair `(-1)^i(i+1) + (-1)^(i+1)(i+2) = -1`; base cases `n = 0, 1`; reconcile `Even`/`(n/2)` `Nat.div` via `omega` (~3 sub-parts). The backlog calls the `Even`/ℕ-division bookkeeping the riskiest of the set to *prove* — but it was never attempted.

## The decomposition trees — there are none

There is **no decomposition tree to report for any of the four targets.** Concretely, at HEAD `1d7e6aa`:

- **No `decompositions/` directory** exists in the repo. The only path matching `decompositions/` anywhere in the tree or git history is the gate-b test fixture `tools/gate_b/tests/fixtures/valid_tree/decompositions/nat-add-comm-hard.agent-alpha.aisp` — a unit-test artifact, not a real decomposition.
- **No `goals/<target>-s[0-9]*` sub-goal files** exist for any of the four targets, on main or in `git log --all --diff-filter=A`.
- **No `decomposed` telemetry event** was emitted by any prover (each metrics.jsonl for h1/h2/h3 contains only a `claimed` line; h4's contains the direct `claimed → proved → pr-opened → released` chain).
- **No decomposition PR.** PR #113 ("feat: goal decomposition (Stage C, ADR-009)") is the **machinery** PR that *built* decomposition; it is not a decomposition *exercise* against these targets.

The Stage-C decomposition machinery (ADR-009, SPEC-009-A, `swarm/prompts/decompose.md`) is **live but unexercised** on this run.

## Why decomposition never fired

`decompose_goal` (ADR-009) is invoked by the swarm **only after the direct `claude` proof attempts exhaust the wall budget** — at which point it emits a `decomposed` event, parks the parent `blocked`, and creates `…-s1..sN` sub-goals at depth+1. The precondition for the recompose chain is therefore: *the direct attempt fails or times out first.*

- `h4` / `sum-range-pow-four-closed-form`: direct attempt **succeeded**, so decomposition was correctly skipped. (Good outcome, wrong arm for this run's headline.)
- `h1` / `not-prime-pow-four-add-four`, `h2` / `platonic-schlafli-core`, `h3` / `alternating-sum-naturals`: direct attempt had **not returned** when the stop hook fired. The budget-exhaustion → decompose branch was never reached.

So the recompose path is still **untested end-to-end against a real target** — and this is now the **second** Phase-2 run to end that way (`phase2-run-001` also proved its single target directly without decomposition). It is a clearly-recurring coverage gap, not a one-off.

**No error to paste for the unreached targets.** There is no `prove-failed` event, no `lake` error, no kernel error, no red gate-a. The only terminal evidence is each metrics.jsonl holding a single `claimed` line and the post-run `goals/<id>.aisp` still showing `status≡open`. The "sticking point" is purely that the direct-prove attempts did not terminate inside the observation window; a longer-wall re-run would be needed to actually drive a target into the decompose path.

## Soundness spot-check (the one merged target)

`library/Unsorry/SumRangePowFourClosedForm.lean`:

- **Forbidden-tactic scan: CLEAN** — `grep` for `sorry|admit|sorryAx|native_decide|axiom|unsafe` returns no matches.
- **Genuine proof** — 8-line induction closed by `ring` on the polynomial identity (no `decide`, no shortcut). Full text shown above.
- **gate-a on PR #140: SUCCESS** — the authoritative job runs `lake exe axiom_audit` (whitelist `[propext, Classical.choice, Quot.sound]` only, rejects `sorryAx` without `--allow-sorry`), `lake build UnsorryLibrary --wfail`, leanchecker kernel replay, **statement-binding regeneration (ADR-011)**, the forbidden-elaboration-option scan, and a textual forbidden-token lint on the library diff. All green on the merge commit.
- **Binding held** — `aff≡1`; index `name≡sum_range_pow_four_closed`. The merged proof inhabits the goal's exact statement.

> The open-goal template `goals/sum-range-pow-four-closed-form.lean` still ends in `sorry`. That is by design — gate-a audits `goals/*.lean` with `--allow-sorry` but `library/*.lean` **without** it. The real, sorry-free proof lives in the library module; don't be misled by the stub.

## What this run establishes (and does not)

- **Establishes:** the direct path closes another non-trivial target (`sum-range-pow-four-closed-form`) soundly, with binding held and gate-a green; the verification machinery (axiom audit, kernel replay, binding regeneration) continues to gate the merged path correctly.
- **Does NOT establish:** decompose → recompose. The headline this run was built to test is **NOT demonstrated**. Three of four targets did not reach a terminal event; the one that did was a direct leaf. After two Phase-2 runs, the end-to-end **decompose → prove subs → recompose-parent-through-gate-a** chain has still never run against a real target.
- **Recommendation (for the next run):** force the decompose arm — give a hard target (e.g. `platonic-schlafli-core` or `alternating-sum-naturals`, whose backlog sketches are explicitly multi-lemma) a wall budget short enough that the direct attempt is *expected* to exhaust, or seed a decomposition directly, so the recompose path actually gets exercised and observed.
