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
    assert problems[0].signature == "(x : ℝ) : x + 0 = x"  # abbrev := is not matched
    assert problems[0].source_ref == "PutnamBench"


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


def test_batch_cap_enforced(tmp_path):
    problems = [Problem(f"putnam_p{i}", ": True", "P") for i in range(51)]
    with pytest.raises(ImportError_):
        assemble_package(
            tmp_path, "putnam-v1", problems,
            supplier="trishul", domain="lean-math", mathlib="m", toolchain="t", license="L",
        )
