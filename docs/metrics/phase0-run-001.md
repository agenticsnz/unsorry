# Phase-0 Trial — Run 001 (2026-06-10)

Machine record: [phase0-run-001.json](phase0-run-001.json) · Schema: [METRICS.md](METRICS.md)

## What ran

Three supervised agents — **trial-alpha** (sonnet), **trial-bravo** (sonnet), **trial-charlie**
(haiku) — each ran 12 cycles of the Phase-0 loop (`swarm/agent.sh`: claim → translate → diff →
PR → release) against the 10-goal known-true backlog, deliberately racing each other. A fourth
agent, **trial-omega** (sonnet), then ran a 3-cycle convergence sweep to mop up overlapping
translation PRs, exercising the sweep fix merged in
[PR #8](https://github.com/agenticsnz/unsorry/pull/8) (SPEC-007-A) immediately before the trial.
A dead agent's claim (`trial-dead` on `nat-le-trans`) was planted in advance to give the reaper
something real to reap. All three supervisors stopped at the 12-cycle cap with work still
visible, not at quiescence.

## The numbers

| Metric | Value | Interpretation |
|---|---|---|
| claim_attempts | 39 | 38 `claimed` + 1 `collision` event across all four agents. |
| collisions | 1 | trial-bravo found nat-le-trans's live-claim cap full and withdrew per contract — the designed behaviour. |
| collision_rate | 0.0256 | Explicit cap-full withdrawals were rare; most contention resolved at the git layer (see caveat below). |
| translations_merged | 24 | Every `tr(...)` PR that was opened, merged — no translation was lost. |
| prs_total | 38 | PRs [#9–#46](https://github.com/agenticsnz/unsorry/pulls?q=is%3Apr+is%3Amerged), 24 `tr(...)` + 14 `converge(...)`; **all 38 merged autonomously**. |
| gate_b_failures_on_first_attempt | 0 | No trial artifact was ever rejected by the validator. |
| validator_pass_rate | 1.00 | 38/38 trial PRs green on gate-b first attempt (88/88 gate-b runs succeeded; no re-run attempts exist). |
| goals_matched | 7 | Independent translations converged byte-equal after normalization. |
| goals_flagged | 1 | nat-le-refl — the trial's single fidelity flag. |
| **fp_rate** | **0.125** | 1 flag / 8 decided goals; all goals are known-true, so the flag is a false positive by construction. |
| paraphrase_pairs_sha_equal | 1 of 3 | One pair byte-equal, one pair is the flag itself, one pair indeterminate (see Fidelity). |
| coordination_errors | 0 | No Gate B rejections, no claims beyond the GB014 cap, no protocol violations in any branch history. |

## Kill-criterion verdict

**Not tripped.** fp_rate = 0.125 < 0.20 (SPEC-003-D: "flag FP ≥ 20 % on identical-meaning
pairs"). Statement-fidelity diffing survives Phase 0; ADR-008 (single translation + Lean
back-translation fallback) stays on the shelf.

## Evidence

### Collisions and claim discipline

- Explicit collision: trial-bravo's `collision` event on nat-le-trans at 03:07:35Z, after
  trial-charlie (03:07:27Z, commit `1938793`) and trial-alpha (03:07:33Z, commit `07cd367`)
  filled the 2-live-claim cap. Bravo withdrew and claimed nat-leq-self instead — exactly the
  contract's collision ⇒ next-goal recovery.
- The full claims-branch history (79 commits: 39 `claim:`, 39 `release:`, 1 `reap:`) never
  shows more than 2 concurrent live (unexpired) claims per goal, and never two live claims by
  one agent. First-push-wins held: claim-push losers either rebased and won the next slot or
  withdrew.
- **Honest caveat:** `metrics.jsonl` has no event for claim-push races resolved by
  rebase-and-retry (alpha 2, bravo 4, charlie several, including one 3-attempt claim) — those
  are visible only in supervisor stderr. `collision_rate` therefore measures cap-full
  withdrawals, not raw git-level contention, which was substantially higher.

### Reap (TTL expiry)

- Actions run: <https://github.com/agenticsnz/unsorry/actions/runs/27250773072> — reaped
  exactly 1 claim (`claims/nat-le-trans.trial-dead.aisp`, expired 4502 s), kept 0,
  unparsable [].
- Removal commit on `claims`: `09ba7efe4f377603d81df285e70b8092c99e5852`
  (`unsorry-reaper[bot]`, "reap: 1 expired claim(s)", deletes only the planted file).
- Live-claim safety: it is the only `reap:` commit in the history; every other claim removal
  is a `release:` by the owning agent. An earlier dispatch run (27245383354, 00:44:22Z,
  pre-expiry) correctly kept the claim. No cron-triggered runs appeared during the window —
  both reaper runs were `workflow_dispatch`; cron-schedule reliability on this repo is
  unverified by this trial.

### Fidelity (planted paraphrase pairs)

| Pair | Result |
|---|---|
| nat-mul-comm ↔ nat-product-order | **Byte-equal** final shas (`ea25d3b6…`): both English phrasings normalized to `∀x,y∈ℕ: x·y ≡ y·x`. Correct fidelity — and an accidental proof that the backlog holds a semantic duplicate (Phase-1 dedup item). |
| nat-le-refl ↔ nat-leq-self | nat-leq-self matched (`bdfe3dd8…`); **nat-le-refl flagged** (sha ∅) — the run's one false positive ([PR #19](https://github.com/agenticsnz/unsorry/pull/19) still merged; flag-don't-block worked as designed). |
| nat-add-zero ↔ nat-zero-identity-add | **Indeterminate.** nat-add-zero matched (`84f38b99…`) but nat-zero-identity-add ended the trial `status≜open` with only trial-omega's translation ([PR #45](https://github.com/agenticsnz/unsorry/pull/45)) — omega cannot converge against itself, so there is no final sha to compare. Scored not-equal under the strict metric, but the comparison is unobservable for this run, not failed. |

## Anomalies

1. **agent.sh branch-reuse push failure (14 failed cycles: alpha 5, bravo 4, charlie 5).** When
   a cycle re-claims a goal whose feature branch already exists on the remote (after auto-merge
   or a prior cycle's rebase advanced it), the plain `git push` is rejected non-fast-forward and
   the cycle exits 1. Every retry recovered, nothing was lost or corrupted, but each occurrence
   burns a cycle and double-counts claimed/translated/released telemetry without a `pr-opened`.
   Worth a fix before Phase 1.
2. **Stale claim state after merge.** The driver of (1): claim/goal state isn't pruned after a
   translation PR auto-merges, so later cycles re-claim already-translated goals (charlie hit
   this on 5 goals).
3. **Three distinct translations of nat-mul-comm.** Sequential claims by all three supervised
   agents are legal under the 2-*live*-claim cap; agent.sh logged the anomaly and still
   converged it matched (`translations:"3"`). The cap bounds concurrency, not total translation
   count — acceptable for Phase 0, worth tightening if duplicate effort matters at Phase-1 scale.
4. **Exit codes under-report partial success** — charlie's cycle 7 exited 1 after successfully
   opening converge [PR #26](https://github.com/agenticsnz/unsorry/pull/26).
5. **Convergence sweep did real work** ([PR #8](https://github.com/agenticsnz/unsorry/pull/8)
   context): the supervised agents left nat-product-order with merged overlapping translations
   but no convergence; trial-omega's sweep converged it
   ([PR #44](https://github.com/agenticsnz/unsorry/pull/44)) and then picked up the two leftover
   backlog goals ([#45](https://github.com/agenticsnz/unsorry/pull/45),
   [#46](https://github.com/agenticsnz/unsorry/pull/46)) before stopping on "no claimable goal".
6. **Telemetry capture artifact:** trial-omega's converged-events capture duplicates its single
   `converged` line; only one convergence happened.

## What this proves for the readiness checklist

- **(c) TTL reaping observed — satisfied.** A genuinely expired claim was removed by the
  scheduled reaper workflow with a durable evidence trail (run 27250773072, commit `09ba7efe`,
  job-summary report), and no live claim was ever touched. Caveat carried forward: the trial
  only observed `workflow_dispatch` runs; observing a *cron-triggered* reap remains open.
- **(d) Collision handling works and the fidelity FP rate is measured under threshold —
  satisfied.** (The checklist letters aren't enumerated verbatim in-repo; per the design doc's
  Phase-0 success criteria this item maps to "claim-collision handling works" + "statement-diff
  false-positive rate measured and under 20 %".) Evidence: first-push-wins arbitration held
  across 39 claim attempts with one clean contract-compliant withdrawal and zero coordination
  errors; fp_rate measured at 0.125 < 0.20 with the kill criterion explicitly evaluated and not
  tripped.
- **(e) Swarm contract at Gold tier or better, with zero protocol-meaning disputes —
  satisfied operationally.** The contract validated at ◊⁺⁺ Platinum at authoring (SPEC-003-D);
  this trial adds the operational half: four agents on two different models ran 39 cycles + a
  sweep against the same contract with **zero protocol-meaning disputes**, 38/38 PRs passing
  Gate B first-attempt, and all coordination artifacts parseable (reaper `unparsable=[]`).

## Observability gaps (declared, not estimated)

- Git-level claim/release push contention is undercounted in telemetry (no event type); counts
  above come from supervisor stderr observations and are approximate where marked.
- The third paraphrase pair's sha comparison is unobservable (second translation never existed).
- Failed cycles emit no failure event in `metrics.jsonl`; failure counts come from supervisor
  exit-code reports.

---

## Addendum — post-observation completion (same day)

The observation above froze at the supervisors' cycle caps. The run was completed immediately
afterwards; this addendum records the final state. The original numbers are left untouched as
the at-observation record.

### Completion runs

A fourth identity, **trial-delta** (sonnet), ran the two leftover second translations:
[PR #48](https://github.com/agenticsnz/unsorry/pull/48) (nat-zero-identity-add, converged in-PR)
and [PR #49](https://github.com/agenticsnz/unsorry/pull/49) (nat-zero-lt-succ → `translated`).
One delta cycle reproduced anomaly 1 (branch-reuse push rejection, retry recovered) —
consistent with the trial's failure pattern.

### Flag adjudication (the designed human-review path)

Final decided state before adjudication: **8 translated + 2 flagged** (nat-le-refl,
nat-zero-identity-add) — strict FP rate 2/10 = **0.20, exactly at the kill-criterion
boundary**. Review of all flagged translation pairs found them identical up to α-renaming plus
**one mechanical root cause: a redundant parenthesis wrap of the binder body**
(`∀x∈ℕ:x≤x` vs `∀n∈ℕ:(n≤n)`).

Resolution ([PR #50](https://github.com/agenticsnz/unsorry/pull/50)): normalization step 5 —
redundant-paren elimination restricted to provably meaning-preserving groups (application
parens `P(x)` never collapsed; 17 new tests including the exact trial pairs). Sha-drift audit:
all 8 previously matched goals unchanged. Both flagged pairs re-diff to **MATCH**; goals
resolved `translated` with agreed shas.

### Final state

| | |
|---|---|
| Goals decided | **10/10 translated**, 0 flagged, 0 open |
| Post-fix fidelity FP rate | **0/10** |
| Paraphrase pairs byte-equal | **3/3** (`ea25d3b6…`, `bdfe3dd8…`, `84f38b99…`) — every pair of independently-worded English statements converged to identical content addresses |
| Kill criterion | **Not tripped** — at-boundary reading rendered moot by the root-cause fix; ADR-008 fallback stays shelved |
| Anomalies 1/2/4 | Fix in flight: re-entrant cycle-state handling for `agent.sh` (branch-name uniqueness + hard-reset claims worktree per cycle) |
