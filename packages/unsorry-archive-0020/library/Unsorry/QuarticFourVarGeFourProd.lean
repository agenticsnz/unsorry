import Mathlib

/-- Goal `quartic-four-var-ge-four-prod`: `4abcd ≤ a⁴+b⁴+c⁴+d⁴`. AM-GM via
`nlinarith`: `a⁴+b⁴ ≥ 2a²b²`, `c⁴+d⁴ ≥ 2c²d²`, `a²b²+c²d² ≥ 2abcd`. See
`library/index/`. -/
theorem quartic_four_var_ge_four_prod (a b c d : ℝ) :
    4 * a * b * c * d ≤ a ^ 4 + b ^ 4 + c ^ 4 + d ^ 4 := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2), sq_nonneg (c ^ 2 - d ^ 2), sq_nonneg (a * b - c * d),
    sq_nonneg (a * b + c * d)]
