import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-!
# An eighth-multiple bound for the fourth power of a sum

For real numbers `a` and `b`, the fourth power of their sum is bounded above by
eight times the sum of their fourth powers.  The gap factors as
`(a - b) ^ 2 * (7 * a ^ 2 + 10 * a * b + 7 * b ^ 2)`, and the second factor is
itself `5 * (a + b) ^ 2 + 2 * a ^ 2 + 2 * b ^ 2`, manifestly nonnegative.
-/

theorem eight_sum_pow_four_ge_sum_pow_four (a b : ℝ) :
    (a + b) ^ 4 ≤ 8 * (a ^ 4 + b ^ 4) := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (sq_nonneg (a + b)),
    mul_nonneg (sq_nonneg (a - b)) (sq_nonneg a),
    mul_nonneg (sq_nonneg (a - b)) (sq_nonneg b)]
