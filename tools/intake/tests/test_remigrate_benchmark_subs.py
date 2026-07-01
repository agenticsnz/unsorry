"""Tests for the pre-ADR-116 benchmark sub-lemma re-pin migration."""
from __future__ import annotations

from pathlib import Path

from tools.intake.remigrate_benchmark_subs import (
    apply_plan,
    plan_migration,
    reopen_goal,
)

SHA = "a" * 64
TC = "leanprover/lean4:v4.24.0"
ML = "c5ea00351c28e24afc9f0f84379aa41082b1188f"


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, "utf-8")


def _register_suite(root: Path, name: str, top: str, obligations: list[str]) -> None:
    subs = ";".join(
        f"sub{chr(0x2080 + i)}≜⟨id≜{g},sha≜{SHA}⟩" for i, g in enumerate(obligations, 1)
    )
    _write(
        root / "targets" / name / "skeleton.aisp",
        f"𝔸5.1.skeleton.{name}@2026-06-25\nγ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜acme;domain≜math;toolchain≜{TC};mathlib≜{ML}}}\n"
        f"⟦Σ:Subs⟧{{{subs}}}\n⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
    )


def _decomp(root: Path, parent: str, subs: list[str], agent: str = "ag") -> None:
    body = ";".join(f"sub{chr(0x2080 + i)}≜⟨id≜{s},sha≜{SHA}⟩" for i, s in enumerate(subs, 1))
    _write(
        root / "decompositions" / f"{parent}.{agent}.aisp",
        f"𝔸5.1.decomp.{parent}.{agent}@2026-06-30\nγ≔unsorry.decomposition\n"
        f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}\n"
        f"⟦Σ:Subs⟧{{{body}}}\n⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
    )


def _goal(root: Path, gid: str, *, status: str, sha: str, parent: str) -> None:
    _write(
        root / "goals" / f"{gid}.aisp",
        f"𝔸5.1.goal.{gid}@2026-06-30\nγ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{\n  id≜{gid}\n  phase≜prove\n  status≜{status}\n  difficulty≜1\n}}\n"
        f"⟦Σ:Source⟧{{\n  src≜decompositions/{parent}.ag.aisp\n}}\n"
        f"⟦Γ:Deps⟧{{\n  deps≜⟨⟩\n}}\n"
        f"⟦Λ:Artifact⟧{{\n  lean≜goals/{gid}.lean\n  sha≜{sha}\n  aff≜1\n  depth≜1\n}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
    )
    _write(root / "goals" / f"{gid}.lean", f"import Mathlib\n\ntheorem thm_{gid.replace('-', '_')} : True := by\n  sorry\n")


def _prove(root: Path, gid: str, sha: str, name: str) -> None:
    """Give <gid> a REPO-pin proof: index entry + module + a proved proof-run."""
    _write(
        root / "library" / "index" / f"{sha}.aisp",
        f"𝔸5.1.lemma@2026-06-30\nγ≔unsorry.lemma\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{gid}; name≜{name}}}\n⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
    )
    _write(root / "library" / "Unsorry" / f"{name}.lean", f"import Mathlib\n\ntheorem {name} : True := trivial\n")
    _write(
        root / "proof-runs" / f"{gid}.ag.20260630t000000000000z-deadbeef.aisp",
        f"𝔸5.1.run@2026-06-30\nγ≔unsorry.proof.run\n"
        f"⟦Ω:Run⟧{{id≜r; goal≜{gid}; agent≜ag; outcome≜proved}}\n⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
    )


def _bench_fixture(root: Path) -> None:
    """A benchmark obligation `obl` decomposed into `obl-s1` (repo-proved) + `obl-s2`
    (unproved), plus an ORGANIC parent `org` with a repo-proved sub `org-s1`."""
    _register_suite(root, "putnam-v1", "putnam-v1-suite", ["obl"])
    _decomp(root, "obl", ["obl-s1", "obl-s2"])
    _goal(root, "obl-s1", status="proved", sha="b" * 64, parent="obl")
    _goal(root, "obl-s2", status="open", sha="∅", parent="obl")
    _prove(root, "obl-s1", "b" * 64, "obl_s1_lemma")
    # organic (no suite): a decomposition whose parent is not a registered obligation
    _decomp(root, "org", ["org-s1"])
    _goal(root, "org-s1", status="proved", sha="c" * 64, parent="org")
    _prove(root, "org-s1", "c" * 64, "org_s1_lemma")


def test_discovers_only_repo_proved_benchmark_subs(tmp_path):
    _bench_fixture(tmp_path)
    plans = plan_migration(tmp_path)
    subs = {p.sub for p in plans}
    assert subs == {"obl-s1"}  # obl-s2 unproved; org-s1 organic (no suite)


def test_plan_targets_the_right_artifacts(tmp_path):
    _bench_fixture(tmp_path)
    (plan,) = [p for p in plan_migration(tmp_path) if p.sub == "obl-s1"]
    assert plan.suite == "putnam-v1"
    assert plan.index_path == tmp_path / "library" / "index" / f"{'b' * 64}.aisp"
    assert plan.module_path == tmp_path / "library" / "Unsorry" / "obl_s1_lemma.lean"
    assert [r.name for r in plan.proof_runs] == [
        "obl-s1.ag.20260630t000000000000z-deadbeef.aisp"
    ]


def test_suite_filter(tmp_path):
    _bench_fixture(tmp_path)
    assert plan_migration(tmp_path, suite="putnam-v1")  # matches
    assert plan_migration(tmp_path, suite="minif2f-v1") == []  # no such subs


def test_parent_filter(tmp_path):
    _bench_fixture(tmp_path)
    assert {p.sub for p in plan_migration(tmp_path, parents={"obl"})} == {"obl-s1"}
    assert plan_migration(tmp_path, parents={"nope"}) == []


def test_idempotent_when_already_reopened(tmp_path):
    _bench_fixture(tmp_path)
    apply_plan(plan_migration(tmp_path))
    assert plan_migration(tmp_path) == []  # nothing left to do


def test_reopen_goal_sets_open_and_empty_sha(tmp_path):
    _bench_fixture(tmp_path)
    reopen_goal(tmp_path / "goals" / "obl-s1.aisp")
    text = (tmp_path / "goals" / "obl-s1.aisp").read_text("utf-8")
    assert "status≜open" in text and "sha≜∅" in text
    assert "status≜proved" not in text and "b" * 64 not in text


def test_apply_removes_artifacts_and_reopens(tmp_path):
    _bench_fixture(tmp_path)
    plans = plan_migration(tmp_path)
    apply_plan(plans)
    # repo-pin proof gone
    assert not (tmp_path / "library" / "index" / f"{'b' * 64}.aisp").exists()
    assert not (tmp_path / "library" / "Unsorry" / "obl_s1_lemma.lean").exists()
    assert not list((tmp_path / "proof-runs").glob("obl-s1.*.aisp"))
    # goal re-opened
    assert "status≜open" in (tmp_path / "goals" / "obl-s1.aisp").read_text("utf-8")
    # the untouched organic + unproved goals are unchanged
    assert (tmp_path / "library" / "Unsorry" / "org_s1_lemma.lean").exists()
    assert "status≜open" in (tmp_path / "goals" / "obl-s2.aisp").read_text("utf-8")
