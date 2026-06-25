"""Tests for the registered-targets.json generator + cohort segregation (SPEC-092-A)."""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

from tools.leaderboard.registered_targets import (
    benchmark_goal_ids,
    pass_at_k,
    registered_targets,
    render_registered_targets_json,
)

SHA_A = "a" * 64
SHA_B = "b" * 64


# ----------------------------------------------------------------- fixtures


def _goal(root: Path, goal: str, difficulty: int, status: str = "proved") -> None:
    path = root / "goals"
    path.mkdir(parents=True, exist_ok=True)
    (path / f"{goal}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{goal}; status≜{status}; difficulty≜{difficulty}}}\n", "utf-8"
    )


def _solver(handle: str) -> str:
    return f"⟦Π:Provenance⟧{{solver≜{handle}}}\n"


def _index(root: Path, sha: str, goal: str, provenance: str = "") -> None:
    path = root / "library" / "index"
    path.mkdir(parents=True, exist_ok=True)
    (path / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-06-13\n"
        "γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{goal}}}\n"
        f"{provenance}⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def _register_suite(root: Path, name: str, top: str, obligations, credit=None) -> None:
    credit = credit or {}
    suite = root / "targets" / name
    suite.mkdir(parents=True, exist_ok=True)
    subs = ";".join(
        f"sub{chr(0x2080 + i)}≜⟨id≜{gid},sha≜{sha}⟩"
        for i, (gid, sha) in enumerate(obligations, 1)
    )
    credit_block = ";".join(f"{gid}≜{credit.get(gid, 'credited')}" for gid, _ in obligations)
    suite.joinpath("skeleton.aisp").write_text(
        f"𝔸5.1.skeleton.{name}@2026-06-24\n"
        "γ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜acme;domain≜math;"
        "toolchain≜leanprover/lean4:v4.30.0;mathlib≜abc123}\n"
        f"⟦Σ:Subs⟧{{{subs}}}\n"
        f"⟦Κ:Credit⟧{{{credit_block}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def _git(root: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(root), *args], check=True,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                   env={**os.environ, "GIT_AUTHOR_NAME": "T", "GIT_AUTHOR_EMAIL": "t@e.test",
                        "GIT_COMMITTER_NAME": "T", "GIT_COMMITTER_EMAIL": "t@e.test"})


# ------------------------------------------------------------- no targets/


def test_no_targets_is_empty_and_noop(tmp_path):
    assert benchmark_goal_ids(tmp_path) == set()
    assert registered_targets(tmp_path) == {"schema_version": 1, "suites": []}
    json.loads(render_registered_targets_json(tmp_path))  # valid JSON


# --------------------------------------------------------- benchmark ids


def test_benchmark_goal_ids_collects_top_and_obligations(tmp_path):
    _register_suite(tmp_path, "putnam", "putnam-top", [("putnam-1988-b2", SHA_A)])
    assert benchmark_goal_ids(tmp_path) == {"putnam-top", "putnam-1988-b2"}


# --------------------------------------------------------------- schema


def test_render_schema_shape(tmp_path):
    _goal(tmp_path, "putnam-1988-b2", 4)
    _register_suite(tmp_path, "putnam", "putnam-top", [("putnam-1988-b2", SHA_A)])
    payload = json.loads(render_registered_targets_json(tmp_path))
    assert payload["schema_version"] == 1
    suite = payload["suites"][0]
    assert set(suite) == {
        "id", "top", "run_snippet", "domain", "supplier", "mathlib_pin", "license",
        "cohort", "credited", "glue", "proved", "pass_at", "stats", "goals",
    }
    assert suite["id"] == "putnam"
    assert suite["mathlib_pin"] == "abc123"
    assert suite["cohort"] == "benchmark"
    assert suite["top"] == "putnam-top"
    assert suite["run_snippet"] == "./swarm/run.sh --goal putnam-top"  # runs the whole suite
    assert suite["stats"]["total_runs"] == 0  # no proof-runs in this fixture
    goal = suite["goals"][0]
    assert set(goal) == {"id", "difficulty", "status", "credit", "run_snippet"}
    assert goal["difficulty"] == 4
    assert goal["run_snippet"] == "./swarm/run.sh --goal putnam-1988-b2"


