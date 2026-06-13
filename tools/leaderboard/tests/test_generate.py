import json
from pathlib import Path

from tools.leaderboard.generate import base_stats, main, proofs, render, render_json


def _index(root: Path, sha: str, goal: str, provenance: str = "") -> None:
    path = root / "library" / "index"
    path.mkdir(parents=True, exist_ok=True)
    (path / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-06-13\n"
        "γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{goal}}}\n"
        f"{provenance}"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def _goal(root: Path, goal: str, difficulty: int, status: str = "open") -> None:
    path = root / "goals"
    path.mkdir(parents=True, exist_ok=True)
    (path / f"{goal}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{goal}; status≜{status}; difficulty≜{difficulty}}}\n",
        encoding="utf-8",
    )


def _run(
    root: Path,
    goal: str,
    run_id: str,
    outcome: str,
    *,
    attempts: int,
    solve_s: int,
    solver: str = "perttu",
    provider: str = "codex",
    model: str = "gpt-5.1-codex",
    lessons: int | None = None,
    lesson_sig: str | None = None,
) -> None:
    agent = "oma-2-c50d"
    path = root / "proof-runs"
    path.mkdir(parents=True, exist_ok=True)
    sha = "a" * 64 if outcome == "proved" else "∅"
    metrics = f"attempts≜{attempts}; solve_s≜{solve_s}; ended≜2026-06-13T12:00:00Z"
    if lessons is not None:
        metrics += f"; lessons≜{lessons}"
    lesson_block = "" if lesson_sig is None else f"⟦Δ:Lesson⟧{{sig≜{lesson_sig}}}\n"
    (path / f"{goal}.{agent}.{run_id}.aisp").write_text(
        f"𝔸5.1.run.{goal}.{agent}.{run_id}@2026-06-13\n"
        "γ≔unsorry.proof.run\n"
        f"⟦Ω:Run⟧{{id≜{run_id}; goal≜{goal}; agent≜{agent}; "
        f"outcome≜{outcome}}}\n"
        f"⟦Π:Provenance⟧{{solver≜{solver}; provider≜{provider}; model≜{model}; "
        "effort≜xhigh}\n"
        f"⟦Λ:Metrics⟧{{{metrics}}}\n"
        f"⟦Σ:Artifact⟧{{sha≜{sha}}}\n"
        f"{lesson_block}"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def test_historical_entries_are_unknown_not_guessed(tmp_path):
    _goal(tmp_path, "old-goal", 4)
    _index(tmp_path, "a" * 64, "old-goal")
    data = proofs(tmp_path)
    assert data[0].solver is None
    assert "1 historical/unknown" in render(tmp_path)
    assert "No attributed work yet" in render(tmp_path)


def test_base_stats_derive_failure_and_efficiency_metrics(tmp_path):
    provenance = (
        "⟦Π:Provenance⟧{solver≜perttu; agent≜oma-2-c50d; provider≜codex; "
        "model≜gpt-5.1-codex; effort≜xhigh; attempts≜2; solve_s≜90}\n"
    )
    _goal(tmp_path, "goal-ok", 4, "proved")
    _goal(tmp_path, "goal-hard", 5, "blocked")
    _index(tmp_path, "a" * 64, "goal-ok", provenance)
    _run(
        tmp_path,
        "goal-ok",
        "20260613t120000000000z-11111111",
        "proved",
        attempts=2,
        solve_s=90,
    )
    _run(
        tmp_path,
        "goal-hard",
        "20260613t120100000000z-22222222",
        "decomposed",
        attempts=3,
        solve_s=210,
    )

    stats = base_stats(tmp_path)
    assert stats["outcomes"] == {
        "runs": 2,
        "successes": 1,
        "failures": 1,
        "run_success_rate": 0.5,
        "attempts": 5,
        "failed_attempts": 4,
        "attempt_yield": 0.2,
        "total_solve_s": 300,
        "median_solve_s": 150,
        "p90_solve_s": 210,
        "successes_per_recorded_hour": 12.0,
    }
    assert stats["contributors"][0]["verified_proofs"] == 1
    assert stats["contributors"][0]["difficulty_points"] == 4
    assert stats["models"][0]["runs"] == 2
    assert stats["queue"]["status_counts"] == {"blocked": 1, "proved": 1}
    assert json.loads(render_json(tmp_path))["schema_version"] == 1

    out = render(tmp_path)
    assert "Run success rate | 50.0%" in out
    assert "Failed attempts | 4" in out
    assert "[@perttu](https://github.com/perttu) | 1 | 2 | 50.0% | 4 | 4" in out
    assert "`codex / gpt-5.1-codex` | 1 | 2 | 50.0% | 4" in out


def test_lesson_telemetry_is_ignored_by_leaderboard(tmp_path):
    # ADR-024: the optional lessons count and ⟦Δ:Lesson⟧ sig are advisory; the
    # leaderboard must derive identical statistics with or without them.
    plain = tmp_path / "plain"
    laden = tmp_path / "laden"
    for root in (plain, laden):
        _goal(root, "g", 4, "blocked")
    _run(plain, "g", "20260613t120000000000z-11111111", "failed", attempts=3, solve_s=90)
    _run(
        laden,
        "g",
        "20260613t120000000000z-11111111",
        "failed",
        attempts=3,
        solve_s=90,
        lessons=2,
        lesson_sig="unsolved goals ⊢ n + 0 = n",
    )
    assert base_stats(plain) == base_stats(laden)


def test_check_and_write_modes_cover_markdown_and_json(tmp_path):
    _goal(tmp_path, "g", 1)
    _index(tmp_path, "a" * 64, "g")
    assert main(["--check", str(tmp_path)]) == 1
    assert main(["--write", str(tmp_path)]) == 0
    assert main(["--check", str(tmp_path)]) == 0
    assert (tmp_path / "docs" / "metrics" / "community-stats.json").is_file()
