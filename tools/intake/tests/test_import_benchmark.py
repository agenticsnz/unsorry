"""Tests for the benchmark importer (M4). Hermetic — the Lean elaboration/credit
seam is injected, so no Lean is needed; the assembly is checked end-to-end against
skeleton-validate (M3), Gate B, and the registered-targets generator (M5a)."""
from __future__ import annotations

import pytest

from tools.governance.admission import parse_registry
from tools.intake.import_benchmark import (
    ImportError_,
    Problem,
    assemble_package,
    batches,
    extract_putnambench,
    main,
    slugify,
)

PUTNAM_SRC = """
import Mathlib
abbrev putnam_2001_a1_solution : Prop := sorry
theorem putnam_1988_b2
(x : ℝ)
: x + 0 = x := sorry
theorem putnam_2001_a1
(h : True)
: putnam_2001_a1_solution := by sorry
"""


def _registry(package="putnam-v1", supplier="trishul"):
    return parse_registry(
        {
            "schema_version": 1,
            "domains": [{"id": "lean-math", "verifier": "lean-kernel", "tier": "VERIFIED"}],
            "targets": [{"package": package, "domain": "lean-math", "supplier": supplier}],
        }
    )


# ------------------------------------------------------------- pure helpers


def test_slugify():
    assert slugify("putnam_1988_b2") == "putnam-1988-b2"
    assert slugify("IMO.2024.P4") == "imo-2024-p4"


def test_extract_putnambench():
    problems = extract_putnambench(PUTNAM_SRC, "PutnamBench")
    assert [p.name for p in problems] == ["putnam_1988_b2", "putnam_2001_a1"]
    # sig is captured verbatim (original formatting preserved); compare ws-insensitively
    assert " ".join(problems[0].signature.split()) == "(x : ℝ) : x + 0 = x"
    assert problems[0].source_ref == "PutnamBench"


def test_extract_handles_internal_assignment():
    """A statement with an internal `:=` (e.g. `let ⟨p, q⟩ := solution`) must NOT
    truncate the signature — only the proof `:= by|sorry` is the cut point (the
    putnam_1965_b4 bug, which built a malformed `: let ⟨…⟩ := by sorry` goal)."""
    src = (
        "import Mathlib\n\n"
        "abbrev sol : Nat × Nat := sorry\n"
        "-- (1, 2)\n"
        "theorem foo (n : Nat) :\n"
        "    let ⟨p, q⟩ := sol\n"
        "    n = p + q := by\n  sorry\n"
    )
    problems = extract_putnambench(src)
    assert len(problems) == 1 and problems[0].name == "foo"
    assert "let ⟨p, q⟩ := sol" in problems[0].signature   # not truncated at the internal :=
    assert problems[0].signature.endswith("n = p + q")
    assert problems[0].preamble == "abbrev sol : Nat × Nat := (1, 2)"  # answer folded in


def test_batches():
    assert list(batches([1, 2, 3, 4, 5], 2)) == [[1, 2], [3, 4], [5]]
    assert list(batches([], 50)) == []


# ------------------------------------------------- keystone: admissible package


