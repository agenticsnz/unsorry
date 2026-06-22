import Mathlib

/-- Goal `sum-sq-times-pairsum-ge-three-abc-sum`:
`3abc(a+b+c) ≤ (a²+b²+c²)(ab+bc+ca)` for nonnegative reals. The gap is
`∑ ab(a-b)² + ∑ (ab-bc)² ≥ 0`; `nlinarith` combines them. See `library/index/`. -/
theorem sum_sq_times_pairsum_ge_three_abc_sum (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) : 3 * a * b * c * (a + b + c) ≤ (a ^ 2 + b ^ 2 + c ^ 2) * (a * b + b * c + c * a) := by
  nlinarith [mul_nonneg (mul_nonneg ha hb) (sq_nonneg (a - b)),
    mul_nonneg (mul_nonneg hb hc) (sq_nonneg (b - c)),
    mul_nonneg (mul_nonneg hc ha) (sq_nonneg (c - a)),
    sq_nonneg (a * b - b * c), sq_nonneg (b * c - c * a), sq_nonneg (c * a - a * b)]
