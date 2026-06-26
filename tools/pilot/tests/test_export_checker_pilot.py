import subprocess
from pathlib import Path

import yaml

import json

from tools.pilot.export_checker_pilot import (
    NANODA_PERMITTED_AXIOMS,
    PATHOLOGY_RATIO,
    ModuleResult,
    aggregate,
    classify_checker,
    compute_ratio,
    determinism_verdict,
    emit_progress,
    export_capture,
    module_source_decls,
    nanoda_config,
    parse_declars_checked,
    render_md,
    run_module,
    run_pilot,
    select_modules,
    sha256_hex,
    swap_two_theorem_values,
    swap_two_theorem_types,
    corrupt_dangling_reference,
    red_team_verdict,
    red_team_suite,
    _DANGLING_INDEX,
)

REPO_ROOT = Path(__file__).resolve().parents[3]
PILOT_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "export-checker-pilot.yml"


def completed(argv, returncode=0, stdout=b"", stderr=""):
    return subprocess.CompletedProcess(tuple(argv), returncode, stdout, stderr)


def clock_seq(*vals):
    it = iter(vals)
    return lambda: next(it)


def make_runner(export_outputs, nanoda=(0, ""), leanchecker=(0, ""), nanoda_args=None, nanoda_stdout=""):
    """Fake runner: lean4export returns successive bytes (None=failure); nanoda /
    leanchecker return (rc, stderr) — or nanoda='timeout' to raise. nanoda's argv
    is appended to `nanoda_args` (if given); nanoda_stdout is its stdout."""
    state = {"i": 0}

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            i = state["i"]
            state["i"] += 1
            out = export_outputs[i] if i < len(export_outputs) else export_outputs[-1]
            return completed(argv, returncode=1) if out is None else completed(argv, stdout=out)
        if argv[0] == "nanoda":
            if nanoda_args is not None:
                nanoda_args.append(argv)
            if nanoda == "timeout":
                raise subprocess.TimeoutExpired(argv, timeout)
            return completed(argv, returncode=nanoda[0], stdout=nanoda_stdout, stderr=nanoda[1])
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


def test_nanoda_config_points_at_export_and_permits_whitelist(tmp_path):
    export = tmp_path / "Unsorry.A.export"
    cfg = nanoda_config(export)
    assert cfg["export_file_path"] == str(export)
    assert cfg["use_stdin"] is False
    # the project audit whitelist + Lean.trustCompiler, skip (not hard-error) others
    assert set(cfg["permitted_axioms"]) == set(NANODA_PERMITTED_AXIOMS)
    assert {"propext", "Classical.choice", "Quot.sound"} <= set(cfg["permitted_axioms"])
    assert cfg["unpermitted_axiom_hard_error"] is False
    # Nat/String literal support — without these nanoda hard-errors on the first
    # Nat literal in any real export (the run-3 finding).
    assert cfg["nat_extension"] is True
    assert cfg["string_extension"] is True


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
    nanoda_args = []
    runner = make_runner([b"EXPORT", b"EXPORT"], nanoda=(0, ""), leanchecker=(0, ""), nanoda_args=nanoda_args)
    clock = clock_seq(0.0, 5.0, 100.0, 102.0)  # nanoda=5s, leanchecker=2s
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.determinism == "stable"
    assert r.export_bytes == len(b"EXPORT")
    assert r.nanoda_status == "ok"
    assert r.nanoda_seconds == 5.0 and r.leanchecker_seconds == 2.0
    assert r.ratio == 2.5 and r.pathology is False
    assert (tmp_path / "Unsorry.A.export").read_bytes() == b"EXPORT"
    # nanoda is invoked with the CONFIG json (not the raw export), and the config
    # on disk points at the export + carries the whitelist (the run-1 bug fix).
    assert len(nanoda_args) == 1
    cfg_arg = nanoda_args[0][-1]
    assert cfg_arg.endswith(".nanoda.json")
    cfg = json.loads((tmp_path / "Unsorry.A.nanoda.json").read_text())
    assert cfg["export_file_path"] == str(tmp_path / "Unsorry.A.export")
    assert "Quot.sound" in cfg["permitted_axioms"]


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


