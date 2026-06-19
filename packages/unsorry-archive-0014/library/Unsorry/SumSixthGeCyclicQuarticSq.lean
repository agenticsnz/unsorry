import Mathlib

/-- Goal `sum-sixth-ge-cyclic-quartic-sq`: `a⁴b²+b⁴c²+c⁴a² ≤ a⁶+b⁶+c⁶`. Each
weighted-AM-GM step `2x⁶+y⁶-3x⁴y² = (x²-y²)²(2x²+y²) ≥ 0`; `nlinarith` combines
the three. See `library/index/`. -/
theorem sum_sixth_ge_cyclic_quartic_sq (a b c : ℝ) :
    a ^ 4 * b ^ 2 + b ^ 4 * c ^ 2 + c ^ 4 * a ^ 2 ≤ a ^ 6 + b ^ 6 + c ^ 6 := by
  nlinarith [mul_nonneg (sq_nonneg (a ^ 2 - b ^ 2)) (show (0 : ℝ) ≤ 2 * a ^ 2 + b ^ 2 by positivity),
    mul_nonneg (sq_nonneg (b ^ 2 - c ^ 2)) (show (0 : ℝ) ≤ 2 * b ^ 2 + c ^ 2 by positivity),
    mul_nonneg (sq_nonneg (c ^ 2 - a ^ 2)) (show (0 : ℝ) ≤ 2 * c ^ 2 + a ^ 2 by positivity)]
