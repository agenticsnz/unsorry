import Mathlib

/-- Goal `three-quartic-ge-sum-times-cubes`:
`(a+b+c)(a³+b³+c³) ≤ 3(a⁴+b⁴+c⁴)` for nonnegative reals (Chebyshev sum). The gap
is `∑_{i<j} (aᵢ-aⱼ)²(aᵢ²+aᵢaⱼ+aⱼ²) ≥ 0`; `nlinarith` combines the three. See
`library/index/`. -/
theorem three_quartic_ge_sum_times_cubes (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) : (a + b + c) * (a ^ 3 + b ^ 3 + c ^ 3) ≤ 3 * (a ^ 4 + b ^ 4 + c ^ 4) := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (show (0 : ℝ) ≤ a ^ 2 + a * b + b ^ 2 by positivity),
    mul_nonneg (sq_nonneg (b - c)) (show (0 : ℝ) ≤ b ^ 2 + b * c + c ^ 2 by positivity),
    mul_nonneg (sq_nonneg (a - c)) (show (0 : ℝ) ≤ a ^ 2 + a * c + c ^ 2 by positivity)]
