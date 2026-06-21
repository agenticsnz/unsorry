import Mathlib

/-- Goal `sum-cubes-sq-le-three-sum-sixth`: `(a³+b³+c³)² ≤ 3(a⁶+b⁶+c⁶)`. SOS via
`nlinarith` (it is `(x+y+z)² ≤ 3(x²+y²+z²)` with `x=a³`). See `library/index/`. -/
theorem sum_cubes_sq_le_three_sum_sixth (a b c : ℝ) :
    (a ^ 3 + b ^ 3 + c ^ 3) ^ 2 ≤ 3 * (a ^ 6 + b ^ 6 + c ^ 6) := by
  nlinarith [sq_nonneg (a ^ 3 - b ^ 3), sq_nonneg (b ^ 3 - c ^ 3), sq_nonneg (c ^ 3 - a ^ 3)]
