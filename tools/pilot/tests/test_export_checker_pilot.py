import subprocess
from pathlib import Path

import yaml

from tools.pilot.export_checker_pilot import (
    PATHOLOGY_RATIO,
    ModuleResult,
    aggregate,
    classify_checker,
    compute_ratio,
    determinism_verdict,
    render_md,
    run_module,
    select_modules,
    sha256_hex,
)

REPO_ROOT = Path(__file__).resolve().parents[3]
PILOT_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "export-checker-pilot.yml"


def completed(argv, returncode=0, stdout=b"", stderr=""):
    return subprocess.CompletedProcess(tuple(argv), returncode, stdout, stderr)


def clock_seq(*vals):
    it = iter(vals)
    return lambda: next(it)


def make_runner(export_outputs, nanoda=(0, ""), leanchecker=(0, "")):
    """Fake runner: lean4export returns successive bytes (None=failure); nanoda /
    leanchecker return (rc, stderr) — or nanoda='timeout' to raise."""
    state = {"i": 0}

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            i = state["i"]
            state["i"] += 1
            out = export_outputs[i] if i < len(export_outputs) else export_outputs[-1]
            return completed(argv, returncode=1) if out is None else completed(argv, stdout=out)
        if argv[0] == "nanoda":
            if nanoda == "timeout":
                raise subprocess.TimeoutExpired(argv, timeout)
            return completed(argv, returncode=nanoda[0], stderr=nanoda[1])
        if argv[0] == "leanchecker":
            return completed(argv, returncode=leanchecker[0], stderr=leanchecker[1])
        return completed(argv)

    return runner


# --- pure helpers -----------------------------------------------------------

def test_sha256_hex_is_stable():
    assert sha256_hex(b"abc") == sha256_hex(b"abc")
    assert sha256_hex(b"abc") != sha256_hex(b"abd")


def test_determinism_verdict():
    assert determinism_verdict([]) == "failed"
    assert determinism_verdict(["a"]) == "single"
    assert determinism_verdict(["a", "a"]) == "stable"
    assert determinism_verdict(["a", "b"]) == "divergent"
    assert determinism_verdict(["a", "a", "b"]) == "divergent"


def test_classify_checker():
    assert classify_checker(0, "") == "ok"
    assert classify_checker(1, "parse error at line 3") == "incompatible"
    assert classify_checker(1, "unsupported export format version") == "incompatible"
    assert classify_checker(1, "unexpected token") == "incompatible"
    assert classify_checker(2, "segmentation fault") == "error"
    assert classify_checker(101, "") == "error"


def test_compute_ratio():
    assert compute_ratio(10.0, 2.0) == 5.0
    assert compute_ratio(None, 2.0) is None
    assert compute_ratio(10.0, None) is None
    assert compute_ratio(10.0, 0.0) is None  # 0-baseline never divides


def test_aggregate_and_verdicts():
    results = [
        ModuleResult("A", 100, "h1", "stable", 4.0, "ok", 2.0, 2.0, False),
        ModuleResult("B", 200, "h2", "stable", 6.0, "ok", 3.0, 2.0, False),
        ModuleResult("C", 0, "", "failed", None, "skipped", None, None, False),
    ]
    s = aggregate(results)
    assert s["modules"] == 3
    assert s["determinism"]["stable"] == 2
    assert s["determinism"]["failed"] == 1
    assert s["determinism"]["cross_run_stable_rate"] == 1.0
    assert s["nanoda"]["ok"] == 2 and s["nanoda"]["skipped"] == 1
    assert s["ratio"]["pathology_count"] == 0
    assert s["verdict"]["Q2_export_deterministic"] is True
    assert s["verdict"]["Q3_wall_clock_bounded"] is True


def test_aggregate_flags_pathology_and_divergence():
    results = [
        ModuleResult("A", 100, "h1", "divergent", 500.0, "ok", 2.0, 250.0, True),
        ModuleResult("B", 100, "h2", "stable", 3.0, "ok", 2.0, 1.5, False),
    ]
    s = aggregate(results)
    assert s["determinism"]["cross_run_stable_rate"] == 0.5  # 1 stable of 2 multi-run
    assert s["ratio"]["pathology_count"] == 1
    assert s["ratio"]["max"] == 250.0
    assert s["verdict"]["Q2_export_deterministic"] is False
    assert s["verdict"]["Q3_wall_clock_bounded"] is False  # pathology present


