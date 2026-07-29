"""Shared proof-index enumeration (see tools/proof_index.py)."""
from __future__ import annotations

from pathlib import Path

from tools import proof_index


def _index(dir_: Path, sha: str, goal: str) -> None:
    dir_.mkdir(parents=True, exist_ok=True)
    (dir_ / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-07-29\nγ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{goal.replace('-', '_')}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def _tree(tmp_path: Path) -> Path:
    _index(tmp_path / "library" / "index", "a" * 64, "repo-goal")
    _index(tmp_path / "targets" / "minif2f-v1" / "_verify" / "library" / "index",
           "b" * 64, "bench-goal")
    _index(tmp_path / "packages" / "unsorry-archive-0001" / "library" / "index",
           "c" * 64, "old-goal")
    return tmp_path


def test_all_three_namespaces_by_default(tmp_path):
    assert proof_index.proved_goals(_tree(tmp_path)) == {
        "repo-goal", "bench-goal", "old-goal"
    }


def test_namespaces_are_selectable(tmp_path):
    root = _tree(tmp_path)
    # tools.archive.plan is repo-only BY DESIGN: archiving moves a module into a
    # new package with its own toolchain, and a suite proof already lives in a
    # package pinned to its suite's Lean+mathlib.
    assert proof_index.proved_goals(root, suites=False, archives=False) == {"repo-goal"}
    assert proof_index.suite_proved_goals(root) == {"bench-goal"}


def test_repo_takes_precedence_over_later_namespaces(tmp_path):
    root = tmp_path
    _index(root / "library" / "index", "d" * 64, "dup-goal")
    _index(root / "targets" / "s" / "_verify" / "library" / "index", "d" * 64, "dup-goal")
    dirs = proof_index.index_dirs(root)
    assert dirs[0] == proof_index.repo_index_dir(root)
    assert proof_index.proved_goals(root) == {"dup-goal"}


def test_missing_directories_are_vacuous(tmp_path):
    assert proof_index.proved_goals(tmp_path) == set()
    assert proof_index.suite_proved_goals(tmp_path) == set()
