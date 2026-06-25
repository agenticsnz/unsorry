"""Tests for benchmark-runs.json — per-run telemetry joined to suites (ADR-092)."""
from __future__ import annotations

import json
from pathlib import Path

from tools.leaderboard.benchmark_runs import (
    benchmark_runs,
    render_benchmark_runs_json,
    suite_run_stats,
    suite_runs,
)
from tools.leaderboard.registered_targets import registered_targets

SHA_A = "a" * 64


def _register_suite(root: Path, name: str, top: str, obligations) -> None:
    suite = root / "targets" / name
    suite.mkdir(parents=True, exist_ok=True)
    subs = ";".join(
        f"sub{chr(0x2080 + i)}≜⟨id≜{gid},sha≜{sha}⟩"
        for i, (gid, sha) in enumerate(obligations, 1)
    )
    credit = ";".join(f"{gid}≜credited" for gid, _ in obligations)
    suite.joinpath("skeleton.aisp").write_text(
        f"𝔸5.1.skeleton.{name}@2026-06-24\n"
        "γ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜acme;domain≜math;"
        "toolchain≜leanprover/lean4:v4.30.0;mathlib≜abc123}\n"
        f"⟦Σ:Subs⟧{{{subs}}}\n"
        f"⟦Κ:Credit⟧{{{credit}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def _proof_run(root, goal, *, run_id, solver, provider, model, outcome, solve_s, ended):
    d = root / "proof-runs"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{goal}.ag.{run_id}.aisp").write_text(
        f"𝔸5.1.run.{goal}.ag.{run_id}@2026-06-14\n"
        "γ≔unsorry.proof.run\n"
        f"⟦Ω:Run⟧{{id≜{run_id}; goal≜{goal}; agent≜ag; outcome≜{outcome}}}\n"
        f"⟦Π:Provenance⟧{{solver≜{solver}; provider≜{provider}; model≜{model}; effort≜high}}\n"
        f"⟦Γ:Goal⟧{{goal≜{goal}}}\n"
        f"⟦Λ:Metrics⟧{{attempts≜1; solve_s≜{solve_s}; ended≜{ended}; lessons≜0}}\n"
        "⟦Σ:Artifact⟧{sha≜∅}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def test_no_runs_is_empty_and_noop(tmp_path):
    assert benchmark_runs(tmp_path) == {"schema_version": 1, "suites": {}}
    json.loads(render_benchmark_runs_json(tmp_path))  # valid JSON


def test_suite_runs_joins_proof_runs_by_goal(tmp_path):
    _register_suite(tmp_path, "putnam-v1", "putnam-v1-suite", [("putnam-1988-b2", SHA_A)])
    _proof_run(tmp_path, "putnam-1988-b2", run_id="r1", solver="ada", provider="claude",
               model="opus", outcome="proved", solve_s=42, ended="2026-06-14T10:00:00Z")
    _proof_run(tmp_path, "putnam-1988-b2", run_id="r2", solver="bob", provider="openai",
               model="leanstral", outcome="failed", solve_s=99, ended="2026-06-14T11:00:00Z")
    # a run for a NON-benchmark goal is excluded
    _proof_run(tmp_path, "organic-x", run_id="r3", solver="cy", provider="lean",
               model="decide", outcome="proved", solve_s=1, ended="2026-06-14T09:00:00Z")

    rows = suite_runs(tmp_path)["putnam-v1"]
    assert [r["run_id"] for r in rows] == ["r1", "r2"]  # chronological, organic-x excluded
    proved, failed = rows[0], rows[1]
    assert proved["contributor"] == "ada" and proved["model"] == "claude/opus"
    assert proved["passed"] is True and proved["verification"] == "kernel"
    assert failed["outcome"] == "failed" and failed["passed"] is False
    assert failed["verification"] == "—"


def test_suite_run_stats_best_worst_and_rate(tmp_path):
    _register_suite(tmp_path, "putnam-v1", "putnam-v1-suite", [("g1", SHA_A)])
    _proof_run(tmp_path, "g1", run_id="r1", solver="ada", provider="claude", model="opus",
               outcome="proved", solve_s=30, ended="2026-06-14T10:00:00Z")
    _proof_run(tmp_path, "g1", run_id="r2", solver="ada", provider="claude", model="opus",
               outcome="proved", solve_s=70, ended="2026-06-14T11:00:00Z")
    _proof_run(tmp_path, "g1", run_id="r3", solver="bob", provider="x", model="y",
               outcome="failed", solve_s=5, ended="2026-06-14T12:00:00Z")
    s = suite_run_stats(tmp_path)["putnam-v1"]
    assert s["total_runs"] == 3 and s["successful_runs"] == 2 and s["failed_runs"] == 1
    assert s["success_rate"] == round(2 / 3, 4)
    assert s["best_solve_s"] == 30 and s["worst_solve_s"] == 70  # proved times only
    assert s["median_solve_s"] == 50 and s["contributors"] == 2


def test_stats_flow_into_registered_targets(tmp_path):
    _register_suite(tmp_path, "putnam-v1", "putnam-v1-suite", [("putnam-1988-b2", SHA_A)])
    _proof_run(tmp_path, "putnam-1988-b2", run_id="r1", solver="ada", provider="claude",
               model="opus", outcome="proved", solve_s=42, ended="2026-06-14T10:00:00Z")
    suite = registered_targets(tmp_path)["suites"][0]
    assert suite["run_snippet"] == "./swarm/run.sh --goal putnam-v1-suite"
    assert suite["stats"]["total_runs"] == 1 and suite["stats"]["best_solve_s"] == 42
