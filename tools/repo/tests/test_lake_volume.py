"""Tests for tools.repo.lake_volume — the .lake volume survey/reclaim janitor."""
from __future__ import annotations

from pathlib import Path

from tools.repo import lake_volume as lv


# ----------------------------- pure core ----------------------------------
def test_parse_pin():
    assert lv.parse_pin("leanprover/lean4:v4.30.0") == "leanprover/lean4:v4.30.0"
    assert lv.parse_pin("  leanprover/lean4:v4.24.0\n") == "leanprover/lean4:v4.24.0"
    assert lv.parse_pin("") is None
    assert lv.parse_pin(None) is None
    assert lv.parse_pin("nightly-2026-01-01") is None


def test_stale_toolchains():
    present = ["leanprover/lean4:v4.24.0", "leanprover/lean4:v4.27.0", "leanprover/lean4:v4.30.0"]
    pinned = {"leanprover/lean4:v4.30.0", "leanprover/lean4:v4.24.0"}
    assert lv.stale_toolchains(present, pinned) == ["leanprover/lean4:v4.27.0"]
    # all live -> nothing stale (the current state: 4 live pins, none evictable)
    assert lv.stale_toolchains(pinned, pinned) == []


def test_needs_reclaim_watermark():
    assert lv.needs_reclaim(free_gb=2, min_free_gb=8, force=False) is True   # below floor
    assert lv.needs_reclaim(free_gb=20, min_free_gb=8, force=False) is False  # plenty free
    assert lv.needs_reclaim(free_gb=20, min_free_gb=8, force=True) is True    # forced
    assert lv.needs_reclaim(free_gb=8, min_free_gb=8, force=False) is False   # exactly at floor


def test_pct_used():
    assert lv.pct_used(free=0, total=100) == 100.0
    assert lv.pct_used(free=50, total=100) == 50.0
    assert lv.pct_used(free=0, total=0) == 0.0  # no div-by-zero


def test_human():
    assert lv.human(0) == "0B"
    assert lv.human(512) == "512B"
    assert lv.human(1024) == "1.0K"
    assert lv.human(50 * 1024**3) == "50.0G"


# ----------------------------- I/O shell ----------------------------------
def test_live_pins_repo_plus_suites(tmp_path):
    (tmp_path / "lean-toolchain").write_text("leanprover/lean4:v4.30.0\n")
    for suite, pin in (("minif2f-v1", "v4.24.0"), ("putnam-v1", "v4.27.0")):
        d = tmp_path / "targets" / suite / "_verify"
        d.mkdir(parents=True)
        (d / "lean-toolchain").write_text(f"leanprover/lean4:{pin}\n")
    pins = lv.live_pins(tmp_path)
    assert set(pins) == {
        "leanprover/lean4:v4.30.0",
        "leanprover/lean4:v4.24.0",
        "leanprover/lean4:v4.27.0",
    }


def test_survey_missing_lake(tmp_path):
    rep = lv.survey(tmp_path, tmp_path / ".lake")
    assert rep["exists"] is False  # no volume mounted -> reported, not crashed


def test_survey_and_apply_reclaims_ltar(tmp_path):
    lake = tmp_path / ".lake"
    mc = lake / "mathlib-cache"
    mc.mkdir(parents=True)
    for name in ("a", "b", "c"):
        (mc / f"{name}.ltar").write_bytes(b"x" * 1000)
    (lake / "packages").mkdir()  # a live-oleans dir the reclaim must NOT touch
    (lake / "packages" / "keep.olean").write_bytes(b"y" * 10)

    rep = lv.survey(tmp_path, lake)
    assert rep["exists"] is True
    assert rep["reclaimable"]["ltar_count"] == 3
    assert rep["reclaimable"]["ltar_bytes"] == 3000

    # force so the watermark doesn't gate the test regardless of the host's free space
    res = lv.apply_reclaim(tmp_path, lake, rep)
    assert res["ltar_removed"] == 3
    assert list(mc.glob("*.ltar")) == []          # archives gone
    assert (lake / "packages" / "keep.olean").exists()  # live oleans untouched
