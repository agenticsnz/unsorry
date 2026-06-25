"""Hermetic unit tests for skeleton-validate checks 1-5 (SPEC-081-A §104-115).

Packages are built on the fly under ``tmp_path``; no network and no Lean (checks 6-7,
``--build``, are exercised by a CI fixture, not here).
"""
from __future__ import annotations

from pathlib import Path

from tools.governance.admission import parse_registry
from tools.intake.skeleton_validate import validate_package
from tools.lean_sig import statement_sha

SUPPLIER = "acme"


def _lean(name: str, statement: str) -> str:
    return f"import Mathlib\n\ntheorem {name} : {statement} := by\n  sorry\n"


def _goal_aisp(goal_id: str) -> str:
    return (
        f"𝔸5.1.goal.{goal_id}@2026-06-24\n"
        "γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{id≜{goal_id};phase≜prove;status≜open;difficulty≜3}}\n"
        f"⟦Σ:Source⟧{{src≜backlog/{goal_id}.md}}\n"
        "⟦Γ:Deps⟧{deps≜⟨⟩}\n"
        f"⟦Λ:Artifact⟧{{lean≜goals/{goal_id}.lean;sha≜∅}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )


def _write_goal(pkg: Path, goal_id: str, statement: str) -> str:
    (pkg / "goals").mkdir(parents=True, exist_ok=True)
    lean = _lean(goal_id.replace("-", "_"), statement)
    (pkg / "goals" / f"{goal_id}.lean").write_text(lean, "utf-8")
    (pkg / "goals" / f"{goal_id}.aisp").write_text(_goal_aisp(goal_id), "utf-8")
    return statement_sha(lean)


def _manifest(top: str = "demo-suite", supplier: str = SUPPLIER, domain: str = "math") -> str:
    return (
        "𝔸5.1.skeleton.demo-suite@2026-06-24\n"
        "γ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜{supplier};domain≜{domain};"
        "toolchain≜leanprover/lean4:v4.30.0;mathlib≜abc123}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )


def _decomp(parent: str, subs: list[tuple[str, str]], edges: list[tuple[str, str]]) -> str:
    sub_str = ";".join(
        f"{label}≜⟨id≜{sid},sha≜{sha}⟩" for label, (sid, sha) in
        zip([f"sub{chr(0x2080 + i)}" for i in range(1, len(subs) + 1)], subs)
    )
    edge_str = ";".join(f"Post({s})⊆Pre({d})" for s, d in edges)
    return (
        f"𝔸5.1.decomp.{parent}.{SUPPLIER}@2026-06-24\n"
        "γ≔unsorry.decomposition\n"
        f"⟦Ω:Decomp⟧{{parent≜{parent};agent≜{SUPPLIER}}}\n"
        f"⟦Σ:Subs⟧{{{sub_str}}}\n"
        f"⟦Γ:Edges⟧{{{edge_str}}}\n"
        "⟦Λ:Requeue⟧{∀s∈subs:goal(s)≫status≔open}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )


def _registry(package: str = "demo-suite", supplier: str = SUPPLIER, domain: str = "lean-math"):
    return parse_registry(
        {
            "schema_version": 1,
            "domains": [{"id": "lean-math", "verifier": "lean-kernel", "tier": "VERIFIED"}],
            "targets": [{"package": package, "domain": domain, "supplier": supplier}],
        }
    )


def build_valid(tmp_path: Path) -> Path:
    """A minimal admissible package: top demo-suite → {demo-a, demo-b}."""
    pkg = tmp_path / "demo-suite"
    _write_goal(pkg, "demo-suite", "True")
    sha_a = _write_goal(pkg, "demo-a", "1 + 1 = 2")
    sha_b = _write_goal(pkg, "demo-b", "2 + 2 = 4")
    (pkg / "skeleton.aisp").write_text(_manifest(), "utf-8")
    (pkg / "decompositions").mkdir(parents=True, exist_ok=True)
    (pkg / "decompositions" / f"demo-suite.{SUPPLIER}.aisp").write_text(
        _decomp(
            "demo-suite",
            [("demo-a", sha_a), ("demo-b", sha_b)],
            [("sub₁", "parent"), ("sub₂", "parent")],
        ),
        "utf-8",
    )
    return pkg


# ---------------------------------------------------------------- happy path


def test_valid_package_admits(tmp_path):
    result = validate_package(build_valid(tmp_path), _registry())
    assert result.ok, result.failures
    assert result.exit_code == 0
    assert result.leaves == ["demo-a", "demo-b"]


# ------------------------------------------------------------ 1. manifest


def test_missing_manifest_field_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    (pkg / "skeleton.aisp").write_text(_manifest(supplier=""), "utf-8")
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("1-manifest" in f and "supplier" in f for f in result.failures)


def test_bad_domain_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    (pkg / "skeleton.aisp").write_text(_manifest(domain="biology"), "utf-8")
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("1-manifest" in f and "domain" in f for f in result.failures)


def test_top_not_a_goal_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    (pkg / "skeleton.aisp").write_text(_manifest(top="ghost-top"), "utf-8")
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("top" in f for f in result.failures)


# ----------------------------------------------------------- 2. provenance


def test_unregistered_package_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    result = validate_package(pkg, _registry(package="something-else"))
    assert not result.ok
    assert any("2-provenance" in f and "curated target" in f for f in result.failures)


def test_non_verified_domain_rejected(tmp_path):
    # registry target points at a domain that is not admitted at VERIFIED
    reg = parse_registry(
        {
            "schema_version": 1,
            "domains": [{"id": "fusion", "verifier": "sim", "tier": "SCORED"}],
            "targets": [{"package": "demo-suite", "domain": "fusion", "supplier": SUPPLIER}],
        }
    )
    result = validate_package(build_valid(tmp_path), reg)
    assert not result.ok
    assert any("2-provenance" in f and "VERIFIED" in f for f in result.failures)


def test_supplier_mismatch_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    result = validate_package(pkg, _registry(supplier="someone-else"))
    assert not result.ok
    assert any("2-provenance" in f for f in result.failures)


# ----------------------------------------------------------- 3. obligations


def test_goal_not_open_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    aisp = (pkg / "goals" / "demo-a.aisp").read_text("utf-8").replace("status≜open", "status≜proved")
    (pkg / "goals" / "demo-a.aisp").write_text(aisp, "utf-8")
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("3-obligation" in f and "open" in f for f in result.failures)


def test_lean_not_ending_in_sorry_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    (pkg / "goals" / "demo-a.lean").write_text(
        "import Mathlib\n\ntheorem demo_a : 1 + 1 = 2 := by\n  norm_num\n", "utf-8"
    )
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("3-obligation" in f and "sorry" in f for f in result.failures)


# --------------------------------------------------------------- 4. edges


def test_dangling_sub_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    sha = statement_sha((pkg / "goals" / "demo-b.lean").read_text("utf-8"))
    (pkg / "decompositions" / f"demo-suite.{SUPPLIER}.aisp").write_text(
        _decomp("demo-suite", [("demo-a", sha), ("ghost-sub", sha)],
                [("sub₁", "parent"), ("sub₂", "parent")]),
        "utf-8",
    )
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("4-edges" in f and "ghost-sub" in f for f in result.failures)


def test_cycle_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    sha_a = statement_sha((pkg / "goals" / "demo-a.lean").read_text("utf-8"))
    sha_b = statement_sha((pkg / "goals" / "demo-b.lean").read_text("utf-8"))
    (pkg / "decompositions" / f"demo-suite.{SUPPLIER}.aisp").write_text(
        _decomp("demo-suite", [("demo-a", sha_a), ("demo-b", sha_b)],
                [("parent", "sub₁"), ("sub₁", "parent")]),  # parent→a and a→parent
        "utf-8",
    )
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("4-edges" in f and "cycle" in f for f in result.failures)


def test_orphan_goal_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    _write_goal(pkg, "demo-orphan", "3 + 3 = 6")  # never referenced as a sub
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("4-edges" in f and "demo-orphan" in f for f in result.failures)


def test_sub_sha_mismatch_rejected(tmp_path):
    pkg = build_valid(tmp_path)
    wrong = "f" * 64
    sha_a = statement_sha((pkg / "goals" / "demo-a.lean").read_text("utf-8"))
    (pkg / "decompositions" / f"demo-suite.{SUPPLIER}.aisp").write_text(
        _decomp("demo-suite", [("demo-a", sha_a), ("demo-b", wrong)],
                [("sub₁", "parent"), ("sub₂", "parent")]),
        "utf-8",
    )
    result = validate_package(pkg, _registry())
    assert not result.ok
    assert any("4-edges" in f and "demo-b" in f and "sha" in f for f in result.failures)


# ------------------------------------------------------------- 5. padding


def _build_passthrough(tmp_path: Path) -> Path:
    pkg = tmp_path / "demo-suite"
    _write_goal(pkg, "demo-suite", "True")
    sha_a = _write_goal(pkg, "demo-a", "True")  # identical statement → pass-through
    (pkg / "skeleton.aisp").write_text(_manifest(), "utf-8")
    (pkg / "decompositions").mkdir(parents=True, exist_ok=True)
    (pkg / "decompositions" / f"demo-suite.{SUPPLIER}.aisp").write_text(
        _decomp("demo-suite", [("demo-a", sha_a)], [("sub₁", "parent")]), "utf-8"
    )
    return pkg


def test_passthrough_warns_by_default(tmp_path):
    result = validate_package(_build_passthrough(tmp_path), _registry())
    assert result.ok  # advisory only
    assert any("5-padding" in w for w in result.warnings)


def test_passthrough_fails_under_strict(tmp_path):
    result = validate_package(_build_passthrough(tmp_path), _registry(), strict=True)
    assert not result.ok
    assert any("5-padding" in f for f in result.failures)


# ----------------------------------------------------------------- misc


def test_missing_package_dir_is_error(tmp_path):
    result = validate_package(tmp_path / "nope", _registry())
    assert result.error is not None
    assert result.exit_code == 2


def test_json_render_shape_stable(tmp_path):
    import json

    from tools.intake.skeleton_validate import _render

    result = validate_package(build_valid(tmp_path), _registry())
    payload = json.loads(_render(result, as_json=True))
    assert set(payload) == {
        "package", "ok", "exit", "failures", "warnings", "leaves",
        "credited", "glue", "error",
    }
    assert payload["ok"] is True
    assert payload["leaves"] == ["demo-a", "demo-b"]