def test_assemble_produces_admissible_package(tmp_path):
    from tools.gate_b.graph import SUB_RE
    from tools.gate_b.records import parse_fields, parse_record
    from tools.gate_b.validator import validate_tree
    from tools.intake.skeleton_validate import validate_package

    problems = [
        Problem("putnam_1988_b2", ": 1 + 1 = 2", "PutnamBench"),
        Problem("putnam_2001_a1", ": 2 + 2 = 4", "PutnamBench"),
    ]
    summary = assemble_package(
        tmp_path, "putnam-v1", problems,
        supplier="trishul", domain="lean-math", mathlib="abc123",
        toolchain="leanprover/lean4:v4.30.0", license="Apache-2.0",
    )

    # 1. skeleton-validate ADMITs the produced package (checks 1-5, hermetic)
    result = validate_package(tmp_path / "targets" / "putnam-v1", _registry())
    assert result.ok, result.failures
    assert set(result.leaves) == {"putnam-1988-b2", "putnam-2001-a1"}

    # 2. the swarm-visible statement is relocated to benchmark-goals/ (ADR-110), never
    #    goals/, so the v4.30 UnsorryGoals build (globs goals.+) cannot compile it; the
    #    Gate-B tree stays clean (no benchmark records leak into goals/).
    assert validate_tree(tmp_path) == []
    assert (tmp_path / "benchmark-goals" / "putnam-1988-b2.lean").is_file()
    assert (tmp_path / "benchmark-goals" / "putnam-1988-b2.aisp").is_file()
    assert not (tmp_path / "goals" / "putnam-1988-b2.lean").exists()
    assert not (tmp_path / "goals" / "putnam-1988-b2.aisp").exists()
    assert (tmp_path / "backlog" / "putnam-1988-b2.md").is_file()
    # the relocated record's artifact path is rewritten to benchmark-goals/
    aisp = (tmp_path / "benchmark-goals" / "putnam-1988-b2.aisp").read_text("utf-8")
    assert "lean≜benchmark-goals/putnam-1988-b2.lean" in aisp
    assert "lean≜goals/putnam-1988-b2.lean" not in aisp
    # statement-hash parity with the content-addressed package copy (single source of truth)
    from tools.lean_sig import statement_sha

    bench = (tmp_path / "benchmark-goals" / "putnam-1988-b2.lean").read_text("utf-8")
    pkgcopy = (
        tmp_path / "targets" / "putnam-v1" / "goals" / "putnam-1988-b2.lean"
    ).read_text("utf-8")
    assert statement_sha(bench) == statement_sha(pkgcopy)

    # 3. the package carries exactly the schema the M5a generator reads
    pkg = tmp_path / "targets" / "putnam-v1"
    skeleton = parse_record((pkg / "skeleton.aisp").read_text("utf-8"))
    assert skeleton.fields.get("top") == "putnam-v1-suite"
    sub_ids = {m.group("id") for m in SUB_RE.finditer(skeleton.block("Σ").body)}
    assert sub_ids == {"putnam-1988-b2", "putnam-2001-a1"}
    target = parse_record((pkg / "target.aisp").read_text("utf-8")).fields
    assert target["domain"] == "lean-math"
    assert target["license"] == "Apache-2.0"
    assert target["cohort"] == "benchmark"
    assert summary["obligations"] == ["putnam-1988-b2", "putnam-2001-a1"]


def test_credit_of_marks_glue(tmp_path):
    from tools.gate_b.records import parse_fields, parse_record

    problems = [Problem("putnam_easy", ": True", "P"), Problem("putnam_hard", ": 1 ≤ 2", "P")]
    assemble_package(
        tmp_path, "putnam-v1", problems,
        supplier="trishul", domain="lean-math", mathlib="abc",
        toolchain="t", license="Apache-2.0",
        credit_of=lambda slug: "glue" if "easy" in slug else "credited",
    )
    skeleton = parse_record(
        (tmp_path / "targets" / "putnam-v1" / "skeleton.aisp").read_text("utf-8")
    )
    assert parse_fields(skeleton.block("Κ").body) == {
        "putnam-easy": "glue", "putnam-hard": "credited",
    }


def test_classify_problems_partitions():
    from tools.intake.import_benchmark import classify_problems

    problems = [
        Problem("putnam_bad", ": Nonexistent", "P"),   # probe-error → quarantine
        Problem("putnam_easy", ": True", "P"),          # trivial → glue
        Problem("putnam_hard", ": 1 ≤ 2", "P"),         # non-trivial → credited
    ]

    def verdict_of(lean_text: str) -> str:  # the injected Lean seam
        if "putnam_bad" in lean_text:
            return "probe-error"
        if "putnam_easy" in lean_text:
            return "trivial"
        return "non-trivial"

    kept, credit, quarantined = classify_problems(problems, verdict_of=verdict_of)
    assert [p.name for p in kept] == ["putnam_easy", "putnam_hard"]
    assert credit == {"putnam-easy": "glue", "putnam-hard": "credited"}
    assert [name for name, _ in quarantined] == ["putnam_bad"]


