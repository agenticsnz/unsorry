"""Tests for the suite-scoped verifier context (ADR-099 / SPEC-099-A §1). Hermetic —
the single ``lake exe cache get`` seam is injected via :class:`FakeRunner`."""
from __future__ import annotations

import json

import pytest

from tools.intake.tests._fakerunner import FakeRunner
from tools.intake.verifier_context import (
    VerifierContextError,
    ensure_verifier_context,
    scaffold,
    verifier_dir,
    warm_cache,
)

V424 = "leanprover/lean4:v4.24.0"
REV24 = "c5ea00351c28e24afc9f0f84379aa41082b1188f"


def _manifest(tmp_path, rev=REV24):
    """A minimal lake-manifest.json the operator would supply (one mathlib entry)."""
    src = tmp_path / "native-manifest.json"
    src.write_text(
        json.dumps(
            {
                "version": "1.1.0",
                "packagesDir": ".lake/packages",
                "packages": [
                    {"type": "git", "name": "mathlib", "rev": rev, "inputRev": "v4.24.0"}
                ],
            }
        ),
        "utf-8",
    )
    return src


def test_scaffold_writes_toolchain_lakefile_manifest(tmp_path):
    src = _manifest(tmp_path)
    vctx = scaffold(tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24, manifest_src=src)

    assert vctx == verifier_dir(tmp_path, "minif2f-v1")
    assert (vctx / "lean-toolchain").read_text("utf-8") == V424 + "\n"
    lakefile = (vctx / "lakefile.toml").read_text("utf-8")
    assert f'rev = "{REV24}"' in lakefile
    assert 'name = "mathlib"' in lakefile
    # the manifest is copied byte-for-byte (transitive dep revs must resolve)
    assert (vctx / "lake-manifest.json").read_bytes() == src.read_bytes()


def test_scaffold_is_idempotent(tmp_path):
    src = _manifest(tmp_path)
    first = {
        p.name: p.read_bytes()
        for p in scaffold(tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24, manifest_src=src).iterdir()
    }
    second = {
        p.name: p.read_bytes()
        for p in scaffold(tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24, manifest_src=src).iterdir()
    }
    assert first == second  # a re-scaffold is byte-identical (no churn)


def test_scaffold_lakefile_name_derived_from_suite(tmp_path):
    src = _manifest(tmp_path)
    a = (scaffold(tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24, manifest_src=src)
         / "lakefile.toml").read_text("utf-8")
    b = (scaffold(tmp_path, "combibench-v1", toolchain=V424, mathlib=REV24, manifest_src=src)
         / "lakefile.toml").read_text("utf-8")
    assert 'defaultTargets = ["Minif2fV1"]' in a
    assert 'defaultTargets = ["CombibenchV1"]' in b
    assert a != b  # distinct suites get distinct lib names (no cross-suite collision)


def test_warm_cache_runs_lake_cache_get_in_vctx(tmp_path):
    src = _manifest(tmp_path)
    vctx = scaffold(tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24, manifest_src=src)
    runner = FakeRunner(cache_rc=0)
    assert warm_cache(vctx, runner=runner) == 0
    call = runner.cache_calls()[0]
    assert call.argv == ("lake", "exe", "cache", "get")
    assert call.cwd == str(vctx)  # the warmup runs in the SUITE project, not the repo root


def test_warm_cache_nonzero_raises(tmp_path):
    src = _manifest(tmp_path)
    runner = FakeRunner(cache_rc=1)
    with pytest.raises(VerifierContextError):
        ensure_verifier_context(
            tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24,
            manifest_src=src, runner=runner, warm=True,
        )


def test_ensure_verifier_context_returns_vctx_and_skips_warm(tmp_path):
    src = _manifest(tmp_path)
    runner = FakeRunner(cache_rc=1)  # would raise if warmed
    vctx = ensure_verifier_context(
        tmp_path, "minif2f-v1", toolchain=V424, mathlib=REV24,
        manifest_src=src, runner=runner, warm=False,
    )
    assert vctx == verifier_dir(tmp_path, "minif2f-v1")
    assert (vctx / "lakefile.toml").is_file()
    assert runner.calls == []  # warm=False never touches the runner
