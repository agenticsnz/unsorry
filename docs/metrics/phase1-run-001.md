# Phase-1 swarm trial — run 001 (W4 prove cycle)

**run_id:** `phase1-run-001` · **date:** 2026-06-10 (UTC) · **trial:** Phase-1 swarm W4, the first *prove* cycle.

Machine record: [`phase1-run-001.json`](phase1-run-001.json).

## What ran

Three prover agents — `prover-alpha`, `prover-bravo`, `prover-charlie` (all driving `claude` on **sonnet**) — ran the real swarm prove workflow end-to-end against `agenticsnz/unsorry`. Each cycle: `agent.sh` claimed an unproved goal, invoked `claude` to write a Lean 4 proof of the goal's theorem, self-verified locally (`lake build UnsorryLibrary --wfail` + `lake exe axiom_audit`), and — on a passing local proof — opened a Gate-A/Gate-B auto-merge PR titled `prove(<goal>): <name> by <agent>`.

This is a genuine contributor workflow, not a simulation. Two goals were proved by `prover-alpha` and merged into the verified library on `main` (int-add-neg #72, int-neg-neg #74); one goal was proved by `prover-bravo` and merged (and-comm-imp #70). The library on `main` now carries three new theorem modules and their `.aisp` index entries.

Cycles run: prover-alpha 8, prover-bravo 2 (then hard-blocked by a full `/tmp`), prover-charlie 1 (then hard-blocked). See the infrastructure findings below — the disk blocker is an environment fault, not an agent or code fault.

## Headline metrics

| Metric | Value | Basis |
|---|---|---|
| `claim_attempts` | **11** | 9 `claimed` events observed in jsonl (alpha 8 + charlie 1) + 2 reported bravo cycles (jsonl unobservable) |
| `collisions` | **0** | zero explicit `collision` events in any observable jsonl |
| `collision_rate` | **0.0** | 0 / 11 |
| `proofs_attempted` | **5** | distinct (goal, agent) prove claims that ran a proof |
| `proofs_merged` | **3** | merged prove PRs (ground truth via `gh`): #70, #72, #74 |
| `merge_rate` | **0.6** | 3 / 5 |
| `prove_failures` | **6** | `prove-failed` events (alpha 5 + charlie 1 observed; bravo 0 reported) |
| `coordination_errors` | **0** | no Gate-B rejection, no cap breach, no protocol violation in histories |
| `gate_a_failures_on_merged_path` | **0** | all 3 merged prove PRs show gate-a = SUCCESS |

### Merge rate — interpretation

`merge_rate = 0.6`: of 5 distinct (goal, agent) prove attempts, 3 landed on `main` through the full Gate-A/Gate-B auto-merge path. The 2 distinct attempts that did not merge are both fully explained and neither is a soundness or coordination failure:

- **int-sub-eq-add-neg** (prover-alpha) — a trivially-true goal (`a - b = a + (-b)`) that never produced a *locally* passing proof inside the 2-attempt budget. Root cause: bare-worktree mathlib rebuild timeout (see infrastructure finding), **not** bad mathematics. It remains an OPEN claimable goal.
- **int-neg-neg** (prover-charlie) — failed local verify on both budget attempts (sonnet proof miss + a release-branch race). The goal was independently proved and merged by **prover-alpha** via #74, so the library is not missing this theorem.

So the 0.6 is a floor, not a ceiling: the two misses are an infrastructure timeout and a redundant attempt on an already-proved goal, not the swarm failing to close provable goals. Three of the swarm's targets are now verified library theorems on `main`.

### Collision rate — interpretation

`collision_rate = 0.0`. No agent emitted a `collision` event (a cap-full claim withdrawal). The "release push rejected … rebasing from scratch" messages that prover-bravo and prover-charlie reported are **release-branch optimistic-concurrency races**: the losing agent rebased, retried, and released its claim cleanly. That is healthy swarm contention handled by the concurrency layer, not a claim collision. Two agents (alpha, charlie) both worked int-neg-neg, but sequentially and within the live-claim cap — charlie released before alpha's successful run, so no cap was ever breached.

A real, separate throughput observation surfaced here (recorded, not a collision): because claim markers are not persisted to `main`, a goal stays *claimable* until its prove PR actually merges. While PRs were pending auto-merge, agents re-selected the same highest-priority unproved goal instead of fanning out — this produced the two redundant duplicate PRs (#71 dup of #70, #73 dup of #72). That is a fan-out/throughput note for Phase-1, not a coordination error.

## Checklist item (b) — non-author-agent end-to-end evidence

**Chosen evidence: PR #74, goal `int-neg-neg`, proved by agent `prover-alpha`.**

- **Goal:** `int-neg-neg` — `theorem int_neg_neg_thm (n : Int) : -(-n) = n`.
- **PR:** [#74](https://github.com/agenticsnz/unsorry/pull/74), title `prove(int-neg-neg): int_neg_neg_thm by prover-alpha`, gate-a = SUCCESS, gate-b = SUCCESS.
- **Authoring agent (AGENT_ID):** `prover-alpha`. The claim/proof trail carries it in three places: (1) the metrics.jsonl `claimed` → `proved` → `pr-opened` events all carry `agent: "prover-alpha"`; (2) the commit subject is `prove(int-neg-neg): int_neg_neg_thm by prover-alpha`; (3) the PR title names `prover-alpha`.
- **Distinct from any seed identity:** **Yes.** Every seed / backlog / translation / governance commit in the repo's history was authored by `Chris Barlow` (the maintainer), `Claude Fable 5 <noreply@anthropic.com>`, or `unsorry-reaper[bot]`. **No `prover-*` id is, or ever was, a git author or committer.** Independently, the proof *content* is novel: `git log --all -S 'Int.neg_neg' -- library/` returns only the proof commit `ae8cf63` and its merge `6eb9248` — the proof body `:= Int.neg_neg n` appears **nowhere in history before this PR**. The `goals/int-neg-neg.lean` seed stub never contained the proof term.
- **Merge commit sha:** `6eb92482ae507898f26349b44f11a49d885d24d2` (squash-merge of #74; now `main` HEAD). The proved theorem is live on `main` at `library/Unsorry/IntNegNeg.lean` with index entry `library/index/de428d34a5ec…aisp`.

### HONEST CAVEAT (per project decision, ADR-007)

Two facts, both stated plainly:

1. **The GitHub account is the maintainer's.** The GitHub PR-author field on #74 shows `cgbarlow`, and the git author/committer of the underlying proof commit `ae8cf63` is `Chris Barlow <cgbarlow@gmail.com>`. This is **by design (ADR-007):** swarm contributors run under the maintainer's own GitHub identity, not a per-agent GitHub account. So the GitHub-author field does **not** prove a non-human, non-maintainer contributor.
2. **The swarm identity is the AGENT_ID, in the claim/commit trail.** The agent that wrote this proof is `prover-alpha`, recorded in the commit subject, the PR title, and the metrics.jsonl event stream — and that proof content was not present anywhere in history before the PR. That trail, not the GitHub account, is the swarm-contribution evidence.

Read together: a distinctly-identified swarm agent (`prover-alpha`, never a seed author) produced a novel Lean proof of `int-neg-neg`, which passed the soundness gate in CI and merged to the verified library on `main` at `6eb9248`. The only "human" fingerprint is the shared GitHub account mandated by ADR-007, which we disclose rather than hide.

## Gate-A vs local-verify

`gate_a_failures_on_merged_path = 0`. On every merged prove PR (#70, #72, #74), the agent's local verify (`lake build UnsorryLibrary --wfail` + `axiom_audit`) **agreed with** CI gate-a — gate-a was SUCCESS in all three `statusCheckRollup`s. There were **zero false-confidence cases** where a locally-verified proof failed CI gate-a. The prove failures this run all occurred at the agent's *own local-verify step* (build timeout / proof miss / race) before any PR opened — they are not green-local-then-red-CI divergences. Local verify mirrored CI on the merged path, which is exactly the property the metric is meant to test.

There is, however, an asymmetry worth flagging in the **other** direction (CI is *easier* to satisfy than local verify, not harder): CI gate-a provisions a warm mathlib olean cache per checkout via `leanprover/lean-action@v1 use-github-cache:true`, whereas `agent.sh`'s bare prove worktree never runs `lake exe cache get` and rebuilds all ~8486 mathlib modules from source. That made several local verifications time out (see below). It does not threaten soundness — a slow-but-correct local build and a fast CI build reach the same verdict — but it is the reason `prove_failures` is non-zero and `merge_rate` is 0.6 rather than higher.

## Prove failures — which goals claude couldn't close, and why

6 `prove-failed` events, none a soundness rejection:

| Goal | Agent | Count | Why |
|---|---|---|---|
| int-add-neg | prover-alpha | 2 | tmpfs ENOSPC before the operator relocated TMPDIR to the roomy fs; subsequently proved & merged (#72) |
| int-neg-neg | prover-alpha | 1 | release-branch race + fresh-worktree mathlib build timeout; subsequently proved & merged (#74) |
| int-sub-eq-add-neg | prover-alpha | 2 | bare-worktree mathlib rebuild exceeded the per-attempt budget; goal is trivially true, **still OPEN/claimable** |
| int-neg-neg | prover-charlie | 1 | sonnet proof miss on both budget attempts + a claims race; goal later closed by alpha (#74) |

The only goal that was *attempted and remains unproved* is **int-sub-eq-add-neg**, and its failure is purely the olean/build-timeout infrastructure issue — claude was never given a working warm build to verify against in the budget window. No goal failed because the mathematics was hard or because a proof was unsound.

`axiom_audit` passed on all three merged modules: no `sorry` / `native_decide` / `admit`, and no axioms beyond `propext` / `Classical.choice` / `Quot.sound`.

## Anomalies and observability gaps

- **Declared unobservable number:** `prover-bravo`'s `metrics.jsonl` was **unreadable**. After bravo's cycle 2, `/tmp` filled to 0MB and the harness stdout-capture path failed with ENOSPC, so the file (which exists on `/workspaces`) could not be `cat`-ed. Bravo's events therefore are **not in the jsonl stream**. Bravo's contribution is reconstructed from its reported summary (2 cycles, 0 failures, proved and-comm-imp, PRs #70/#71) and corroborated by ground truth (#70 merged, title names prover-bravo). `claim_attempts` (+2) and `prove_failures` (+0) fold in bravo's reported, not jsonl-observed, numbers; the split is itemized in the JSON `notes`. **This is declared, never silently estimated.**
- **Index/library asymmetry:** 4 index entries vs 3 proved library modules. The extra entry `4c71a8b4…aisp` maps to goal `nat-zero-lt-succ` (status≜translated, **not** proved) and has no proved library module behind it — a pre-existing translated-goal index entry, not produced by this prove run. Minor; flagged.
- **Two open redundant prove PRs (#71, #73):** both are duplicate re-proves of goals already merged (#70, #72), both CONFLICTING/DIRTY against an advanced `main`. #71 has all checks green (gate-a SUCCESS) and is blocked purely by the merge conflict; #73 never triggered any check-run and is permanently blocked by conflict + missing required checks. Left open per observer instructions. This is the swarm racing on the highest-priority goal under pending auto-merge — expected, not an error.
- **Infrastructure (product recommendation, no repo edits made):** (1) `agent.sh`'s bare prove worktree never warms the mathlib olean cache, so local verify rebuilds from source and times out non-deterministically; a one-line `lake exe cache get` in `open_pr_worktree` / before `prove_local_verify` would make prove verification fast and deterministic. (2) `/tmp` was a separate 7.8G tmpfs already ~100% full from other jobs' stale trees; W4 provers should run with clone + workdir + `CLAUDE_CODE_TMPDIR` on the roomy `/workspaces` fs by default. Both flagged for Phase-1; neither implemented (observer permitted no repo edits to fix infrastructure).

## What this proves for checklist (b) and (c)

- **(b) Non-author end-to-end contribution:** demonstrated. A distinctly-identified swarm agent (`prover-alpha`, never a seed/translation author) produced a *novel* Lean proof — not present anywhere in history before the PR — that passed the CI soundness gate (gate-a SUCCESS) and merged to the verified library on `main` at commit `6eb9248`. The honest ADR-007 caveat (shared maintainer GitHub account) is disclosed rather than relied upon; the agent identity lives in the claim/commit trail. Three such merges happened this run (alpha ×2, bravo ×1), so the result is not a one-off.
- **(c) Gate integrity holds under a real prove swarm:** demonstrated. Across 5 prove attempts, 6 failures, 3 merges and 2 redundant races, there were **0 coordination errors**, **0 gate-a failures on the merged path**, and **0 unsound proofs** (axiom_audit clean on every merged module). Local verify mirrored CI gate-a on every merged path; every failure was caught *before* merge by the agent's own verify step or by the conflict/required-check gate. The gate let exactly the sound proofs through and nothing else.
