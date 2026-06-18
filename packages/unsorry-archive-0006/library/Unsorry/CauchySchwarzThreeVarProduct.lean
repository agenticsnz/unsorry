import Mathlib

/-- Goal `cauchy-schwarz-three-var-product`: the three-variable Cauchy–Schwarz
inequality in product form, `(a·x + b·y + c·z)² ≤ (a²+b²+c²)(x²+y²+z²)`. See
`library/index/`. Proof via the Lagrange identity: the gap equals
`(a·y−b·x)² + (a·z−c·x)² + (b·z−c·y)² ≥ 0`. -/
theorem cauchy_schwarz_three_var_product (a b c x y z : ℝ) :
    (a*x + b*y + c*z)^2 ≤ (a^2 + b^2 + c^2) * (x^2 + y^2 + z^2) := by
  nlinarith [sq_nonneg (a*y - b*x), sq_nonneg (a*z - c*x), sq_nonneg (b*z - c*y)]