def test_status_from_library_index(tmp_path):
    _goal(tmp_path, "p-proved", 4)
    _goal(tmp_path, "p-open", 4)
    _index(tmp_path, SHA_A, "p-proved")
    _register_suite(tmp_path, "putnam", "putnam-top",
                    [("p-proved", SHA_A), ("p-open", SHA_B)])
    suite = registered_targets(tmp_path)["suites"][0]
    by_id = {g["id"]: g["status"] for g in suite["goals"]}
    assert by_id == {"p-proved": "proved", "p-open": "open"}
    assert suite["proved"] == 1


def test_credit_from_skeleton(tmp_path):
    _register_suite(tmp_path, "putnam", "putnam-top",
                    [("hard", SHA_A), ("easy", SHA_B)], credit={"easy": "glue"})
    suite = registered_targets(tmp_path)["suites"][0]
    assert suite["credited"] == 1 and suite["glue"] == 1
    by_id = {g["id"]: g["credit"] for g in suite["goals"]}
    assert by_id == {"hard": "credited", "easy": "glue"}


# --------------------------------------------------------------- pass@k


def test_pass_at_k_estimator():
    assert pass_at_k(10, 0, 1) == 0.0          # nothing accepted
    assert pass_at_k(10, 10, 1) == 1.0         # all accepted
    assert abs(pass_at_k(5, 1, 1) - 0.2) < 1e-9   # 1/5
    assert abs(pass_at_k(10, 5, 1) - 0.5) < 1e-9
    assert pass_at_k(3, 1, 5) == 0.0           # k > n
    assert pass_at_k(4, 2, 2) == 1.0 - (1 / 6)  # C(2,2)/C(4,2) = 1/6


# ------------------------------------------------------------ determinism


def test_render_is_deterministic(tmp_path):
    _goal(tmp_path, "putnam-1988-b2", 4)
    _register_suite(tmp_path, "putnam", "putnam-top", [("putnam-1988-b2", SHA_A)])
    assert render_registered_targets_json(tmp_path) == render_registered_targets_json(tmp_path)


# ------------------------------------------------- cohort segregation (the invariant)


def test_benchmark_proofs_stay_off_the_organic_board(tmp_path):
    from tools.leaderboard.generate import base_stats

    _git(tmp_path, "init")
    _goal(tmp_path, "organic-a", 3)
    _index(tmp_path, SHA_A, "organic-a", _solver("ada"))
    _goal(tmp_path, "bench-b", 4)
    _index(tmp_path, SHA_B, "bench-b", _solver("ada"))

    # control: before registering the benchmark, both proofs are organic
    assert base_stats(tmp_path)["credit"]["credited_proofs"] == 2

    # register bench-b as a benchmark obligation → it segregates off the organic board
    _register_suite(tmp_path, "putnam", "putnam-top", [("bench-b", SHA_B)])
    assert base_stats(tmp_path)["credit"]["credited_proofs"] == 1  # only organic-a

    # …and it appears on the benchmark surface instead
    assert registered_targets(tmp_path)["suites"][0]["proved"] == 1


def test_retired_suite_hidden_from_publish_but_still_segregated(tmp_path):
    """A suite marked ``retired`` in the registry drops off the published intent
    surface (the guild stops listing it) but its immutable goals stay benchmark —
    never re-counted as organic (ADR-018)."""
    _register_suite(tmp_path, "putnam-v1", "putnam-top", [("putnam-1988-b2", SHA_A)])
    _register_suite(tmp_path, "demo-v1", "demo-top", [("demo-add-comm", SHA_B)])
    reg = tmp_path / "docs" / "governance"
    reg.mkdir(parents=True, exist_ok=True)
    (reg / "admitted-domains.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "domains": [],
                "targets": [
                    {"package": "putnam-v1", "domain": "lean-math", "supplier": "trishullab"},
                    {"package": "demo-v1", "domain": "lean-math", "supplier": "agenticsnz",
                     "retired": True},
                ],
            }
        ),
        "utf-8",
    )
    # retired demo-v1 is excluded from the published surface…
    assert [s["id"] for s in registered_targets(tmp_path)["suites"]] == ["putnam-v1"]
    # …but its goals stay benchmark (kept out of the organic board)
    assert {"demo-top", "demo-add-comm"} <= benchmark_goal_ids(tmp_path)
