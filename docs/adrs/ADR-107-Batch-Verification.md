# ADR-107: Batch verification — amortise the per-PR Gate A env-load across K proofs

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-107 |
| **Initiative** | throughput / verification capacity (D1b) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-26 |
| **Status** | Proposed |

## Context

A 2026-06-26 scaling audit (#6751, building on the throughput roadmap #5678) found that
**unsorry is no longer verification-*compute*-bound** — Gate A runs with slack (~8 in-flight vs the
~20 governor cap) — yet a **344-deep queue** persists, ~336 of it a single solver's
(`@ohdearquant`) homogeneous `template-ring-cofactor` flood. The lever to drain it is not *more*
gate capacity but spending the existing budget more efficiently.

Gate A's cost is **dominated by a fixed, per-PR environment load**: restoring the ~12–20 GB mathlib
cache and building the existing library (`gate_a_prepare`). That cost is paid **once per PR**,
independent of how many new proofs the PR adds — each additional proof is only a cheap incremental
`lake build` compile, a seconds-long nanoda leaf check (ADR-097), and its replay slice (ADR-063).
So today the swarm pays the dominant fixed cost **once per proof** (one PR per proof), when it could
pay it **once per K proofs**.

This is item **D1b** on the roadmap (issue #5683; the issue's reserved "ADR-092" was lost to the
ADR-number race — that number is now `ADR-092-Segregated-Benchmark-Track` — so this lands as
**ADR-107**). It is the queue-drainage lever called out in #6751 §5.

Two facts make batching cheap and safe to add:

- **Conflict-free by construction.** A queued prove branch's commit adds only NEW, content-addressed
  files: `library/Unsorry/<Name>.lean`, `library/index/<sha>.aisp`, `goals/<goal>.{lean,aisp}`,
  `backlog/<goal>.md`, `proof-runs/…`. Two *distinct* goals therefore touch **disjoint** paths, so
  their commits combine onto one branch with **zero conflicts**.
- **Counting & attribution are file-based.** `tools/leaderboard` derives `verified_proofs` and per-
  proof provenance from the `library/index/*.aisp` records (each carries `solver≜/agent≜/provider≜/
  model≜`), not from commit subjects — so K records in one merge = K correctly-attributed proofs.

## Decision

**Add an opt-in dispatcher mode that combines up to K independent queued `queued/prove/*` branches
into ONE `batch/prove/<hash>` PR, so Gate A pays its env-load once and verifies all K together.**
Controlled by `UNSORRY_BATCH_SIZE` (default **1** = today's one-PR-per-proof behaviour; the batch
code never runs until an operator raises it).

1. **Selection (pure, `tools/dispatch/batch.py`).** From the queued branches *already ordered* by
   ADR-075/106 (`fair_dispatch_order`), pick up to `UNSORRY_BATCH_SIZE` whose changed-file sets are
   pairwise **disjoint** and whose goals are not already proved / in an open PR (singleton or batch)
   / picked this pass. Disjointness is checked defensively even though distinct goals guarantee it;
   any colliding branch is dropped back to singleton dispatch. The batch branch name is a
   deterministic sha-256 of the sorted goals (idempotent re-runs; distinct sets never collide).

2. **Assembly (`swarm/agent.sh`).** Branch `batch/prove/<hash>` from `origin/main`, **cherry-pick**
   each constituent branch's tip prove commit (disjoint ADD-only ⇒ never conflicts; preserves the
   `prove(<goal>):` subject + author), Gate-B-validate the combined tree, push, open ONE PR.

3. **Merge with a MERGE COMMIT, not squash.** A batch is enrolled with `gh pr merge --auto
   --merge` (vs `--squash` for singletons). This keeps each constituent's original `prove(<goal>):`
   commit in `main`'s reachable history, so the leaderboard's `merge_times` (`git log --no-merges`)
   and `git_add_authors` (`git log --diff-filter=A -- library/index`, both **without**
   `--first-parent`) resolve every batched proof's merge-hour and author **with no leaderboard
   change**. A squash would collapse the K subjects into one `prove-batch(…)` and erase per-proof
   merge-time/author resolution. (Branch protection permits this: `required_linear_history=false`.)

4. **Governor accounting.** A batch is **one** admission: `submission_governor_allows` is consulted
   once, and a batch consumes one `gate-a` run (the binding `UNSORRY_MAX_GATE_A_IN_FLIGHT` meter)
   for K proofs — exactly the amortisation. Its `prove-batch(` title is deliberately distinct from
   `prove(`, so the open-prove-PR count and ADR-105's same-repo arm/rerun janitor treat it as its
   own kind.

