"""Statement-binding generator tests (ADR-011, SPEC-011-A)."""
from __future__ import annotations

from pathlib import Path

from tools.gate_a.check_statement_binding import clean, generate
from tools.lean_sig import camel_name, foralltype, statement, theorem_name


def _make_proved(tree: Path, goal: str, decl: str, proof: str = "by sorry",
                 module: str | None = None):
    """Create a proved goal: goals/<goal>.{aisp,lean}, a library proof module,
    and the index entry that marks it proved."""
    (tree / "goals").mkdir(parents=True, exist_ok=True)
    (tree / "library" / "Unsorry").mkdir(parents=True, exist_ok=True)
    (tree / "library" / "index").mkdir(parents=True, exist_ok=True)
    (tree / "goals" / f"{goal}.lean").write_text(f"{decl} := by sorry\n", encoding="utf-8")
    mod = module or camel_name(goal)
    (tree / "library" / "Unsorry" / f"{mod}.lean").write_text(
        f"import Mathlib\n\n{decl} := {proof}\n", encoding="utf-8"
    )
    sha = "0" * 64
    name = theorem_name(decl + " := by sorry")
    (tree / "library" / "index" / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-06-10\nγ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{name}}}\n"
        f"⟦Σ:Stmt⟧{{\n  stmt≜{statement(decl + ' := by sorry')}\n}}\n"
        f"⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def test_generate_writes_canonical_binding(tmp_path):
    _make_proved(tmp_path, "nat-add-comm-thm",
                 "theorem nat_add_comm_thm (a b : Nat) : a + b = b + a",
                 proof="Nat.add_comm a b")
    assert generate(tmp_path) == 0
    binding = tmp_path / "library" / "Unsorry" / "NatAddCommThmBinding.lean"
    assert binding.read_text(encoding="utf-8") == (
        "import Unsorry.NatAddCommThm\n\n"
        "theorem nat_add_comm_thm_binding_check : "
        "∀ (a b : Nat), a + b = b + a := nat_add_comm_thm\n"
    )


def test_generate_finds_module_by_theorem_name(tmp_path):
    # Proof lives in a non-conventional module (the grandfathered Basic.lean
    # case) — the generator must find it by content, not assume <Camel>.lean.
    _make_proved(tmp_path, "nat-zero-lt-succ",
                 "theorem nat_zero_lt_succ (n : Nat) : 0 < n + 1",
                 proof="Nat.succ_pos n", module="Basic")
    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry" / "NatZeroLtSuccBinding.lean").read_text()
    assert "import Unsorry.Basic" in binding
    assert "nat_zero_lt_succ_binding_check" in binding


def test_generate_errors_when_no_module_declares_the_theorem(tmp_path):
    _make_proved(tmp_path, "lonely",
                 "theorem lonely (n : Nat) : n = n", proof="rfl")
    # Delete the proof module so nothing declares `lonely`.
    (tmp_path / "library" / "Unsorry" / "Lonely.lean").unlink()
    assert generate(tmp_path) == 1


def test_clean_removes_only_bindings(tmp_path):
    _make_proved(tmp_path, "nat-x", "theorem nat_x (n : Nat) : n = n", proof="rfl")
    generate(tmp_path)
    assert list((tmp_path / "library" / "Unsorry").glob("*Binding.lean"))
    clean(tmp_path)
    assert not list((tmp_path / "library" / "Unsorry").glob("*Binding.lean"))
    assert (tmp_path / "library" / "Unsorry" / "NatX.lean").exists()  # proof kept


def test_foralltype_no_binders():
    assert foralltype("theorem t : 1 = 1 := rfl") == "1 = 1"


def test_foralltype_implicit_and_instance_binders():
    decl = "theorem t {α : Type} [Add α] (a : α) : a = a := rfl"
    assert foralltype(decl) == "∀ {α : Type} [Add α] (a : α), a = a"


def test_grandfathered_entry_without_goal_lean_is_skipped(tmp_path):
    # An index entry whose goal has no goals/<g>.lean (a translate/grandfathered
    # manual lemma) is skipped, not failed — there is no goal type to bind.
    (tmp_path / "goals").mkdir(parents=True, exist_ok=True)
    (tmp_path / "library" / "Unsorry").mkdir(parents=True, exist_ok=True)
    (tmp_path / "library" / "index").mkdir(parents=True, exist_ok=True)
    (tmp_path / "library" / "Unsorry" / "Basic.lean").write_text(
        "theorem grand : True := trivial\n", encoding="utf-8")
    sha = "0" * 64
    (tmp_path / "library" / "index" / f"{sha}.aisp").write_text(
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜grand-old; name≜grand}}\n", encoding="utf-8")
    assert generate(tmp_path) == 0
    assert not list((tmp_path / "library" / "Unsorry").glob("*Binding.lean"))
