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

    # 2. the swarm-visible top-level goals are Gate-B clean
    assert validate_tree(tmp_path) == []
    assert (tmp_path / "goals" / "putnam-1988-b2.aisp").is_file()
    assert (tmp_path / "backlog" / "putnam-1988-b2.md").is_file()

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
    # the quarantined statement was never imported; the rest are
    assert not (tmp_path / "goals" / "putnam-bad.lean").exists()
    assert (tmp_path / "goals" / "putnam-easy.lean").exists()
    assert (tmp_path / "goals" / "putnam-hard.lean").exists()
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
    goal = (tmp_path / "goals" / "putnam-2017-a1.lean").read_text("utf-8")
    # the concrete answer is bundled (so the statement is fixed + provable, not opaque)
    assert f"abbrev putnam_2017_a1_solution : Set ℤ := {ANSWER}" in goal
    assert "theorem putnam_2017_a1" in goal
    assert goal.rstrip().endswith("sorry")  # the obligation sorry is still the last token


def test_batch_cap_enforced(tmp_path):
    problems = [Problem(f"putnam_p{i}", ": True", "P") for i in range(51)]
    with pytest.raises(ImportError_):
        assemble_package(
            tmp_path, "putnam-v1", problems,
            supplier="trishul", domain="lean-math", mathlib="m", toolchain="t", license="L",
        )