def test_build_flow_excludes_quarantined_and_tags_credit(tmp_path):
    from tools.gate_b.records import parse_fields, parse_record
    from tools.intake.import_benchmark import classify_problems

    problems = [
        Problem("putnam_bad", ": Nonexistent", "P"),
        Problem("putnam_easy", ": True", "P"),
        Problem("putnam_hard", ": 1 ≤ 2", "P"),
    ]

    def verdict_of(lean_text: str) -> str:
        if "putnam_bad" in lean_text:
            return "probe-error"
        if "putnam_easy" in lean_text:
            return "trivial"
        return "non-trivial"

    kept, credit, _ = classify_problems(problems, verdict_of=verdict_of)
    assemble_package(
        tmp_path, "putnam-v1", kept,
        supplier="trishul", domain="lean-math", mathlib="m", toolchain="tc",
        license="Apache-2.0", credit_of=lambda slug: credit.get(slug, "credited"),
    )
    # the quarantined statement was never imported; the rest land in benchmark-goals/ (ADR-110)
    assert not (tmp_path / "benchmark-goals" / "putnam-bad.lean").exists()
    assert (tmp_path / "benchmark-goals" / "putnam-easy.lean").exists()
    assert (tmp_path / "benchmark-goals" / "putnam-hard.lean").exists()
    skeleton = parse_record(
        (tmp_path / "targets" / "putnam-v1" / "skeleton.aisp").read_text("utf-8")
    )
    assert parse_fields(skeleton.block("Κ").body) == {
        "putnam-easy": "glue", "putnam-hard": "credited",
    }


def test_probe_verdict_builds_full_battery(monkeypatch, tmp_path):
    """Exercise the real `_probe_verdict` with a stubbed probe (no Lean) so the
    `TACTIC_BATTERY + EXTRA_BATTERY` line is actually run — guards against the
    NameError that `--build` would otherwise hit on the user's box."""
    import tools.sourcing.check_triviality as ct

    seen = {}

    def fake_probe(path, *, battery, root, **kw):
        seen["battery"] = battery
        return {"verdict": "non-trivial"}

    monkeypatch.setattr(ct, "probe", fake_probe)
    from tools.intake.import_benchmark import _probe_verdict
    from tools.intake.skeleton_validate import EXTRA_BATTERY

    verdict = _probe_verdict("import Mathlib\n\ntheorem t : True := by sorry\n", tmp_path)
    assert verdict == "non-trivial"
    assert set(EXTRA_BATTERY) <= set(seen["battery"])  # the full ADR-078 battery is used


PUTNAM_ANSWER_SRC = """
import Mathlib

abbrev putnam_2017_a1_solution : Set ℤ := sorry
-- {x : ℤ | x > 0 ∧ (x = 1 ∨ 5 ∣ x)}

/--
Find all values …
-/
theorem putnam_2017_a1
(S : Set ℤ)
: S = putnam_2017_a1_solution := by sorry
"""

ANSWER = "{x : ℤ | x > 0 ∧ (x = 1 ∨ 5 ∣ x)}"


def test_companion_preamble_folds_answer_in():
    from tools.intake.import_benchmark import companion_preamble

    pre = companion_preamble(PUTNAM_ANSWER_SRC)
    assert pre == f"abbrev putnam_2017_a1_solution : Set ℤ := {ANSWER}"
    assert "sorry" not in pre  # the answer-blank was substituted, not left opaque


def test_pure_proof_statement_has_no_preamble():
    problems = extract_putnambench("import Mathlib\n\ntheorem foo : 1 = 1 := by sorry\n")
    assert problems[0].preamble == ""


def test_extract_attaches_preamble():
    problems = extract_putnambench(PUTNAM_ANSWER_SRC, "PutnamBench")
    assert len(problems) == 1
    assert problems[0].preamble == f"abbrev putnam_2017_a1_solution : Set ℤ := {ANSWER}"


def test_assemble_bundles_companion_into_goal(tmp_path):
    problems = extract_putnambench(PUTNAM_ANSWER_SRC, "PutnamBench")
    assemble_package(
        tmp_path, "putnam-v1", problems,
        supplier="trishul", domain="lean-math", mathlib="m", toolchain="t",
        license="Apache-2.0",
    )
    goal = (tmp_path / "benchmark-goals" / "putnam-2017-a1.lean").read_text("utf-8")
    # the concrete answer is bundled (so the statement is fixed + provable, not opaque)
    assert f"abbrev putnam_2017_a1_solution : Set ℤ := {ANSWER}" in goal
    assert "theorem putnam_2017_a1" in goal
    assert goal.rstrip().endswith("sorry")  # the obligation sorry is still the last token


