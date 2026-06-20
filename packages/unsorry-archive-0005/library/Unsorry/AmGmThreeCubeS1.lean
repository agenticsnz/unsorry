import Mathlib

/-!
# Four times a product is bounded by the square of the sum

For nonnegative reals `a` and `b`, we have `4 * (a * b) ≤ (a + b) ^ 2`.
This is the two-variable arithmetic/geometric inequality in squared form,
following directly from `0 ≤ (a - b) ^ 2`. The nonnegativity hypotheses are not
needed (the bound holds for all reals), so their binders are underscored to
satisfy `linter.unusedVariables` under the Gate A `--wfail` build.
-/

theorem am_gm_two_square (a b : ℝ) (_ha : 0 ≤ a) (_hb : 0 ≤ b) :
    4 * (a * b) ≤ (a + b) ^ 2 := by
  nlinarith [sq_nonneg (a - b)]
