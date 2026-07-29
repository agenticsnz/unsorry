"""Statement-binding generator tests (ADR-011, SPEC-011-A)."""
from __future__ import annotations

from pathlib import Path

from tools.gate_a.check_statement_binding import clean, generate
from tools.lean_sig import camel_name, foralltype, statement, theorem_name


def _make_proved(tree: Path, goal: str, decl: str, proof: str = "by sorry",
                 module: str | None = None, header: str = "",
                 status: str = "proved"):
    """Create a proved goal: goals/<goal>.{aisp,lean}, a library proof module,
    and the index entry that marks it proved. `header` is prepended to the
    goal `.lean` (import/`open` lines)."""
    (tree / "goals").mkdir(parents=True, exist_ok=True)
    (tree / "library" / "Unsorry").mkdir(parents=True, exist_ok=True)
    (tree / "library" / "index").mkdir(parents=True, exist_ok=True)
    (tree / "goals" / f"{goal}.lean").write_text(
        f"{header}{decl} := by sorry\n", encoding="utf-8")
    (tree / "goals" / f"{goal}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{goal}; phase≜prove; status≜{status}; difficulty≜1}}\n",
        encoding="utf-8",
    )
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


def _make_proved_at_suite(tree: Path, goal: str, decl: str, proof: str = "by sorry",
                          suite: str = "minif2f-v1", status: str = "proved"):
    """A proof made at a SUITE's pin: module and index entry live in the suite
    verification package, never in the repo library (ADR-099/ADR-116)."""
    lib = tree / "targets" / suite / "_verify" / "library"
    (tree / "goals").mkdir(parents=True, exist_ok=True)
    (lib / "Unsorry").mkdir(parents=True, exist_ok=True)
    (lib / "index").mkdir(parents=True, exist_ok=True)
    (tree / "goals" / f"{goal}.lean").write_text(
        f"{decl} := by sorry\n", encoding="utf-8")
    (tree / "goals" / f"{goal}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{goal}; phase≜prove; status≜{status}; difficulty≜1}}\n",
        encoding="utf-8",
    )
    (lib / "Unsorry" / f"{camel_name(goal)}.lean").write_text(
        f"import Mathlib\n\n{decl} := {proof}\n", encoding="utf-8")
    sha = "1" * 64
    name = theorem_name(decl + " := by sorry")
    (lib / "index" / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-07-29\nγ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{name}}}\n"
        f"⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )
    return lib


def test_suite_pinned_proof_gets_a_binding(tmp_path):
    """ADR-011 must bind benchmark proofs too (#7191).

    `check_in_proof` DELETES the agent's own binding before opening the PR, on
    the understanding that Gate A regenerates it. For a suite-pinned proof that
    regeneration never happened — the generator read only `library/index` — so
    statement identity was verified on the proving agent's machine and nowhere
    else. A weakened restatement under the goal's name would have passed.
    """
    lib = _make_proved_at_suite(
        tmp_path, "bench-goal",
        "theorem bench_goal (a b : Nat) : a + b = b + a",
        proof="Nat.add_comm a b")
    assert generate(tmp_path) == 0
    binding = lib / "Unsorry" / "BenchGoalBinding.lean"
    assert binding.is_file(), "no binding generated for a suite-pinned proof"
    text = binding.read_text(encoding="utf-8")
    assert "import Unsorry.BenchGoal" in text
    assert "theorem bench_goal_binding_check" in text
    # It must land in the SUITE library, beside its module — not the repo one.
    assert not (tmp_path / "library" / "Unsorry" / "BenchGoalBinding.lean").exists()


def test_suite_binding_asserts_the_goal_type_not_the_modules(tmp_path):
    """The binding restates the GOAL's type, so a weaker module fails to inhabit it."""
    lib = _make_proved_at_suite(
        tmp_path, "weak-goal",
        "theorem weak_goal (a b : Nat) : a + b = b + a",
        proof="Nat.add_comm a b")
    assert generate(tmp_path) == 0
    text = (lib / "Unsorry" / "WeakGoalBinding.lean").read_text(encoding="utf-8")
    assert foralltype("theorem weak_goal (a b : Nat) : a + b = b + a := by sorry") in text


def test_clean_removes_suite_bindings_too(tmp_path):
    lib = _make_proved_at_suite(
        tmp_path, "bench-goal",
        "theorem bench_goal (a b : Nat) : a + b = b + a",
        proof="Nat.add_comm a b")
    generate(tmp_path)
    assert (lib / "Unsorry" / "BenchGoalBinding.lean").is_file()
    clean(tmp_path)
    assert not (lib / "Unsorry" / "BenchGoalBinding.lean").exists(), \
        "suite binding survived clean — it would be committed as stale glue"


def test_generate_writes_canonical_binding(tmp_path):
    _make_proved(tmp_path, "nat-add-comm-thm",
                 "theorem nat_add_comm_thm (a b : Nat) : a + b = b + a",
                 proof="Nat.add_comm a b")
    assert generate(tmp_path) == 0
    binding = tmp_path / "library" / "Unsorry" / "NatAddCommThmBinding.lean"
    assert binding.read_text(encoding="utf-8") == (
        "import Unsorry.NatAddCommThm\n\n"
        "set_option linter.unusedVariables false in\n"
        "theorem nat_add_comm_thm_binding_check : "
        "∀ (a b : Nat), a + b = b + a := nat_add_comm_thm\n"
    )


