import Mathlib

/-- Goal `schur-inequality-deg-one`: Schur's inequality at `t = 1`,
`0 ≤ a(a-b)(a-c) + b(b-a)(b-c) + c(c-a)(c-b)` for nonnegative reals. Proved by
splitting on the order of `a, b, c`; `nlinarith` closes each case. See
`library/index/`. -/
theorem schur_inequality_deg_one (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) :
    0 ≤ a * (a - b) * (a - c) + b * (b - a) * (b - c) + c * (c - a) * (c - b) := by
  rcases le_total a b with h1 | h1 <;> rcases le_total b c with h2 | h2 <;>
    rcases le_total a c with h3 | h3 <;>
    nlinarith [mul_nonneg ha (sq_nonneg (a - b)), mul_nonneg hb (sq_nonneg (b - c)),
      mul_nonneg hc (sq_nonneg (a - c)), mul_nonneg ha (sq_nonneg (a - c)),
      mul_nonneg hb (sq_nonneg (a - b)), mul_nonneg hc (sq_nonneg (b - c)),
      mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)),
      mul_nonneg hc (sq_nonneg (a - b))]
