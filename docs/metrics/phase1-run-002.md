# Phase-1 swarm rerun — run 002 (post-cache-fix prove baseline)

**run_id:** `phase1-run-002` · **date:** 2026-06-10 (UTC) · **trial:** Phase-1 swarm prove cycle, rerun after the mathlib-cache-in-worktree fix.

Machine record: [`phase1-run-002.json`](phase1-run-002.json).

## What ran

Three prover agents — `p2-alpha`, `p2-bravo`, `p2-charlie` (each driving `claude`) — ran the real swarm prove workflow end-to-end against `agenticsnz/unsorry`, 12 cycles each (36 cycles total). Each cycle: `agent.sh` claimed an unproved goal, invoked `claude` to write a Lean 4 proof of the goal's theorem, **warmed the mathlib olean cache (`lake exe cache get`) in the prove worktree**, self-verified locally (`lake build UnsorryLibrary --wfail` + `lake exe axiom_audit`), and — on a passing local proof — opened a Gate-A/Gate-B auto-merge PR titled `prove(<goal>): <name> by <agent>`.

This is the post-cache-fix baseline. Run-001 left the bare prove worktree without a warm olean cache, so local verify rebuilt all ~8486 mathlib modules from source and timed out non-deterministically; that produced run-001's `merge_rate = 0.6` and its 6 build-timeout `prove_failures`. Run-002 tests whether warming the cache removes those timeouts **without** introducing a green-local-then-red-CI divergence.

