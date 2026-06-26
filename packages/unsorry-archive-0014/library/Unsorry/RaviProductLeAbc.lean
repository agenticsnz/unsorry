import Mathlib

/-- Goal `ravi-product-le-abc`: for a triangle (Ravi positivity
`a+b-c, b+c-a, c+a-b ≥ 0`), `(a+b-c)(b+c-a)(c+a-b) ≤ abc`. With `x=b+c-a`,
`y=c+a-b`, `z=a+b-c`, the gap is `x(y-z)²+y(z-x)²+z(x-y)² ≥ 0`, i.e.
`∑ (b+c-a)(b-c)² ≥ 0`. See `library/index/`. -/
theorem ravi_product_le_abc (a b c : ℝ) (hab : 0 ≤ a + b - c) (hbc : 0 ≤ b + c - a)
    (hca : 0 ≤ c + a - b) : (a + b - c) * (b + c - a) * (c + a - b) ≤ a * b * c := by
  nlinarith [mul_nonneg hbc (sq_nonneg (b - c)), mul_nonneg hca (sq_nonneg (c - a)),
    mul_nonneg hab (sq_nonneg (a - b))]