def test_run_module_captures_nanoda_stderr_on_error(tmp_path):
    # The run-1/2 gap: when nanoda errors we MUST keep its stderr to diagnose why.
    runner = make_runner([b"E", b"E"], nanoda=(101, "thread 'main' panicked at 'boom'"), leanchecker=(0, ""))
    clock = clock_seq(0.0, 0.07, 0.0, 30.0)
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.nanoda_status == "error"
    assert "panicked" in r.nanoda_stderr  # stderr preserved, not discarded
    # and it surfaces in the report's diagnostics section
    md = render_md([r], aggregate([r]))
    assert "nanoda diagnostics" in md and "panicked" in md


def test_run_module_no_stderr_kept_on_ok(tmp_path):
    runner = make_runner([b"E", b"E"], nanoda=(0, "noise"), leanchecker=(0, ""))
    clock = clock_seq(0.0, 4.0, 0.0, 30.0)
    r = run_module("Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path, runner, clock, 300)
    assert r.nanoda_status == "ok"
    assert r.nanoda_stderr == ""  # clean runs don't carry noise


def test_run_pilot_invokes_progress_per_module(tmp_path):
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True)
    for n in ("A", "B"):
        (d / f"{n}.lean").write_text("")
    runner = make_runner([b"E"] * 8, nanoda=(0, ""), leanchecker=(0, ""))
    seen = []
    run_pilot(
        tmp_path, ["Unsorry.A", "Unsorry.B"], 1,
        ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path / "exp",
        runner=runner, clock=lambda: 0.0, timeout=300,
        on_progress=lambda i, total, r: seen.append((i, total, r.module)),
    )
    assert seen == [(1, 2, "Unsorry.A"), (2, 2, "Unsorry.B")]


def test_emit_progress_appends_to_step_summary(tmp_path, monkeypatch):
    summary = tmp_path / "summary.md"
    monkeypatch.setenv("GITHUB_STEP_SUMMARY", str(summary))
    r = ModuleResult("Unsorry.A", 100, "h", "stable", 4.0, "ok", 2.0, 2.0, False)
    emit_progress(1, 3, r)
    body = summary.read_text()
    assert "[1/3] Unsorry.A" in body and "nanoda=ok" in body


def _ndjson(*objs):
    return "\n".join(json.dumps(o) for o in objs)


def test_swap_two_theorem_values_makes_ill_typed_export():
    # two theorems with DIFFERENT types (1 vs 2) and values (10 vs 20)
    text = _ndjson(
        {"meta": {}},
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 2, "value": 20, "all": []}},
        {"axiom": {"name": 3, "type": 5}},  # non-theorem untouched
    )
    out = swap_two_theorem_values(text)
    assert out is not None
    lines = [json.loads(l) for l in out.split("\n")]
    # values swapped: thm(type 1) now has value 20, thm(type 2) now has value 10
    thm1 = next(o["thm"] for o in lines if o.get("thm", {}).get("type") == 1)
    thm2 = next(o["thm"] for o in lines if o.get("thm", {}).get("type") == 2)
    assert thm1["value"] == 20 and thm2["value"] == 10
    # the axiom line is byte-preserved
    assert '{"axiom": {"name": 3, "type": 5}}' in out


def test_swap_returns_none_when_no_two_distinct_typed_theorems():
    # all theorems share type 1 → cannot construct an ill-typed swap
    text = _ndjson(
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 1, "value": 20, "all": []}},
    )
    assert swap_two_theorem_values(text) is None
    # fewer than two theorems
    assert swap_two_theorem_values(_ndjson({"thm": {"name": 1, "type": 1, "value": 10, "all": []}})) is None


