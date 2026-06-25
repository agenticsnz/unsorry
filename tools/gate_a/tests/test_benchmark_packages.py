"""Tests for benchmark suite verification at the suite pin (ADR-099 / SPEC-099-A §2).
Hermetic — the lake subprocess seam is injected; no Lean needed."""
from __future__ import annotations

import subprocess
from pathlib import Path

from tools.gate_a.benchmark_packages import (
    benchmark_verify_roots,
    changed_benchmark_roots,
    validate_benchmark_package,
    validate_changed,
    verify_root_for_path,
)

LAKEFILE = (
    'name = "minif2fV1"\nversion = "0.1.0"\ndefaultTargets = ["Minif2fV1"]\n\n'
    '[[require]]\nname = "mathlib"\nscope = "leanprover-community"\nrev = "REV24"\n\n'
    '[[lean_lib]]\nname = "Minif2fV1"\nsrcDir = "library"\nglobs = ["Unsorry.+"]\n'
)


def _verify_pkg(root: Path, suite: str = "minif2f-v1", *, modules=None, toolchain=True):
    """Scaffold a suite verification package on disk. ``modules`` maps a module file
    (under library/) to its contents."""
    vctx = root / "targets" / suite / "_verify"
    vctx.mkdir(parents=True, exist_ok=True)
    (vctx / "lakefile.toml").write_text(LAKEFILE, "utf-8")
    if toolchain:
        (vctx / "lean-toolchain").write_text("leanprover/lean4:v4.24.0\n", "utf-8")
    for rel, contents in (modules or {}).items():
        path = vctx / "library" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, "utf-8")
    return vctx


def _ok(argv, **_kw):
    return subprocess.CompletedProcess(argv, 0, "", "")


# ---------------------------------------------------------------- discovery


def test_benchmark_verify_roots_discovers_scaffolded_suites(tmp_path):
    _verify_pkg(tmp_path, "minif2f-v1")
    (tmp_path / "targets" / "no-verify-yet").mkdir(parents=True)  # not scaffolded → ignored
    roots = benchmark_verify_roots(tmp_path)
    assert roots == [tmp_path / "targets" / "minif2f-v1" / "_verify"]


def test_verify_root_for_path(tmp_path):
    _verify_pkg(tmp_path, "minif2f-v1")
    assert verify_root_for_path(tmp_path, "targets/minif2f-v1/_verify/library/Unsorry/A.lean") == (
        tmp_path / "targets" / "minif2f-v1" / "_verify"
    )
    assert verify_root_for_path(tmp_path, "targets/minif2f-v1/skeleton.aisp") is None
    assert verify_root_for_path(tmp_path, "library/Unsorry/A.lean") is None


def test_changed_benchmark_roots_baseless_returns_all(tmp_path):
    _verify_pkg(tmp_path, "minif2f-v1")
    assert changed_benchmark_roots(tmp_path, None) == benchmark_verify_roots(tmp_path)


# -------------------------------------------------------------- validation


def test_open_suite_no_modules_is_ok_without_building(tmp_path):
    """A suite with no discharged obligations yet (empty library) needs no kernel
    build — validation is a no-op (returns 0, never invokes lake)."""
    _verify_pkg(tmp_path, "minif2f-v1")  # no modules
    calls = []

    def runner(argv, **_kw):
        calls.append(tuple(argv))
        return _ok(argv)

    assert validate_benchmark_package(tmp_path, tmp_path / "targets" / "minif2f-v1" / "_verify", runner) == 0
    assert calls == []  # no cache get / lake build for an open suite


def test_proved_module_kernel_built_at_pin(tmp_path):
    """A discharged obligation (sorry-free module) is kernel-verified: cache get +
    `lake build --wfail` run IN the suite package (cwd), so it builds at the suite pin."""
    vctx = _verify_pkg(
        tmp_path, "minif2f-v1",
        modules={"Unsorry/Minif2fA.lean": "import Mathlib\n\ntheorem minif2f_a : 1 = 1 := rfl\n"},
    )
    calls = []

    def runner(argv, **kwargs):
        calls.append((tuple(argv), kwargs.get("cwd")))
        return _ok(argv)

    assert validate_benchmark_package(tmp_path, vctx, runner) == 0
    argvs = [a for a, _ in calls]
    assert ("lake", "exe", "cache", "get") in argvs
    assert ("lake", "build", "Minif2fV1", "--wfail") in argvs
    # every lake call ran in the suite package, never the repo root → the suite pin
    assert all(cwd == str(vctx) for _, cwd in calls)


def test_forbidden_sorry_rejected(tmp_path):
    """A proof module containing `sorry` (or axiom/native_decide) is rejected before any
    build — a benchmark discharge must be genuinely closed."""
    vctx = _verify_pkg(
        tmp_path, "minif2f-v1",
        modules={"Unsorry/Bad.lean": "import Mathlib\n\ntheorem bad : 1 = 1 := by sorry\n"},
    )
    calls = []

    def runner(argv, **_kw):
        calls.append(tuple(argv))
        return _ok(argv)

    assert validate_benchmark_package(tmp_path, vctx, runner) == 1
    assert ("lake", "build", "Minif2fV1", "--wfail") not in calls  # rejected before build


def test_build_failure_propagates(tmp_path):
    """A kernel/build failure at the suite pin fails the gate (no false positive)."""
    vctx = _verify_pkg(
        tmp_path, "minif2f-v1",
        modules={"Unsorry/A.lean": "import Mathlib\n\ntheorem a : 1 = 1 := rfl\n"},
    )

    def runner(argv, **_kw):
        rc = 1 if tuple(argv)[:2] == ("lake", "build") else 0
        return subprocess.CompletedProcess(argv, rc, "", "build error")

    assert validate_benchmark_package(tmp_path, vctx, runner) == 1


def test_missing_lakefile_rejected(tmp_path):
    vctx = tmp_path / "targets" / "minif2f-v1" / "_verify"
    vctx.mkdir(parents=True)
    assert validate_benchmark_package(tmp_path, vctx, _ok) == 1  # no lakefile.toml


def test_validate_changed_baseless_validates_all(tmp_path):
    _verify_pkg(
        tmp_path, "minif2f-v1",
        modules={"Unsorry/A.lean": "import Mathlib\n\ntheorem a : 1 = 1 := rfl\n"},
    )
    assert validate_changed(tmp_path, None, _ok) == 0


def test_validate_changed_no_packages_is_ok(tmp_path):
    assert validate_changed(tmp_path, None, _ok) == 0  # no targets/ at all
