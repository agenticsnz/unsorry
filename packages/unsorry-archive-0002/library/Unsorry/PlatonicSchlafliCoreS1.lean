import Lean.Linter.UnusedVariables
import Unsorry.PlatonicSchlafliCoreS1S1
import Unsorry.PlatonicSchlafliCoreS1S2
import Unsorry.PlatonicSchlafliCoreS1S3

/-!
# `nat_lt_six_of_inv_gt_sixth` (goal `platonic-schlafli-core-s1`)

For a natural `n` with `(n : ℚ)⁻¹ > 6⁻¹`, we have `n < 6`. By contradiction:
composing the kernel-verified sub-lemmas of this goal family (ADR-014), if
`¬ n < 6` then `6 ≤ n` (`nat_six_le_of_not_lt_six`), so `(6 : ℚ) ≤ (n : ℚ)`
(`rat_cast_six_le_of_six_le`), so `(n : ℚ)⁻¹ ≤ 6⁻¹` by antitonicity of
inversion on the positives (`rat_inv_le_inv_six_of_six_le`) — contradicting
the hypothesis.
-/

theorem nat_lt_six_of_inv_gt_sixth (n : ℕ) (h : (n : ℚ)⁻¹ > 6⁻¹) : n < 6 := by
  by_contra hn
  exact absurd h (not_lt.mpr (rat_inv_le_inv_six_of_six_le (n : ℚ)
    (rat_cast_six_le_of_six_le n (nat_six_le_of_not_lt_six n hn))))

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (n : ℕ) (h : (n : ℚ)⁻¹ > 6⁻¹), n < 6`, copying the goal's
binder names verbatim. `h` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS1.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