def test_run_module_negative_control_records_rejection(tmp_path):
    # The export has two differently-typed theorems so a swap is constructable.
    export = _ndjson(
        {"meta": {}},
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 2, "value": 20, "all": []}},
    ).encode()
    nanoda_calls = []

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            return completed(argv, stdout=export)
        if argv[0] == "nanoda":
            cfg_path = argv[-1]
            nanoda_calls.append(cfg_path)
            # The valid export's config → ok; the .bad config → reject (rc 1).
            rc = 1 if cfg_path.endswith(".bad.nanoda.json") else 0
            return completed(argv, returncode=rc, stdout="Checked 2 declarations with no errors" if rc == 0 else "", stderr="type mismatch" if rc else "")
        return completed(argv, stdout="")  # leanchecker

    r = run_module(
        "Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path,
        runner, clock_seq(0.0, 0.5, 0.0, 11.0, 0.0, 0.2), 300,
        negative_control=True,
    )
    assert r.nanoda_status == "ok"      # valid export accepted
    assert r.nc_rejected is True        # ill-typed swap rejected ⇒ sound on this case
    assert any(c.endswith(".bad.nanoda.json") for c in nanoda_calls)  # the swap WAS fed to nanoda


def test_run_module_negative_control_flags_soundness_failure(tmp_path):
    # If nanoda ACCEPTS the ill-typed export, nc_rejected is False (a failure signal).
    export = _ndjson(
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 2, "value": 20, "all": []}},
    ).encode()

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            return completed(argv, stdout=export)
        if argv[0] == "nanoda":
            return completed(argv, returncode=0, stdout="Checked 2 declarations with no errors")  # accepts EVERYTHING
        return completed(argv, stdout="")

    r = run_module(
        "Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path,
        runner, clock_seq(0.0, 0.5, 0.0, 11.0, 0.0, 0.2), 300,
        negative_control=True,
    )
    assert r.nc_rejected is False  # accepted an ill-typed export → soundness failure flagged


# --- broader red-team (SPEC-096-A §4.1, acceptance gate 1) -------------------

def _two_typed_thms():
    return _ndjson(
        {"meta": {}},
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 2, "value": 20, "all": []}},
    )


def test_swap_two_theorem_types_alters_statement():
    out = swap_two_theorem_types(_two_typed_thms())
    assert out is not None
    lines = [json.loads(l) for l in out.split("\n")]
    thms = [o["thm"] for o in lines if "thm" in o]
    # types swapped, values preserved → each theorem now claims the OTHER statement
    by_val = {t["value"]: t for t in thms}
    assert by_val[10]["type"] == 2 and by_val[20]["type"] == 1
    # all-same-type or single-theorem → cannot construct
    assert swap_two_theorem_types(_ndjson(
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 1, "value": 20, "all": []}})) is None
    assert swap_two_theorem_types(_ndjson({"thm": {"name": 1, "type": 1, "value": 10}})) is None


def test_corrupt_dangling_reference_points_value_out_of_range():
    out = corrupt_dangling_reference(_two_typed_thms())
    assert out is not None
    thms = [json.loads(l)["thm"] for l in out.split("\n") if '"thm"' in l]
    # exactly one theorem's value now points at the dangling sentinel; the rest intact
    dangling = [t for t in thms if t["value"] == _DANGLING_INDEX]
    assert len(dangling) == 1
    # no theorems → None
    assert corrupt_dangling_reference(_ndjson({"axiom": {"name": 1, "type": 2}})) is None


def test_nanoda_config_axiom_hard_error_and_empty_whitelist(tmp_path):
    export = tmp_path / "A.export"
    cfg = nanoda_config(export, permitted_axioms=(), unpermitted_axiom_hard_error=True)
    assert cfg["permitted_axioms"] == []
    assert cfg["unpermitted_axiom_hard_error"] is True
    # default stays lenient
    assert nanoda_config(export)["unpermitted_axiom_hard_error"] is False


def test_red_team_verdict_classifies():
    assert red_team_verdict("c", False, None) == "n/a"          # not constructable
    assert red_team_verdict("c", True, None) == "n/a"           # constructable but not run
    assert red_team_verdict("c", True, "error") == "rejected"   # any non-ok = sound
    assert red_team_verdict("c", True, "timeout") == "rejected"
    assert red_team_verdict("c", True, "ok") == "ACCEPTED"      # accepted invalid = failure