def test_generate_suppresses_unused_variable_lint(tmp_path):
    # A named hypothesis binder after an implicit binder (the
    # not-prime-pow-four-add-four shape) is eta-expanded by the elaborator and
    # flagged by linter.unusedVariables, failing --wfail for any correct proof.
    # The generated obligation must therefore disable that lint for itself.
    _make_proved(tmp_path, "not-prime-pow-four-add-four",
                 "theorem not_prime_pow_four_add_four {n : ℕ} (hn : 1 < n) : "
                 "¬ Nat.Prime (n ^ 4 + 4)")
    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry"
               / "NotPrimePowFourAddFourBinding.lean").read_text(encoding="utf-8")
    assert "set_option linter.unusedVariables false in\n" in binding
    assert ("theorem not_prime_pow_four_add_four_binding_check : "
            "∀ {n : ℕ} (hn : 1 < n), ¬ Nat.Prime (n ^ 4 + 4) "
            ":= not_prime_pow_four_add_four\n") in binding


def test_generate_carries_goal_open_commands(tmp_path):
    # A goal stated under `open Finset` (the batch-3 shape, PR #259) names
    # `range` unqualified; the regenerated obligation must elaborate in the
    # goal's own namespace context, so the goal file's `open` commands travel
    # with the type — placed after the import, before the obligation.
    _make_proved(
        tmp_path, "sum-range-pentagonal-closed-form",
        "theorem sum_range_pentagonal_closed_form (n : ℕ) : "
        "2 * (∑ k ∈ range (n + 1), (3 * k^2 - k) / 2) = n^2 * (n + 1)",
        header="import Mathlib.Algebra.BigOperators.Intervals\n\nopen Finset\n\n")
    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry"
               / "SumRangePentagonalClosedFormBinding.lean").read_text(encoding="utf-8")
    assert "open Finset\n" in binding
    assert binding.index("import ") < binding.index("open Finset")
    assert binding.index("open Finset") < binding.index(
        "theorem sum_range_pentagonal_closed_form_binding_check")


def test_generate_carries_goal_imports_before_proof_module(tmp_path):
    # Regression: a goal may state its type using notation provided by its own
    # imports (`ℕ` from Mathlib), while the proof module proves the same theorem
    # with core names (`Nat`) and therefore does not import Mathlib. The binding
    # restates the goal's type, so it must carry the goal imports too.
    _make_proved(
        tmp_path, "nat-pow-helper",
        "theorem nat_pow_helper (n : ℕ) : n = n",
        proof="rfl",
        header="import Mathlib\n\n",
    )
    (tmp_path / "library" / "Unsorry" / "NatPowHelper.lean").write_text(
        "theorem nat_pow_helper (n : Nat) : n = n := rfl\n",
        encoding="utf-8",
    )

    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry" / "NatPowHelperBinding.lean").read_text(
        encoding="utf-8"
    )
    assert binding.startswith("import Mathlib\nimport Unsorry.NatPowHelper\n\n")


def test_generate_without_opens_is_byte_identical_to_canonical(tmp_path):
    # No `open` in the goal file → the obligation keeps the exact canonical
    # shape (regression guard for the pre-open generator output).
    _make_proved(tmp_path, "nat-y", "theorem nat_y (n : Nat) : n = n", proof="rfl")
    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry" / "NatYBinding.lean").read_text(
        encoding="utf-8")
    assert binding == (
        "import Unsorry.NatY\n\n"
        "set_option linter.unusedVariables false in\n"
        "theorem nat_y_binding_check : ∀ (n : Nat), n = n := nat_y\n"
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


def test_generate_skips_archived_goal(tmp_path):
    _make_proved(tmp_path, "old-proof",
                 "theorem old_proof (n : Nat) : n = n",
                 proof="rfl", status="archived")
    (tmp_path / "library" / "Unsorry" / "OldProof.lean").unlink()
    assert generate(tmp_path) == 0
    assert not (tmp_path / "library" / "Unsorry" / "OldProofBinding.lean").exists()


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


def test_generate_skips_private_name_collision(tmp_path):
    # A theorem name can collide with a `private` helper in an alphabetically
    # earlier module (a recompose proof re-using a sub-lemma's name). The binding
    # must bind to the PUBLIC proof module, not the unreferenceable private one.
    # Regression: goal nat-sq-lt-two-pow-s2 looped on #679/#963/#1173 because the
    # binding imported the parent's `private theorem sq_lt_two_pow_step_from_five`.
    _make_proved(tmp_path, "nat-step-s2",
                 "theorem step_from_five (n : Nat) : n = n",
                 proof="rfl")
    # alphabetically-earlier module re-declaring the same name as private
    (tmp_path / "library" / "Unsorry" / "NatStep.lean").write_text(
        "import Mathlib\n\nprivate theorem step_from_five (n : Nat) : n = n := rfl\n",
        encoding="utf-8")
    assert generate(tmp_path) == 0
    binding = (tmp_path / "library" / "Unsorry" / "NatStepS2Binding.lean").read_text(encoding="utf-8")
    assert "import Unsorry.NatStepS2\n" in binding      # the public proof module
    assert "import Unsorry.NatStep\n" not in binding    # not the private collision
    assert ":= step_from_five\n" in binding
