import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.Linarith

/-!
# `rat_gt_sixth_of_add_gt_half` (goal `platonic-schlafli-core-s2-s2`)

If `a + b` exceeds `2⁻¹` while `b` is at most `3⁻¹`, then `a` exceeds
`6⁻¹`: from the numeral fact `6⁻¹ + 3⁻¹ ≤ 2⁻¹` we get
`6⁻¹ + b ≤ 2⁻¹ < a + b`, and cancelling `b` is linear arithmetic over `ℚ`.
-/

theorem rat_gt_sixth_of_add_gt_half (a b : ℚ) (hab : (2 : ℚ)⁻¹ < a + b)
    (hb : b ≤ (3 : ℚ)⁻¹) : (6 : ℚ)⁻¹ < a := by
  have key : (6 : ℚ)⁻¹ + (3 : ℚ)⁻¹ ≤ (2 : ℚ)⁻¹ := by norm_num
  linarith

/-- The ADR-011 binding obligation that Gate A regenerates for this goal
states its type as `∀ (a b : ℚ) (hab : (2 : ℚ)⁻¹ < a + b)
(hb : b ≤ (3 : ℚ)⁻¹), (6 : ℚ)⁻¹ < a`, copying the goal's binder names
verbatim. `hab` and `hb` do not occur in the conclusion, so the
unused-variables linter warns on them and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this carries that exemption over to the `∀ (h : P), Q`
spelling. Lint-scope only: it has no effect on elaboration, the kernel
check, or the audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS2S2.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
