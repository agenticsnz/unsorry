"""gen_triples tests (ADR-060 / SPEC-060-A). A generated triple must round-trip
through Gate B clean, and match the SPEC-003-A fresh-goal schema exactly."""
from __future__ import annotations

import pytest

from tools.gate_b.validator import validate_tree
from tools.sourcing.gen_triples import (
    TripleError,
    main,
    parse_candidate,
    render_aisp,
    render_lean,
    snake,
    valid_slug,
    write_triple,
)

_COMMON = dict(
    lean_sig="(n : Nat) : 0 < n + 1",
    statement="The successor of any natural number is positive.",
    source="#400 Identity Engine (ADR-043) — order family.",
    reference="Not a named mathlib lemma in this form.",
    absence="no-local-match (grep of pinned mathlib rev abc123, 2026-06-16).",
    triviality="machine-checked non-trivial (battery v1, rev abc123, 2026-06-16).",
    difficulty=3,
    decomposition="omega after Nat.succ_pos; verify with lake env lean.",
)


def test_snake_and_slug_rules():
    assert snake("alternating-sum-shifted-choose-eq-one") == "alternating_sum_shifted_choose_eq_one"
    assert valid_slug("nat-succ-pos")
    assert not valid_slug("Nat-Succ")        # uppercase
    assert not valid_slug("-leading-hyphen")  # leading hyphen
    assert not valid_slug("has.dot")          # dots reserved


def test_lean_stub_is_canonical():
    text = render_lean("nat-succ-pos", "(n : Nat) : 0 < n + 1")
    assert text == "import Mathlib\n\ntheorem nat_succ_pos (n : Nat) : 0 < n + 1 := by\n  sorry\n"


def test_aisp_is_fresh_open_schema():
    text = render_aisp("nat-succ-pos", 3, "2026-06-16", -20)
    assert text.startswith("𝔸5.1.goal.nat-succ-pos@2026-06-16\nγ≔unsorry.goal\n")
    assert "  id≜nat-succ-pos\n" in text and "  phase≜prove\n" in text
    assert "  status≜open\n" in text and "  difficulty≜3\n" in text
    assert "  sha≜∅\n" in text and "  aff≜-20\n" in text          # open ⇒ empty sha
    assert text.rstrip("\n").endswith("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")          # exact band seed
    assert text.endswith("\n")                                     # trailing newline


def test_generated_triple_passes_gate_b(tmp_path):
    paths = write_triple(tmp_path, "nat-succ-pos", date="2026-06-16", **_COMMON)
    assert [p.name for p in paths] == ["nat-succ-pos.lean", "nat-succ-pos.aisp", "nat-succ-pos.md"]
    assert (tmp_path / "goals" / "nat-succ-pos.aisp").exists()
    assert (tmp_path / "backlog" / "nat-succ-pos.md").exists()
    violations = validate_tree(tmp_path)
    assert violations == [], "\n".join(str(v) for v in violations)


def test_refuses_to_clobber_without_force(tmp_path):
    write_triple(tmp_path, "nat-succ-pos", date="2026-06-16", **_COMMON)
    with pytest.raises(TripleError, match="already exists"):
        write_triple(tmp_path, "nat-succ-pos", date="2026-06-16", **_COMMON)
    # --force overwrites
    write_triple(tmp_path, "nat-succ-pos", date="2026-06-16", force=True, **_COMMON)


def test_rejects_bad_slug_and_difficulty(tmp_path):
    with pytest.raises(TripleError, match="invalid slug"):
        write_triple(tmp_path, "Bad.Slug", date="2026-06-16", **_COMMON)
    bad = dict(_COMMON, difficulty=7)
    with pytest.raises(TripleError, match="out of range"):
        write_triple(tmp_path, "nat-succ-pos", date="2026-06-16", **bad)


def test_parse_candidate():
    slug, statement = parse_candidate(
        "- [ ] `four_not_dvd_sq_add_two` — Every natural number's square plus two is never divisible by four\n"
        "      absence: no-local-match · triviality: non-trivial · conf: high"
    )
    assert slug == "four-not-dvd-sq-add-two"
    assert statement.startswith("Every natural number's square plus two")


def test_main_writes_and_validates(tmp_path, capsys):
    rc = main([
        "--slug", "nat-succ-pos", "--lean-sig", "(n : Nat) : 0 < n + 1",
        "--statement", _COMMON["statement"], "--difficulty", "3",
        "--source", _COMMON["source"], "--reference", _COMMON["reference"],
        "--absence", _COMMON["absence"], "--triviality", _COMMON["triviality"],
        "--decomposition", _COMMON["decomposition"],
        "--date", "2026-06-16", "--root", str(tmp_path), "--validate",
    ])
    assert rc == 0
    assert "Gate B: clean" in capsys.readouterr().err