5. **Dedup.** While a batch PR is open, its goals are published in a `Batch-Goals:` manifest line in
   the PR body; the dispatcher adds those to its dedup set (`dispatch_open_batch_goals`) so it never
   opens a redundant singleton for an already-batched goal.

6. **Failure handling (`batch-recovery-janitor.yml`).** A batch is **all-or-nothing per PR**, so one
   bad proof reddens all K. Recovery (a janitor mirroring ADR-105, with the pure decision in
   `batch.recover_action`) classifies each open batch PR's latest `gate-a`:
   - **cancellation cascade** (a leg cancelled by the merge firehose — reusing
     `finalization_recovery.gate_failure_is_cancellation`) ⇒ **re-run**, do not split.
   - **genuine failure** ⇒ **redispatch singly**: open a singleton PR for each constituent (whose
     `queued/prove/*` branch still exists — assembly never deletes it), then close the batch. Each
     proof then gets an isolated verdict; the bad one is identified by its own red gate and lingers
     exactly like any genuinely-failing singleton today, the K−1 good ones merge. Opening the
     singletons first establishes dedup so the set is never re-batched.

## Consequences

- **The queue drains up to K× faster per unit verifier budget.** With the env-load amortised, the
  same `UNSORRY_MAX_GATE_A_IN_FLIGHT` cap clears K proofs per slot-occupancy instead of one — the
  template flood is the ideal first batch (homogeneous, low-risk, hundreds deep).
- **Soundness is untouched (ADR-049, p=1).** Gate A verifies every proof file in the combined PR
  exactly as a singleton — `lake build` compiles all of them, nanoda checks each leaf, replay
  covers every new olean. The Lean kernel still decides each proof independently; no proof trusts
  another. The producer's local verification is never trusted (Gate A re-verifies from scratch).
- **Attribution & metrics are preserved with zero leaderboard change** — by the file-based counting
  and the merge-commit strategy (item 3). This is the load-bearing reason for `--merge` over
  `--squash`; it is asserted by tests and must not regress.
- **Off by default, fully reversible.** `UNSORRY_BATCH_SIZE=1` (the default) makes the dispatcher
  behave byte-for-byte as today. No goal file is touched (ADR-018). The batch path adds files only.
- **New trust surface is minimal.** The recovery janitor can close batch PRs and open singletons;
  it acts only on `prove-batch(` PRs and only opens singletons from already-pushed `queued/prove/*`
  branches — never fabricating proof content. CODEOWNERS still gates the gate/harness paths.

## Alternatives considered

- **Squash the batch (uniform with singletons).** Rejected: collapses the K `prove(<goal>):`
  subjects, breaking the leaderboard's per-proof merge-time/author resolution unless
  `tools/leaderboard` (a CODEOWNERS-gated path) is changed to parse a batch manifest from commit
  bodies. The merge-commit keeps the change to `/swarm/` + `tools/dispatch/` + the new janitor.
- **Bisect a failed batch.** More work to isolate the bad proof; redispatch-singly achieves the
  same K−1-good-proofs-still-land outcome with one extra round of singleton gates, reusing the
  existing isolated-singleton machinery. Bisection is a possible future optimisation (noted in
  SPEC-107-A) if genuine batch failures prove common.
- **Verify-many in a single gate job (gate-side batching).** Unnecessary: Gate A already verifies
  every file in a PR in one env-load, so PR-assembly batching captures the whole win with **no gate
  change** and no required-context (`gate-a`) change (ADR-058 invariant preserved).
- **Raise the in-flight cap / add runners instead.** Pure linear spend (#6751 L1); batching bends
  the per-proof cost and composes with a higher cap rather than competing with it.

## References

ADR-058 (governor caps / in-flight meter — a batch = one admission), ADR-075/106 (dispatch ordering
the batch fills from), ADR-064/071 (dispatch dedup — extended to batch PRs), ADR-005 (autonomous
merge — batches enrol with `--merge`), ADR-105 (finalization recovery — recovery pattern + the
`gate_failure_is_cancellation` classifier reused here; its arm/rerun janitor skips `prove-batch(`
titles, so batch recovery is owned by the new janitor), ADR-049 (p=1, kernel sole oracle —
unchanged), ADR-097/063 (nanoda leaf check + sharded replay — the cheap per-proof terms), ADR-018
(goal-statement immutability — batching adds files only). Roadmap #5683 (D1b), #5678, audit #6751.
SPEC-107-A specifies the module, the assembly, and the recovery janitor.