def _redteam_runner(export_bytes, *, accept_classes=(), axiom_free=False):
    """Config-aware faker. nanoda reads the config JSON it's handed and decides:
    a mutated-export config (path tag) → reject unless its class is in accept_classes;
    the axiom-restrict config (empty permitted_axioms) → reject unless axiom_free;
    the valid check → ok."""
    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            return completed(argv, stdout=export_bytes)
        if argv[0] == "nanoda":
            cfg = json.loads(Path(argv[-1]).read_text())
            exp = cfg["export_file_path"]
            if cfg["permitted_axioms"] == []:                       # axiom-restrict
                return completed(argv, returncode=0) if axiom_free else completed(argv, returncode=1, stderr="unpermitted axiom")
            for cls in ("value-swap", "type-swap", "dangling-ref"):
                if f".{cls}.export" in exp:
                    return completed(argv, returncode=0) if cls in accept_classes else completed(argv, returncode=1, stderr="reject")
            return completed(argv, returncode=0, stdout="Checked 2 declarations with no errors")  # valid
        return completed(argv, stdout="")  # leanchecker
    return runner


def test_red_team_suite_all_rejected_is_sound(tmp_path):
    suite = red_team_suite(_two_typed_thms(), tmp_path, "Unsorry.A",
                           ("nanoda",), _redteam_runner(_two_typed_thms().encode()), lambda: 0.0, 300)
    assert suite == {"value-swap": "rejected", "type-swap": "rejected",
                     "dangling-ref": "rejected", "axiom-restrict": "rejected"}


def test_red_team_suite_accept_flags_soundness_failure(tmp_path):
    suite = red_team_suite(_two_typed_thms(), tmp_path, "Unsorry.A", ("nanoda",),
                           _redteam_runner(_two_typed_thms().encode(), accept_classes=("type-swap",)),
                           lambda: 0.0, 300)
    assert suite["type-swap"] == "ACCEPTED"        # nanoda accepted an altered statement → failure
    assert suite["value-swap"] == "rejected"


def test_red_team_suite_axiom_free_is_na(tmp_path):
    suite = red_team_suite(_two_typed_thms(), tmp_path, "Unsorry.A", ("nanoda",),
                           _redteam_runner(_two_typed_thms().encode(), axiom_free=True), lambda: 0.0, 300)
    assert suite["axiom-restrict"] == "n/a"         # nothing to enforce, not a failure


def test_run_module_red_team_populates_result_and_nc(tmp_path):
    r = run_module("Unsorry.A", 1, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path,
                   _redteam_runner(_two_typed_thms().encode()), lambda: 0.0, 300, red_team=True)
    assert r.nanoda_status == "ok"
    assert r.red_team == {"value-swap": "rejected", "type-swap": "rejected",
                          "dangling-ref": "rejected", "axiom-restrict": "rejected"}
    assert r.nc_rejected is True   # back-compat: value-swap class mirrors nc_rejected


def test_aggregate_and_render_red_team_summary():
    sound = ModuleResult("Unsorry.A", 100, "h", "single", 0.4, "ok", 9.0, None, False,
                         red_team={"value-swap": "rejected", "type-swap": "rejected",
                                   "dangling-ref": "rejected", "axiom-restrict": "n/a"})
    s = aggregate([sound])
    assert s["red_team"]["sound"] is True
    assert s["red_team"]["per_class"]["axiom-restrict"]["n/a"] == 1
    assert s["verdict"]["red_team_sound"] is True
    md = render_md([sound], s)
    assert "Broader red-team" in md and "vacuity" in md   # the honest boundary note is present
    # a soundness failure flips the verdict
    bad = ModuleResult("Unsorry.B", 100, "h", "single", 0.4, "ok", 9.0, None, False,
                       red_team={"value-swap": "ACCEPTED", "type-swap": "rejected",
                                 "dangling-ref": "rejected", "axiom-restrict": "rejected"})
    sbad = aggregate([bad])
    assert sbad["red_team"]["sound"] is False
    assert "SOUNDNESS FAILURE" in render_md([bad], sbad)


def test_parse_declars_checked():
    assert parse_declars_checked("Checked 2317 declarations with no errors") == 2317
    assert parse_declars_checked("Checked 1 declarations with no errors, skipping ...") == 1
    assert parse_declars_checked("some other output") is None
    assert parse_declars_checked("") is None


def test_nanoda_config_confirm_decls_adds_pp_guard(tmp_path):
    export = tmp_path / "A.export"
    cfg = nanoda_config(export, confirm_decls=["alt_geometric_ratio_eight"])
    assert cfg["pp_declars"] == ["alt_geometric_ratio_eight"]
    assert cfg["unknown_pp_declar_hard_error"] is True  # missing target → hard error
    assert cfg["pp_options"]["proofs"] is False
    # without confirm_decls: no pp guard
    assert "pp_declars" not in nanoda_config(export)


