"""benchmark-runs.json — per-run telemetry for the benchmark cohort (ADR-092 / SPEC-092-A).

Joins ``proof-runs/`` records to their registered suite (by goal membership) so the
guild suite-detail page can render a table of *every* benchmark run — contributor,
model, time, performance, pass/fail, verification — and so ``registered-targets.json``
can carry best/worst summary stats per suite. Deterministic (sorted, no wall-clock),
and a no-op when no suite is registered or no run telemetry exists yet.

Verification: the Lean kernel is the sole gating oracle (Gate A), so every *proved*
run is kernel-verified (``"kernel"``); the diverse independent checkers (#5678 /
ADR-096) are not per-run telemetry yet, and a non-proved run carries no verdict
(``"—"``). Per-attempt pass@k is still future (SPEC-092-A §2) — these are terminal
runs, so the surfaced accuracy is the per-run success rate, not pass@k.
"""
from __future__ import annotations

import json
from pathlib import Path
from statistics import median

from tools.gate_b.records import parse_record
from tools.leaderboard.registered_targets import (
    _obligation_ids,
    retired_packages,
    suite_dirs,
)

SCHEMA_VERSION = 1

#: A suite with no runs yet (e.g. a freshly imported benchmark) — stable shape so the
#: card/detail page never special-cases "missing stats".
EMPTY_STATS: dict = {
    "total_runs": 0,
    "successful_runs": 0,
    "failed_runs": 0,
    "success_rate": 0.0,
    "best_solve_s": None,
    "worst_solve_s": None,
    "median_solve_s": None,
    "contributors": 0,
}


def _alias_map(root: Path) -> dict[str, str]:
    """A solver/handle → canonical github map, derived from contributor-aliases.json,
    so the runs table reflects the SAME consolidated attribution as the leaderboard
    (e.g. ``OceanLi`` → ``ohdearquant``). Keys are lower-cased git-author name,
    display_name, and github handle; unmapped handles pass through unchanged."""
    from tools.leaderboard.generate import contributor_aliases  # lazy: import cycle

    mapping: dict[str, str] = {}
    for key, value in contributor_aliases(root).items():
        github = value.get("github")
        if not github:
            continue
        mapping[key.split(" <")[0].strip().lower()] = github  # git-author name
        display = value.get("display_name")
        if display:
            mapping[display.lower()] = github
        mapping[github.lower()] = github
    return mapping


def _goal_to_suite(root: Path) -> dict[str, str]:
    """Map each benchmark goal id (the ``top`` sentinel + every obligation) to its
    suite — retired suites included, since their runs still belong to the suite."""
    mapping: dict[str, str] = {}
    retired = retired_packages(root)
    for suite in suite_dirs(root):
        if suite.name in retired:  # no card/detail page → no run table
            continue
        skeleton = parse_record((suite / "skeleton.aisp").read_text("utf-8"))
        top = skeleton.fields.get("top")
        if top:
            mapping[top] = suite.name
        for gid in _obligation_ids(skeleton):
            mapping[gid] = suite.name
    return mapping


def _model_label(run) -> str:
    parts = [p for p in (run.provider, run.model) if p]
    return "/".join(parts) if parts else (run.provider or "")


def _row(run, aliases: dict[str, str]) -> dict:
    return {
        "run_id": run.id,
        "goal": run.goal,
        "contributor": aliases.get(run.solver.lower(), run.solver),
        "model": _model_label(run),
        "ended": run.ended,
        "solve_s": run.solve_s,
        "outcome": run.outcome,
        "passed": run.succeeded,
        "verification": "kernel" if run.succeeded else "—",
    }


def suite_runs(root: Path) -> dict[str, list[dict]]:
    """suite id -> chronological list of its benchmark run rows."""
    from tools.leaderboard.generate import runs as _runs  # lazy: breaks the import cycle

    mapping = _goal_to_suite(root)
    aliases = _alias_map(root)
    by_suite: dict[str, list[dict]] = {}
    for run in _runs(root):
        suite = mapping.get(run.goal)
        if suite is not None:
            by_suite.setdefault(suite, []).append(_row(run, aliases))
    for rows in by_suite.values():
        rows.sort(key=lambda r: (r["ended"], r["run_id"]))
    return by_suite


def suite_run_stats(root: Path) -> dict[str, dict]:
    """suite id -> summary over its runs (pass rate + best/worst/median solve time)."""
    stats: dict[str, dict] = {}
    for suite, rows in suite_runs(root).items():
        solved = [r for r in rows if r["passed"]]
        times = [r["solve_s"] for r in solved if r["solve_s"] is not None]
        stats[suite] = {
            "total_runs": len(rows),
            "successful_runs": len(solved),
            "failed_runs": len(rows) - len(solved),
            "success_rate": round(len(solved) / len(rows), 4) if rows else 0.0,
            "best_solve_s": min(times) if times else None,
            "worst_solve_s": max(times) if times else None,
            "median_solve_s": int(median(times)) if times else None,
            "contributors": len({r["contributor"] for r in rows}),
        }
    return stats


def benchmark_runs(root: Path) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "suites": dict(sorted(suite_runs(root).items())),
    }


def benchmark_runs_path(root: Path) -> Path:
    return Path(root) / "docs" / "metrics" / "benchmark-runs.json"


def render_benchmark_runs_json(root: Path) -> str:
    return (
        json.dumps(benchmark_runs(root), ensure_ascii=False, indent=2, sort_keys=True)
        + "\n"
    )
