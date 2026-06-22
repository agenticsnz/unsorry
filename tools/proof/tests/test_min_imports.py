"""Tests for the ADR-074 minimal-import candidate generator."""
from __future__ import annotations

from tools.proof.min_imports import (
    BROAD_IMPORT,
    TACTIC_UMBRELLA,
    candidate_imports,
    main,
    rewrite_imports,
)

# A real ZMod divisibility proof shaped like the live backlog (#2397).
ZMOD_PROOF = """import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_21_sub_pow_seventeen (n : ℤ) : (240 : ℤ) ∣ n ^ 21 - n ^ 17 := by
  have h : ∀ m : ZMod 240, m ^ 21 - m ^ 17 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 17 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 17) 240).mp hz
  exact_mod_cast hdvd
"""


def test_zmod_proof_narrows_to_zmod_basic_and_tactic():
    mods = candidate_imports(ZMOD_PROOF)
    assert mods == ["import Mathlib.Data.ZMod.Basic", TACTIC_UMBRELLA]


def test_math_module_precedes_tactic_umbrella():
    # Order matters: the math module is emitted before the tactic umbrella.
    mods = candidate_imports(ZMOD_PROOF)
    assert mods.index("import Mathlib.Data.ZMod.Basic") < mods.index(TACTIC_UMBRELLA)


def test_already_narrow_is_left_untouched():
    src = "import Mathlib.Algebra.Group.Basic\n\ntheorem t : True := trivial\n"
    assert candidate_imports(src) is None


def test_multiple_imports_left_untouched():
    src = "import Mathlib\nimport Mathlib.Tactic\n\ntheorem t : True := trivial\n"
    assert candidate_imports(src) is None


def test_no_known_feature_proposes_nothing():
    # Broad import but no mapped math feature (and no ZMod): fall back, propose None
    # rather than a tactic-only block guaranteed to miss the proof's lemmas.
    src = "import Mathlib\n\ntheorem t : 1 + 1 = 2 := rfl\n"
    assert candidate_imports(src) is None


def test_zmod_without_tactics_skips_umbrella():
    src = "import Mathlib\n\ntheorem t (m : ZMod 2) : m = m := rfl\n"
    assert candidate_imports(src) == ["import Mathlib.Data.ZMod.Basic"]


def test_rewrite_replaces_only_the_import_line():
    mods = ["import Mathlib.Data.ZMod.Basic", TACTIC_UMBRELLA]
    out = rewrite_imports(ZMOD_PROOF, mods)
    assert out.startswith("import Mathlib.Data.ZMod.Basic\n" + TACTIC_UMBRELLA + "\n")
    assert BROAD_IMPORT + "\n" not in out
    # Body is preserved verbatim, including the set_option line and the proof.
    assert "set_option maxRecDepth 40000 in" in out
    assert "exact_mod_cast hdvd" in out
    assert out.endswith("\n")


def test_rewrite_is_idempotent_on_body():
    mods = candidate_imports(ZMOD_PROOF)
    once = rewrite_imports(ZMOD_PROOF, mods)
    # The narrowed file no longer matches the broad default, so it is left alone.
    assert candidate_imports(once) is None


def test_cli_emits_narrowed_module(tmp_path, capsys):
    f = tmp_path / "Proof.lean"
    f.write_text(ZMOD_PROOF, encoding="utf-8")
    rc = main([str(f)])
    assert rc == 0
    out = capsys.readouterr().out
    assert out.startswith("import Mathlib.Data.ZMod.Basic\n")
    assert "exact_mod_cast hdvd" in out


def test_cli_returns_1_when_nothing_to_narrow(tmp_path):
    f = tmp_path / "Proof.lean"
    f.write_text("import Mathlib.Tactic\n\ntheorem t : True := trivial\n",
                 encoding="utf-8")
    assert main([str(f)]) == 1


def test_cli_usage_error_without_arg():
    assert main([]) == 2