def test_run_module_records_declars_and_confirms_target(tmp_path):
    runner = make_runner(
        [b"E", b"E"], nanoda=(0, ""), leanchecker=(0, ""),
        nanoda_stdout="Checked 2317 declarations with no errors",
    )
    clock = clock_seq(0.0, 0.5, 0.0, 11.0)
    r = run_module(
        "Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path,
        runner, clock, 300, confirm_decls=["thm_a"],
    )
    assert r.nanoda_status == "ok"
    assert r.nanoda_declars_checked == 2317   # real closure size, not degenerate
    assert r.target_confirmed is True         # pp guard passed ⇒ target present


def test_run_module_target_not_confirmed_when_nanoda_errors(tmp_path):
    # If the target theorem were absent, nanoda hard-errors (unknown_pp_declar) →
    # status != ok → target_confirmed False (the degenerate-pass guard works).
    runner = make_runner(
        [b"E", b"E"], nanoda=(1, "unknown pp declar 'thm_a'"), leanchecker=(0, ""),
    )
    clock = clock_seq(0.0, 0.1, 0.0, 11.0)
    r = run_module(
        "Unsorry.A", 2, ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path,
        runner, clock, 300, confirm_decls=["thm_a"],
    )
    assert r.target_confirmed is False


def test_select_modules_spread_is_diverse(tmp_path):
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True)
    for i in range(100):
        (d / f"M{i:03d}.lean").write_text("")
    first = select_modules(tmp_path, 4, None, spread=False)
    spread = select_modules(tmp_path, 4, None, spread=True)
    assert len(spread) == 4
    assert spread != first          # not the first-4 cluster
    assert spread[0] != spread[-1]  # spans the list
    assert len(set(spread)) == 4    # distinct


def test_module_source_decls_parses_theorem_names(tmp_path):
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True)
    (d / "AltGeometricRatioEight.lean").write_text(
        "import Mathlib\n"
        "/-- doc -/\n"
        "theorem alt_geometric_ratio_eight (n : ℕ) : True := by trivial\n"
    )
    assert module_source_decls(tmp_path, "Unsorry.AltGeometricRatioEight") == ["alt_geometric_ratio_eight"]
    # nested module path + def/lemma kinds
    (d / "Sub").mkdir()
    (d / "Sub" / "Foo.lean").write_text("def my_def := 1\nlemma my_lemma : True := trivial\n")
    assert module_source_decls(tmp_path, "Unsorry.Sub.Foo") == ["my_def", "my_lemma"]
    assert module_source_decls(tmp_path, "Unsorry.Missing") == []


def test_export_capture_scopes_to_decls(tmp_path):
    seen = []

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        seen.append(argv)
        return completed(argv, stdout=b"EXPORT")

    # whole-module: no `--`
    export_capture("Unsorry.A", ("lean4export",), runner)
    assert seen[-1] == ("lean4export", "Unsorry.A")
    # scoped: `Module -- d1 d2`
    export_capture("Unsorry.A", ("lean4export",), runner, scope_decls=["a_thm", "b_thm"])
    assert seen[-1] == ("lean4export", "Unsorry.A", "--", "a_thm", "b_thm")


def test_run_pilot_scope_decls_passes_module_decls(tmp_path):
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True)
    (d / "A.lean").write_text("theorem thm_a : True := trivial\n")
    export_calls = []

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            export_calls.append(argv)
            return completed(argv, stdout=b"E")
        return completed(argv, stdout="")  # nanoda/leanchecker

    run_pilot(
        tmp_path, ["Unsorry.A"], 1,
        ("lean4export",), ("nanoda",), ("leanchecker",), tmp_path / "exp",
        runner=runner, clock=lambda: 0.0, timeout=300,
        on_progress=lambda *a: None, scope_decls=True,
    )
    # lean4export was scoped to the module's own theorem
    assert export_calls and export_calls[0] == ("lean4export", "Unsorry.A", "--", "thm_a")


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