def test_extract_imolean_names_from_filename_and_strips_namespace():
    from tools.intake.import_benchmark import extract_imolean

    src = (
        "/- copyright -/\n"
        "import Mathlib\n\n"
        "open scoped Finset\n\n"
        "namespace IMO2020P2\n\n"
        "theorem result {a : ℝ} (h : 0 < a) : a + 0 = a := by\n  sorry\n\n"
        "end IMO2020P2\n"
    )
    problems = extract_imolean(src, "IMOLean", "IMO2020P2")
    assert len(problems) == 1
    p = problems[0]
    assert p.name == "IMO2020P2"  # goal name from the FILE, not the theorem ("result")
    assert "namespace" not in p.preamble and "end" not in p.preamble  # wrapper dropped
    assert "open scoped Finset" in p.preamble  # real companions kept
    assert p.signature.endswith("a + 0 = a")


def test_assemble_accumulates_across_batches(tmp_path):
    common = dict(supplier="acme", domain="lean-math", mathlib="m", toolchain="t", license="L")
    assemble_package(tmp_path, "putnam-v1", [Problem("putnam_a", ": 1 = 1", "P")], **common)
    summary = assemble_package(tmp_path, "putnam-v1", [Problem("putnam_b", ": 2 = 2", "P")], **common)
    # the skeleton now lists BOTH obligations (accumulated, not replaced by batch 2)
    assert set(summary["obligations"]) == {"putnam-a", "putnam-b"}
    skeleton = (tmp_path / "targets" / "putnam-v1" / "skeleton.aisp").read_text("utf-8")
    assert "id≜putnam-a" in skeleton and "id≜putnam-b" in skeleton


def test_main_skips_already_imported_and_accumulates(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "p1.lean").write_text("import Mathlib\n\ntheorem putnam_a : 1 = 1 := by sorry\n", "utf-8")
    (src / "p2.lean").write_text("import Mathlib\n\ntheorem putnam_b : 2 = 2 := by sorry\n", "utf-8")
    argv = ["putnam-v1", str(src), "--supplier", "acme", "--license", "L", "--mathlib", "m",
            "--root", str(tmp_path), "--limit", "1"]

    assert main(argv) == 0  # batch 1 → first obligation only (limit 1)
    assert (tmp_path / "benchmark-goals" / "putnam-a.lean").is_file()
    assert not (tmp_path / "benchmark-goals" / "putnam-b.lean").is_file()

    assert main(argv) == 0  # batch 2 → skips putnam_a, picks up putnam_b
    assert (tmp_path / "benchmark-goals" / "putnam-b.lean").is_file()
    skeleton = (tmp_path / "targets" / "putnam-v1" / "skeleton.aisp").read_text("utf-8")
    assert "id≜putnam-a" in skeleton and "id≜putnam-b" in skeleton  # accumulated

    assert main(argv) == 0  # batch 3 → everything already imported, nothing new


def test_main_skips_a_goal_pre_existing_in_goals_dir(tmp_path):
    """A suite first imported before ADR-110 has its obligations in goals/, not
    benchmark-goals/. Re-importing must still skip them (dedup checks both dirs), or the
    batch would re-import them and overflow the 50-per-package cap."""
    src = tmp_path / "src"
    src.mkdir()
    (src / "p.lean").write_text("import Mathlib\n\ntheorem putnam_a : 1 = 1 := by sorry\n", "utf-8")
    (tmp_path / "goals").mkdir()  # simulate a pre-segregation import (obligation in goals/)
    (tmp_path / "goals" / "putnam-a.lean").write_text("x", "utf-8")
    argv = ["putnam-v1", str(src), "--supplier", "acme", "--license", "L", "--mathlib", "m",
            "--root", str(tmp_path), "--limit", "50"]
    assert main(argv) == 0  # putnam_a already in goals/ → nothing new
    assert not (tmp_path / "benchmark-goals" / "putnam-a.lean").exists()  # not re-imported


def test_batch_cap_enforced(tmp_path):
    problems = [Problem(f"putnam_p{i}", ": True", "P") for i in range(51)]
    with pytest.raises(ImportError_):
        assemble_package(
            tmp_path, "putnam-v1", problems,
            supplier="trishul", domain="lean-math", mathlib="m", toolchain="t", license="L",
        )


# ---------------------------------------------- per-suite pin (ADR-099, #6381)

import json
import subprocess

from tools.intake.tests._fakerunner import FakeRunner

