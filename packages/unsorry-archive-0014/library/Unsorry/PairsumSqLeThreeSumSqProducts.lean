import Mathlib

/-- Goal `pairsum-sq-le-three-sum-sq-products`:
`(ab+bc+ca)² ≤ 3(a²b²+b²c²+c²a²)`. SOS via `nlinarith` (it is `(x+y+z)² ≤
3(x²+y²+z²)` with `x=ab` etc.). See `library/index/`. -/
theorem pairsum_sq_le_three_sum_sq_products (a b c : ℝ) :
    (a * b + b * c + c * a) ^ 2 ≤ 3 * (a ^ 2 * b ^ 2 + b ^ 2 * c ^ 2 + c ^ 2 * a ^ 2) := by
  nlinarith [sq_nonneg (a * b - b * c), sq_nonneg (b * c - c * a), sq_nonneg (c * a - a * b)]
