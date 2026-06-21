# SPEC-070-A: Duplicate-Verifier-Waste Metric

Implements: [ADR-070](../ADR-070-Duplicate-Verifier-Waste-Metric.md) · Status: Living · Updated: 2026-06-18

The contract for step **2a** of the Phase-2 plan (SPEC-053-A §8.1): a read-only
metric that quantifies the Gate A capacity claimless fork duplicates waste, so the
build/no-build decision for sharded selection (§8.3) and the fork-writable lease
(§8.4) is evidence-gated.

## 1. Deliverables

1. **`tools/repo/fork_waste.py`** — a pure summariser + a stdin/CLI front end.
2. **`docs/metrics/fork-waste.json`** — the published metric artifact.
3. **A scheduled `fork-waste` workflow** — refreshes the artifact (the
   `queue-board` pattern: `REFRESH_TOKEN`, report-only when unset, `[skip ci]`).
4. **Tests** — `tools/repo/tests/test_fork_waste.py` (pytest).

## 2. Input

A list of prove PRs as `gh pr list` JSON objects. Required fields per PR:

```
gh pr list --state all --limit 1000 \
  --json number,title,state,isCrossRepository,mergedAt
```

- `title` — used to filter `prove(<goal>):` PRs (ADR-026) and extract `<goal>`.
- `isCrossRepository` — true ⇒ a fork PR.
- `state` — `OPEN` | `MERGED` | `CLOSED`.
- `mergedAt` — non-null ⇒ merged (a `CLOSED` PR with null `mergedAt` is the
  **closed-unmerged** loser).

Non-prove titles are ignored. Best-effort: malformed/empty input yields a
zero-valued summary, never an error.

## 3. Pure summariser

`summarize(prs) -> dict` is a function of its argument only (no network, no clock)
so it is hermetically unit-tested. It returns:

```json
{
  "prove_prs": 0,
  "fork_prove_prs": 0,
  "fork_merged": 0,
  "fork_open": 0,
  "fork_closed_unmerged": 0,
  "fork_waste_ratio": 0.0,
  "goals_with_multiple_prove_prs": 0,
  "goals_with_fork_collision": 0,
  "estimated_wasted_gate_a_runs": 0,
  "top_collisions": [
    { "goal": "<id>", "prove_prs": 3, "fork_prove_prs": 2, "merged": 1 }
  ]
}
```

Definitions:

- **fork_closed_unmerged** — cross-repo prove PRs with `state == CLOSED` and null
  `mergedAt`. These are the wasted ones (each ran ≥1 Gate A and did not land).
- **fork_waste_ratio** — `fork_closed_unmerged / fork_prove_prs` (0.0 when no fork
  prove PRs; rounded to 4 dp).
- **goals_with_fork_collision** — goals with `prove_prs > 1` **and**
  `fork_prove_prs ≥ 1`.
- **estimated_wasted_gate_a_runs** — equals `fork_closed_unmerged` (a **lower
  bound**: a PR may trigger Gate A more than once across pushes).
- **top_collisions** — colliding goals, worst first (by `prove_prs`, then by
  `fork_prove_prs`, then `goal`), capped (default 10).

## 4. CLI

```
# summarise stdin → JSON on stdout
gh pr list --state all --limit 1000 --json number,title,state,isCrossRepository,mergedAt \
  | python3 -m tools.repo.fork_waste summarize

# also write the published artifact + print a human one-liner
… | python3 -m tools.repo.fork_waste summarize --write docs/metrics/fork-waste.json
```

`--write <path>` writes the JSON (a `generated` timestamp may be added by the
caller/workflow, never inside `summarize` — keeping it pure) and prints a
human-readable summary line to stderr. Unknown subcommand → usage + exit 2.

## 5. Refresh workflow

`.github/workflows/fork-waste.yml`, modelled on `queue-board.yml`:

- `schedule` (cron, e.g. hourly) + `workflow_dispatch`.
- Checks out, sets up Python, runs `gh pr list … | … summarize --write
  docs/metrics/fork-waste.json`, commits the artifact with `[skip ci]` and pushes
  via `REFRESH_TOKEN`. **Unset token ⇒ report-only** (compute + print, no commit).
- `permissions: contents: write` (to commit the artifact) — read-only `gh` for the
  PR list.

## 6. Quality bar

- `python3 -m pytest tools/repo/tests/test_fork_waste.py -q` — green. Covers:
  prove-title filter + goal extraction; cross-repo partition; closed-unmerged =
  waste (merged/open are not); waste ratio incl. zero-division; collision count;
  top-collisions ordering + cap; CLI stdin/`--write`/bad-input/usage.
- The workflow YAML parses and follows the `queue-board` token pattern.
- No harness coupling: nothing in `swarm/` imports this; it is operator/analytics
  tooling only.

## 7. Out of scope (deferred)

- Exact per-run Gate A minutes (PR outcome is the MVP proxy).
- A board/HTML page for the metric (JSON artifact only for now).
- Any control-path use of the metric (it is advisory; never gates selection,
  admission, or merge).
- The Phase-2 mitigations the metric gates — sharded selection (SPEC-053-A §8.3),
  the lease (§8.4), and identity/quota (SPEC-054-A §7).