V424 = "leanprover/lean4:v4.24.0"
REV24 = "c5ea00351c28e24afc9f0f84379aa41082b1188f"


def _native_manifest(tmp_path, rev=REV24):
    src = tmp_path / "native-manifest.json"
    src.write_text(
        json.dumps({"version": "1.1.0", "packagesDir": ".lake/packages",
                    "packages": [{"type": "git", "name": "mathlib", "rev": rev}]}),
        "utf-8",
    )
    return src


def _is_probe(path: str) -> bool:
    return path.endswith("TrivialityProbe.lean")


def test_build_verdict_runs_real_build_in_suite_context(tmp_path):
    """Keystone: the real build runs `lake env lean` with cwd = the suite _verify dir,
    NOT the repo root — the core ADR-099 fix."""
    from tools.intake.import_benchmark import _build_verdict

    vctx = tmp_path / "targets" / "minif2f-v1" / "_verify"
    vctx.mkdir(parents=True)
    runner = FakeRunner(default_rc=0)
    assert _build_verdict("theorem t : True := by sorry\n", vctx, runner=runner) == "build-ok"
    call = runner.lean_calls()[0]
    assert call.argv[:3] == ("lake", "env", "lean")
    assert call.cwd == str(vctx)


def test_build_error_quarantines(tmp_path):
    """A statement that does not build under the suite pin (the putnam-1966-b5
    `Finset.toSet` evidence case) is quarantined, with the suite-pin reason."""
    from tools.intake.import_benchmark import build_verdict_of, classify_problems

    vctx = tmp_path / "_verify"
    vctx.mkdir()
    # real build fails for the bad statement; never reaches the probe
    runner = FakeRunner(rc_for_lean=lambda contents, path: 1 if not _is_probe(path) else 0)
    problems = [Problem("putnam_1966_b5", ": Finset.toSet s = s", "P")]
    kept, credit, quarantined = classify_problems(
        problems, verdict_of=build_verdict_of(vctx, runner=runner)
    )
    assert kept == []
    assert quarantined == [("putnam_1966_b5", "does not build under the suite pin")]
    assert runner.lean_calls()[0].cwd == str(vctx)
    # the build gated it BEFORE the foralltype proxy ran (no probe call)
    assert not any(_is_probe(c.argv[-1]) for c in runner.lean_calls())


def test_build_ok_then_battery_classifies_glue_vs_credited(tmp_path):
    from tools.intake.import_benchmark import build_verdict_of, classify_problems

    vctx = tmp_path / "_verify"
    vctx.mkdir()

    def rc_for_lean(contents, path):
        if not _is_probe(path):
            return 0                      # real build always elaborates
        return 0 if "True" in contents else 1   # battery closes `True` (glue), not the rest

    runner = FakeRunner(rc_for_lean=rc_for_lean)
    problems = [Problem("putnam_easy", ": True", "P"), Problem("putnam_hard", ": 1 ≤ 2", "P")]
    kept, credit, quarantined = classify_problems(
        problems, verdict_of=build_verdict_of(vctx, runner=runner)
    )
    assert [p.name for p in kept] == ["putnam_easy", "putnam_hard"]
    assert credit == {"putnam-easy": "glue", "putnam-hard": "credited"}
    assert quarantined == []


def test_real_build_gap_closed(tmp_path):
    """A statement the `foralltype` battery proxy would PASS (its type elaborates) but
    whose real build FAILS is now quarantined — the probe-vs-build gap (#6371)."""
    from tools.intake.import_benchmark import build_verdict_of, classify_problems

    vctx = tmp_path / "_verify"
    vctx.mkdir()
    # real statement fails (rc 1); the proxy probe WOULD pass (rc 0) but is never reached
    runner = FakeRunner(rc_for_lean=lambda contents, path: 0 if _is_probe(path) else 1)
    problems = [Problem("putnam_gap", ": SomeAbbrevThatDoesNotElaborate = 0", "P")]
    kept, credit, quarantined = classify_problems(
        problems, verdict_of=build_verdict_of(vctx, runner=runner)
    )
    assert kept == [] and quarantined[0][1] == "does not build under the suite pin"
    assert runner.lean_calls() and not any(_is_probe(c.argv[-1]) for c in runner.lean_calls())


