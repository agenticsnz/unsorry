import Mathlib

/-- Goal `cube-of-sum-le-nine-sum-cubes`: `(a+b+c)³ ≤ 9(a³+b³+c³)` for nonnegative
reals. SOS via `nlinarith` on `x·(y-z)²` terms. See `library/index/`. -/
theorem cube_of_sum_le_nine_sum_cubes (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) : (a + b + c) ^ 3 ≤ 9 * (a ^ 3 + b ^ 3 + c ^ 3) := by
  nlinarith [mul_nonneg ha (sq_nonneg (a - b)), mul_nonneg hb (sq_nonneg (a - b)),
    mul_nonneg hb (sq_nonneg (b - c)), mul_nonneg hc (sq_nonneg (b - c)),
    mul_nonneg ha (sq_nonneg (a - c)), mul_nonneg hc (sq_nonneg (a - c)),
    mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)),
    mul_nonneg hc (sq_nonneg (a - b))]
