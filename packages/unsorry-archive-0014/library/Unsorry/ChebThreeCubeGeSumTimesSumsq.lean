import Mathlib

/-- Goal `cheb-three-cube-ge-sum-times-sumsq`:
`(a+b+c)(a²+b²+c²) ≤ 3(a³+b³+c³)` for nonnegative reals (Chebyshev sum). The gap
is `∑_{i<j} (aᵢ-aⱼ)²(aᵢ+aⱼ) ≥ 0`; `nlinarith` combines the three. See
`library/index/`. -/
theorem cheb_three_cube_ge_sum_times_sumsq (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) : (a + b + c) * (a ^ 2 + b ^ 2 + c ^ 2) ≤ 3 * (a ^ 3 + b ^ 3 + c ^ 3) := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (add_nonneg ha hb),
    mul_nonneg (sq_nonneg (b - c)) (add_nonneg hb hc),
    mul_nonneg (sq_nonneg (a - c)) (add_nonneg ha hc)]
