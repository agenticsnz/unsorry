# Swarm Metrics

Index of metric runs and the schema each machine record (`phase0-run-NNN.json`) follows.

Metric runs are recorded by a trial observer after each swarm trial. Each run lands as a
**docs PR through Gate B like everything else** — the observer opens a PR with the machine
record (`.json`), the human narrative (`.md`), and any index updates; required checks must be
green before auto-merge, and no metric run is ever pushed directly to `main`.

## Runs

| Run | Date | Trial | Records |
|---|---|---|---|
| `phase0-run-001` | 2026-06-10 | Phase-0 swarm trial W2 (3 supervised agents + 1 sweep agent, 10 backlog goals) | [phase0-run-001.json](phase0-run-001.json) · [phase0-run-001.md](phase0-run-001.md) |
| `gate-a-redteam-001` | 2026-06-10 | Gate A red team W3 (9 adversarial bypass vectors, real PRs) | [gate-a-redteam-001.md](gate-a-redteam-001.md) |
| `phase1-run-001` | 2026-06-10 | Phase-1 swarm W4 (first prove cycle: 3 prover agents on sonnet; merge_rate 0.6, 3 proofs merged to the verified library, 0 gate-a failures on the merged path) | [phase1-run-001.json](phase1-run-001.json) · [phase1-run-001.md](phase1-run-001.md) |
| `checklist-evidence` | 2026-06-10 | Contributor-readiness checklist W5 (items (a)–(f) adversarially verified; body of the v1.0.0 release) | [checklist-evidence.md](checklist-evidence.md) |

## Machine-record JSON schema

Top-level fields of `phase0-run-NNN.json`:

| Field | Type | Definition |
|---|---|---|
| `run_id` | string | Unique id of the metric run, `phase0-run-NNN`. |
| `date` | string (ISO-8601 date) | Date the trial ran (UTC). |
| `agents` | array of `{id, model, role}` | Agent ids and the model each ran on (`role` is `supervisor-driven` or `sweep`). |
| `metrics` | object | The computed metrics — see field table below. |
| `planted_pairs` | array of `{pair, shas, sha_equal, note}` | Result per planted paraphrase pair (identical meaning, different English). |
| `reap` | object `{run_url, removal_commit, reaped, kept, unparsable}` | Reaper evidence: Actions run URL and the `reap:` commit on the `claims` branch. |
| `pr_numbers` | array of int | All trial PR numbers (titles `tr(...)` / `converge(...)`). |
| `kill_criterion` | object `{metric, threshold, value, tripped}` | The fidelity kill criterion (SPEC-003-D) and whether this run tripped it. |
| `notes` | array of string | Caveats, anomalies, and observability gaps — anything partially unobservable is declared here, never silently estimated. |

### `metrics` fields

| Field | Type | Definition |
|---|---|---|
| `claim_attempts` | int | Count of `claimed` events **plus** `collision` events across all agents (incl. the sweep agent), from the agents' `metrics.jsonl` telemetry. |
| `collisions` | int | Count of explicit `collision` events (an agent found the goal's live-claim cap already filled and withdrew). |
| `collision_rate` | number | `collisions / claim_attempts` (0 if no attempts). |
| `translations_merged` | int | Merged trial PRs titled `tr(...)`. |
| `prs_total` | int | All trial PRs (`tr(...)` + `converge(...)`). |
| `gate_b_failures_on_first_attempt` | int | Trial PRs whose `gate-b` required check failed on its first attempt. |
| `validator_pass_rate` | number | (trial PRs whose `gate-b` check passed on first attempt) / (trial PRs total). |
| `goals_matched` | int | Goals whose final record is `status≜translated` (independent translations converged). |
| `goals_flagged` | int | Goals whose final record is `status≜flagged` (translations diverged after normalization). |
| `fp_rate` | number | `flagged / (matched + flagged)`. All Phase-0 goals are elementary known-true statements, so any flag is a false positive by construction. |
| `paraphrase_pairs_sha_equal` | int | Of the planted paraphrase pairs, how many ended with byte-equal final shas (secondary fidelity signal, **not** part of `fp_rate`). |
| `coordination_errors` | int | Malformed artifacts rejected by Gate B + double-claims beyond the GB014 cap + protocol violations visible in branch histories. Expected 0; each instance is described in `notes`. |

### Kill criterion

`fp_rate >= 0.20` trips the fidelity kill criterion (SPEC-003-D: "flag FP ≥ 20 % on
identical-meaning pairs"). If tripped, the response is ADR-008: drop to single translation
plus Lean back-translation.

## Phase-1 prove-cycle `metrics` fields

Prove-cycle runs (`phase1-run-NNN.json`) record proof production rather than translation, so
they carry a different `metrics` block (Phase-0 translation fields do not apply):

| Field | Type | Definition |
|---|---|---|
| `claim_attempts` | int | Count of `claimed` events (+ any `collision` events) across all provers' `metrics.jsonl`. Where a prover's jsonl is unobservable, its reported cycle count is folded in and the split is declared in `notes`. |
| `collisions` | int | Explicit `collision` telemetry events (cap-full claim withdrawal). Release-branch optimistic-concurrency races that the loser resolved by rebase-and-retry are **not** collisions. |
| `collision_rate` | number | `collisions / claim_attempts` (0 if no attempts). |
| `proofs_attempted` | int | Distinct `(goal, agent)` prove claims that ran a proof (re-claims of the same pair collapse to one). |
| `proofs_merged` | int | Merged prove PRs (titled `prove(<goal>): <name> by <agent>`), from `gh` ground truth. |
| `merge_rate` | number | `proofs_merged / proofs_attempted`. |
| `prove_failures` | int | `prove-failed` events — claude could not produce a locally-passing proof within the attempt budget. Not a soundness rejection unless `notes` says so. |
| `coordination_errors` | int | Gate-B rejections + double-claims beyond the live-claim cap + protocol violations in branch histories. Expected 0; each instance described in `notes`. |
| `gate_a_failures_on_merged_path` | int | Merged prove PRs whose `gate-a` required check was RED (proof passed the agent's local `lake build`+`axiom_audit` but CI disagreed). 0 means local verify mirrored CI; any >0 is a false-confidence finding described in `notes`. |
