import Mathlib

/-- Goal `prod-pair-sums-ge-eight-ninths-sum-prod`:
`8(a+b+c)(ab+bc+ca) ≤ 9(a+b)(b+c)(c+a)` for nonnegative reals. Since
`(a+b)(b+c)(c+a) = (a+b+c)(ab+bc+ca) - abc`, it reduces to
`(a+b+c)(ab+bc+ca) ≥ 9abc`, i.e. `∑ a(b-c)² ≥ 0`. See `library/index/`. -/
theorem prod_pair_sums_ge_eight_ninths_sum_prod (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) : 8 * (a + b + c) * (a * b + b * c + c * a) ≤ 9 * ((a + b) * (b + c) * (c + a)) := by
  nlinarith [mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (c - a)),
    mul_nonneg hc (sq_nonneg (a - b))]