def test_aggregate_inconclusive_when_no_timing():
    results = [ModuleResult("A", 0, "", "failed", None, "skipped", None, None, False)]
    s = aggregate(results)
    assert s["verdict"]["Q2_export_deterministic"] is None
    assert s["verdict"]["Q3_wall_clock_bounded"] is None


def test_render_md_has_verdict_and_rows():
    results = [ModuleResult("Unsorry.A", 100, "h1", "stable", 4.0, "ok", 2.0, 2.0, False)]
    md = render_md(results, aggregate(results))
    assert "Q2" in md and "Q3" in md
    assert "Unsorry.A" in md
    assert f"{int(PATHOLOGY_RATIO)}" in md


# --- orchestration ----------------------------------------------------------

def test_run_module_stable_ratio(tmp_path):
    runner = make_runner([b"EXPORT", b"EXPORT"], nanoda=(0, ""), leanchecker=(0, ""))
    clock = clock_seq(0.0, 5.0, 100.0, 102.0)  # nanoda=5s, leanchecker=2s
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.determinism == "stable"
    assert r.export_bytes == len(b"EXPORT")
    assert r.nanoda_status == "ok"
    assert r.nanoda_seconds == 5.0 and r.leanchecker_seconds == 2.0
    assert r.ratio == 2.5 and r.pathology is False
    assert (tmp_path / "Unsorry.A.export").read_bytes() == b"EXPORT"


def test_run_module_divergent(tmp_path):
    runner = make_runner([b"EXPORT-1", b"EXPORT-2"])
    clock = clock_seq(0.0, 1.0, 0.0, 1.0)
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.determinism == "divergent"


def test_run_module_export_failure_skips_nanoda(tmp_path):
    runner = make_runner([None])  # lean4export fails
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock_seq(), 300)
    assert r.determinism == "failed"
    assert r.nanoda_status == "skipped"
    assert r.ratio is None


def test_run_module_nanoda_timeout(tmp_path):
    runner = make_runner([b"E", b"E"], nanoda="timeout", leanchecker=(0, ""))
    clock = clock_seq(0.0, 0.0, 10.0, 11.0)  # nanoda raises before 2nd read; leanchecker 1s
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 1)
    assert r.nanoda_status == "timeout"
    assert r.nanoda_seconds is None
    assert r.ratio is None  # no nanoda time → no ratio


def test_run_module_nanoda_incompatible(tmp_path):
    runner = make_runner([b"E", b"E"], nanoda=(1, "parse error: unknown kind"), leanchecker=(0, ""))
    clock = clock_seq(0.0, 3.0, 0.0, 1.0)
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.nanoda_status == "incompatible"


def test_select_modules(tmp_path):
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True)
    for n in ("A", "B", "C"):
        (d / f"{n}.lean").write_text("")
    assert select_modules(tmp_path, 2, None) == ["Unsorry.A", "Unsorry.B"]
    assert select_modules(tmp_path, 99, ["X.Y"]) == ["X.Y"]  # explicit list overrides


# --- workflow conformance (SPEC-093-A §6) -----------------------------------

def test_pilot_workflow_is_dispatch_only_and_non_gating():
    assert PILOT_WORKFLOW.is_file(), f"missing pilot workflow at {PILOT_WORKFLOW}"
    text = PILOT_WORKFLOW.read_text(encoding="utf-8")
    doc = yaml.safe_load(text)
    # PyYAML parses the bare `on:` key as boolean True.
    triggers = doc.get(True, doc.get("on"))
    assert isinstance(triggers, dict) and set(triggers) == {"workflow_dispatch"}, "pilot must be workflow_dispatch-only"
    assert (doc.get("permissions") or {}).get("contents") == "read", "pilot must be read-only"
    # observe-only: never admits content / pushes / opens PRs.
    for forbidden in ("git push", "gh pr ", "download-artifact"):
        assert forbidden not in text, f"pilot workflow must not contain {forbidden!r}"
