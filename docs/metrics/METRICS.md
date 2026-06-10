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