Ground truth was taken from a fresh clone at `main` HEAD `44d2b1a` (`feat: statement-binding gate (Stage D, ADR-011) (#123)`), via `gh` PR data, the `origin/claims` branch history, and the `goals/*.aisp` + `library/` tree. The three run-001 prove merges (#70, #72, #74) pre-date this run and are excluded from run-002's attempt/merge counts; run-002 prove PRs are **#85 and up**.

## Headline metrics

| Metric | Value | Basis |
|---|---|---|
| `claim_attempts` | **39** | `claim:` commits by p2-* agents on `origin/claims` (13 each). Telemetry reports 12 cycles each (36); the +3 are optimistic-concurrency claim-push retries — declared. |
| `collisions` | **0** | zero `collision` events anywhere |
| `collision_rate` | **0.0** | 0 / 39 |
| `proofs_attempted` | **18** | distinct (goal, agent) prove claims that ran a proof |
| `proofs_merged` | **16** | distinct (goal, agent) pairs that landed ≥1 merged prove PR (22 prove PRs merged; 6 are duplicate landings) |
| `merge_rate` | **0.889** | 16 / 18 |
| `prove_failures` | **0** | zero `prove-failed` events — every selected goal verified locally on attempt 1 |
| `gate_a_failures_on_merged_path` | **0** | all 22 merged prove PRs show gate-a = SUCCESS |
| `coordination_errors` | **0** | no Gate-B failure, no cap breach, no protocol violation |
| `goals_proved_total` | **16** | cumulative `status≜proved` on main (3 from run-001 + 13 new) |

## What the cache fix changed vs run-001

Run-001 and run-002 are the same workflow on the same backlog; the **only** intended difference is that run-002 warms the mathlib olean cache in the prove worktree. The effect is unambiguous and lands exactly where run-001's narrative predicted it would.

| Signal | run-001 | run-002 | Reading |
|---|---|---|---|
| `prove_failures` | 6 (all bare-worktree mathlib rebuild timeouts) | **0** | The cache fix eliminated every failure. Run-001 had **no** soundness or bad-math failures — all 6 were the build timeout. Warming oleans dropped per-proof verify to ~2–3.5 min and removed the timeout entirely. |
| `merge_rate` | 0.6 (3/5) | **0.889 (16/18)** | The two run-002 "misses" are cross-agent duplicate races on goals that **did** land via the other agent (#88, #92), not unproved goals. At the goal level, 13/13 distinct goals the swarm actually picked up are proved on main. |
| `gate_a_failures_on_merged_path` | 0 | **0** | The watch item for the rerun. Making local verify *faster* did not make it *wrong*: local verify still mirrored CI gate-a on every one of the 22 merged paths. No green-local-then-red-CI case. |
| build/infra blockers | `/tmp` filled to 0 MB, hard-blocked bravo & charlie after 1–2 cycles | **none** | All three agents completed 12 full cycles on `/workspaces` (38 G free). No ENOSPC, no stalled agent. |
| new goals proved | 3 | **13** | The verified library grew from 3 non-Basic modules to **16**. |

In one sentence: the cache fix converted run-001's 6 infrastructure failures and 0.6 merge rate into **0 failures and a 0.889 merge rate**, with **no** new false-confidence (gate-a-on-merged-path stayed at 0). The merge rate did not reach 1.0 only because of cross-agent duplicate races — both goals that drove the "misses" are proved on main.

## Duplicate-PR / fan-out behaviour (input to Stage C caps)

The dominant inefficiency this run is **not** a proof failure — it is merge/status-propagation lag driving redundant re-proofs. The mechanism:

1. An agent proves a goal locally and opens an auto-merge PR.
2. The goal's claim is only effectively released-for-good when that PR **merges** to main and the status flips `open → proved` on `origin/main`.
3. Under heavy auto-merge-queue contention (3 concurrent provers + Stage B/C/D feature merges), the PR sits in the rebase-from-scratch release loop for 1–3 cycles.
4. Meanwhile the selector reads `origin/main`, still sees the goal as claimable, and re-hands the **same already-proved goal** to the same agent — producing an identical-sha duplicate PR.

Quantified from ground truth:

- **22 merged prove PRs but only 13 distinct new goals.** 6 of the 22 merges are duplicate landings of an already-merged (goal, agent) pair (#89, #104, #107, #115, #116, #119).
- **~23 of 36 agent-cycles (~64%) were spent on duplicate re-proofs** of an already-proved goal. Per agent: p2-alpha 5 distinct of 12, p2-bravo 6 of 12, p2-charlie 7 of 12.
- **14 open prove PRs** remain, all `CONFLICTING`/`DIRTY` — duplicate re-proofs blocked **only** by merge conflict against an advanced main, not by any red gate. They come in duplicate-target pairs, so only one of each pair can merge before its twin goes DIRTY.

This is throughput-limiting, **not** correctness-affecting: auto-merge dedups, and same-sha duplicates land as no-ops or stay open harmlessly once the goal is `status≜proved`. The cost is opportunity: those ~23 wasted cycles never fanned out to the tail of the backlog.

**Recommendation for Stage C (caps/decomposition):** a `sha-already-in-library` or `claimed-but-PR-open-by-me` short-circuit, decoupled from the main-branch status flip, plus a **per-goal live-proof-PR cap** (so the second and third agent don't pile onto a goal that already has an in-flight proof PR). With that dedup, the same 36-cycle budget would very likely have closed the 4 untouched open goals and emptied the prove backlog.

## Unproved goals — honest accounting

Four prove-targets remain `status≜open` at run end: **`nat-mul-one-thm`, `nat-mul-zero-thm`, `nat-zero-le`, `or-comm-imp`**.

The honest finding: **none of these was a model capability failure, and none was attempted-and-failed.** Each has **zero** `claim:` commits from any p2-* agent on `origin/claims` — they were **never claimed**. They remain open because the duplicate-thrash above consumed the cycle budget before fan-out reached the backlog tail. With the recommended dedup short-circuit, the swarm would very likely have closed 2–4 of them. There is no goal in this run that the model picked up and could not prove.

Ten further goals are `status≜translated` (`nat-add-assoc`, `nat-add-zero`, `nat-le-refl`, `nat-le-trans`, `nat-leq-self`, `nat-mul-comm`, `nat-mul-one`, `nat-product-order`, `nat-zero-identity-add`, `nat-zero-lt-succ`). These are **upstream of the prove stage** — not yet bound to a `-thm` prove target — so they are out of scope for a prove run, not failures.

## Gate-A vs local-verify

`gate_a_failures_on_merged_path = 0`. On every one of the 22 merged run-002 prove PRs, the agent's local verify agreed with CI gate-a — `statusCheckRollup` shows gate-a = SUCCESS on all 22. There were **zero** false-confidence cases where a locally-verified proof failed CI gate-a. This is the property the rerun most needed to confirm: warming the olean cache made local verify *faster* (matching CI's warm cache) but did not change its *verdict*. Run-001 already had this property; run-002 keeps it under a 4×-larger merged-proof load.

## Soundness

`axiom_audit` is part of the merged path's gate; every merged module passed it (no `sorry` / `native_decide` / `admit`, no axioms beyond `propext` / `Classical.choice` / `Quot.sound`). The 16 `status≜proved` goals map 1:1 to the 16 non-Basic `library/Unsorry/*.lean` modules. (There are 17 index `.aisp` entries — the +1 is the pre-existing `nat-zero-lt-succ` translated-goal entry carried since run-001, the same index/library asymmetry flagged in run-001, not produced by this run.)

## Anomalies and observability gaps

- **`claim_attempts` 39 vs 36 cycles (declared, not estimated):** `origin/claims` carries 13 `claim:` commits per agent (39), while each agent's telemetry reports 12 cycles (36). The +1 per agent is the optimistic-concurrency retry — a claim push that lost the release-branch race, re-pushed after a rebase-from-scratch, leaving an extra `claim:` commit. The headline metric uses the ground-truth claims-branch count (39); the telemetry-cycle count (36) is the alternative denominator and is declared. Either way `collisions = 0`, so `collision_rate = 0.0`.
- **jsonl not independently re-read:** `p2-alpha` / `p2-charlie` `metrics.jsonl` live in their own workdirs (`/workspaces/w7-p2-*-work/`) and were not re-read here; `p2-bravo`'s jsonl was provided inline. **All headline metrics are derived from `gh` + `origin/claims` + the goals/library tree** (independently verifiable ground truth), so they do not depend on jsonl readability. Cycle counts (12 each) are agent-reported and corroborated by the claims-branch claim counts.
- **14 open DIRTY prove PRs left untouched:** per observer scope, nothing was merged, rebased, or edited; no `--admin` used. Per the settle telemetry these need rebase-on-main + paired-dup dedup (not proof work) to land — out of scope for an observer.
- **"release push rejected … rebasing from scratch" on every cycle:** these are release-branch optimistic-concurrency races resolved by rebase-and-retry, **not** collisions. Two `reap:` commits cleared expired claims (reaper, also not a collision).

## What this run establishes

- The cache fix is validated: **0 build-timeout failures** (down from 6), **merge_rate 0.889** (up from 0.6), and **0 gate-a failures on the merged path** preserved. The verified library grew from 3 to 16 theorem modules.
- The remaining inefficiency is **merge-lag duplicate fan-out** (~64% of cycles on re-proofs), characterised here as direct input to Stage C's caps/decomposition work.
- The remaining unproved prove-targets are **un-attempted, not unprovable** — a fan-out budget problem, not a model-capability problem. Stated plainly, with no goal claimed-and-failed.
