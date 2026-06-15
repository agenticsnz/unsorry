import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Algebra.Order.GroupWithZero.Unbundled.Basic
import Mathlib.Tactic.NormNum

/-!
# `rat_inv_le_inv_six_of_six_le` (goal `platonic-schlafli-core-s1-s2`)

For any rational `q` with `6 ≤ q`, we have `q⁻¹ ≤ 6⁻¹`: inversion is antitone
on the positives (`inv_anti₀`), and `0 < 6 ≤ q`.
-/

theorem rat_inv_le_inv_six_of_six_le (q : ℚ) (h : (6 : ℚ) ≤ q) : q⁻¹ ≤ (6 : ℚ)⁻¹ :=
  inv_anti₀ (by norm_num) h

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (q : ℚ) (h : (6 : ℚ) ≤ q), q⁻¹ ≤ (6 : ℚ)⁻¹`, copying the goal's
binder names verbatim. `h` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS1S2.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