def test_build_verdict_deterministic(tmp_path):
    from tools.intake.import_benchmark import build_verdict_of

    vctx = tmp_path / "_verify"
    vctx.mkdir()
    verdict_of = build_verdict_of(
        vctx, runner=FakeRunner(rc_for_lean=lambda c, p: 0 if _is_probe(p) else 0)
    )
    text = "theorem t : True := by sorry\n"
    assert verdict_of(text) == verdict_of(text) == "trivial"


def test_quarantine_reason_distinguishes_build_vs_elaborate():
    """The build-fail and probe-error quarantine reasons differ, so an operator can tell
    genuine pin drift from a tooling/elaboration gap."""
    from tools.intake.import_benchmark import classify_problems

    problems = [Problem("putnam_build", ": A", "P"), Problem("putnam_elab", ": B", "P")]

    def verdict_of(text):
        return "build-error" if "putnam_build" in text else "probe-error"

    _, _, quarantined = classify_problems(problems, verdict_of=verdict_of)
    reasons = dict((name, reason) for name, reason in quarantined)
    assert reasons["putnam_build"] == "does not build under the suite pin"
    assert reasons["putnam_elab"] == "does not elaborate under the pinned mathlib"
    assert reasons["putnam_build"] != reasons["putnam_elab"]


def test_native_pin_recorded_in_both_aisp_files(tmp_path):
    """The suite's NATIVE pin (v4.24) lands in skeleton.aisp + target.aisp — not the
    repo pin. (The importer records --mathlib/--toolchain verbatim; the main() guard
    keeps them equal to the verifier-context pin.)"""
    assemble_package(
        tmp_path, "minif2f-v1", [Problem("minif2f_x", ": 1 = 1", "miniF2F")],
        supplier="yangky11", domain="lean-math", mathlib=REV24, toolchain=V424,
        license="MIT",
    )
    pkg = tmp_path / "targets" / "minif2f-v1"
    skeleton = (pkg / "skeleton.aisp").read_text("utf-8")
    assert f"toolchain≜{V424};mathlib≜{REV24}" in skeleton
    assert f"mathlib≜{REV24}" in (pkg / "target.aisp").read_text("utf-8")


def _build_argv(tmp_path, src, *, mathlib=REV24, manifest=None):
    return ["minif2f-v1", str(src), "--supplier", "yangky11", "--license", "MIT",
            "--mathlib", mathlib, "--toolchain", V424, "--root", str(tmp_path),
            "--manifest", str(manifest), "--build"]


def test_main_build_guards_pin_mismatch(tmp_path, monkeypatch):
    """--build aborts (exit 2) and writes NO goals when the --manifest records a mathlib
    rev different from --mathlib — metadata can never diverge from the verifier context."""
    monkeypatch.setattr(subprocess, "run", FakeRunner(cache_rc=0))
    src = tmp_path / "s.lean"
    src.write_text("import Mathlib\n\ntheorem minif2f_a : 1 = 1 := by sorry\n", "utf-8")
    manifest = _native_manifest(tmp_path, rev="DIFFERENT_REV")
    rc = main(_build_argv(tmp_path, src, mathlib=REV24, manifest=manifest))
    assert rc == 2
    assert not (tmp_path / "goals").exists()  # aborted before assemble_package


def test_main_build_uses_suite_context_not_repo_root(tmp_path, monkeypatch):
    """End-to-end --build: every lake call (cache get + env lean) runs in the suite
    _verify dir, never the repo root; the statement imports; a re-run is a no-op."""
    runner = FakeRunner(rc_for_lean=lambda c, p: 1 if _is_probe(p) else 0)  # non-trivial→credited
    monkeypatch.setattr(subprocess, "run", runner)
    src = tmp_path / "s.lean"
    src.write_text("import Mathlib\n\ntheorem minif2f_a : 1 ≤ 2 := by sorry\n", "utf-8")
    manifest = _native_manifest(tmp_path, rev=REV24)

    assert main(_build_argv(tmp_path, src, manifest=manifest)) == 0
    assert (tmp_path / "benchmark-goals" / "minif2f-a.lean").is_file()
    vctx = str(tmp_path / "targets" / "minif2f-v1" / "_verify")
    assert runner.calls and all(c.cwd == vctx for c in runner.calls)  # never the repo root

    # idempotent re-run: already imported, nothing new
    assert main(_build_argv(tmp_path, src, manifest=manifest)) == 0
