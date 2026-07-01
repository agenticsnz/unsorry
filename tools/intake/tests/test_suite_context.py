"""Tests for the goal→suite verifier-context resolver (ADR-099 / SPEC-099-A §3)."""
from __future__ import annotations

from pathlib import Path

from tools.intake.suite_context import goal_suite_context, main

V424 = "leanprover/lean4:v4.24.0"
REV24 = "c5ea00351c28e24afc9f0f84379aa41082b1188f"
SHA = "a" * 64


def _register_suite(root: Path, name, top, obligations, *, toolchain=V424, mathlib=REV24):
    suite = root / "targets" / name
    suite.mkdir(parents=True, exist_ok=True)
    subs = ";".join(
        f"sub{chr(0x2080 + i)}≜⟨id≜{gid},sha≜{SHA}⟩" for i, gid in enumerate(obligations, 1)
    )
    suite.joinpath("skeleton.aisp").write_text(
        f"𝔸5.1.skeleton.{name}@2026-06-25\n"
        "γ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜acme;domain≜math;"
        f"toolchain≜{toolchain};mathlib≜{mathlib}}}\n"
        f"⟦Σ:Subs⟧{{{subs}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def _register_decomp(root: Path, parent, subs, *, agent="agent-x"):
    """Write a decomposition record linking ``subs`` (ids) to ``parent`` (ADR-009).

    Mirrors the on-disk ``decompositions/<parent>.<agent>.aisp`` shape: a ``⟦Ω:Decomp⟧``
    ``parent`` field and a ``⟦Σ:Subs⟧`` block of content-addressed sub ids."""
    ddir = root / "decompositions"
    ddir.mkdir(parents=True, exist_ok=True)
    sub_lines = "".join(
        f"  sub{chr(0x2080 + i)}≜⟨id≜{sid},sha≜{SHA}⟩\n" for i, sid in enumerate(subs, 1)
    )
    ddir.joinpath(f"{parent}.{agent}.aisp").write_text(
        f"𝔸5.1.decomp.{parent}.{agent}@2026-06-30\n"
        "γ≔unsorry.decomposition\n"
        f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}\n"
        f"⟦Σ:Subs⟧{{\n{sub_lines}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )


def test_decomposition_sub_inherits_obligation_context(tmp_path):
    # (a) A direct decomposition sub of a benchmark obligation inherits the SAME suite
    # context as the obligation — the ADR-116 inheritance edge.
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["aime-1983-p9", "minif2f-b"])
    _register_decomp(tmp_path, "aime-1983-p9", ["aime-1983-p9-s1", "aime-1983-p9-s2"])
    assert goal_suite_context(tmp_path, "aime-1983-p9-s1") == {
        "suite": "minif2f-v1",
        "toolchain": V424,
        "mathlib": REV24,
        "verify_dir": "targets/minif2f-v1/_verify",
        "build_target": "Minif2fV1",
    }
    # identical to the obligation's own context (inherited, not merely non-None)
    assert goal_suite_context(tmp_path, "aime-1983-p9-s1") == goal_suite_context(
        tmp_path, "aime-1983-p9"
    )


def test_grandchild_decomposition_sub_inherits(tmp_path):
    # (b) A sub-of-a-sub (grandchild) resolves by walking the chain to the obligation.
    # The grandchild uses a CURATED (non ``-sN``) id to prove resolution does not depend
    # on the id suffix — it follows the decomposition graph, not a name pattern.
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["putnam-1962-a1"])
    _register_decomp(tmp_path, "putnam-1962-a1", ["putnam-1962-a1-s1"])
    _register_decomp(tmp_path, "putnam-1962-a1-s1", ["cauchy-schwarz-helper"])
    assert goal_suite_context(tmp_path, "cauchy-schwarz-helper")["suite"] == "minif2f-v1"


def test_decomposition_sub_of_non_obligation_is_none(tmp_path):
    # (c) A decomposition sub whose parent chain never reaches an obligation/top stays
    # organic → None (the repo-pin path is unchanged for organic decompositions).
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    _register_decomp(tmp_path, "some-organic-goal", ["some-organic-goal-s1"])
    assert goal_suite_context(tmp_path, "some-organic-goal-s1") is None


def test_obligation_and_organic_unchanged_with_decompositions(tmp_path):
    # (d) Regression: with decomposition records present, an obligation still resolves
    # directly and an unrelated organic goal still resolves to None — byte-identical to
    # the pre-ADR-116 behaviour.
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    _register_decomp(tmp_path, "minif2f-a", ["minif2f-a-s1"])
    assert goal_suite_context(tmp_path, "minif2f-a")["suite"] == "minif2f-v1"
    assert goal_suite_context(tmp_path, "totally-unrelated") is None


def test_resolves_obligation_to_suite_pin(tmp_path):
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a", "minif2f-b"])
    ctx = goal_suite_context(tmp_path, "minif2f-a")
    assert ctx == {
        "suite": "minif2f-v1",
        "toolchain": V424,
        "mathlib": REV24,
        "verify_dir": "targets/minif2f-v1/_verify",
        "build_target": "Minif2fV1",
    }


def test_resolves_top_sentinel(tmp_path):
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    assert goal_suite_context(tmp_path, "minif2f-v1-suite")["suite"] == "minif2f-v1"


def test_organic_goal_resolves_to_none(tmp_path):
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    assert goal_suite_context(tmp_path, "some-organic-goal") is None


def test_no_targets_is_none(tmp_path):
    assert goal_suite_context(tmp_path, "anything") is None


def test_cli_prints_tsv_for_benchmark_goal(tmp_path, capsys):
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    assert main(["minif2f-a", "--root", str(tmp_path)]) == 0
    out = capsys.readouterr().out.strip()
    assert out == f"{V424}\t{REV24}\ttargets/minif2f-v1/_verify\tMinif2fV1"


def test_cli_empty_for_organic_goal(tmp_path, capsys):
    _register_suite(tmp_path, "minif2f-v1", "minif2f-v1-suite", ["minif2f-a"])
    assert main(["organic", "--root", str(tmp_path)]) == 0
    assert capsys.readouterr().out == ""
