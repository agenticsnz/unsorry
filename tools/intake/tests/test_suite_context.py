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
