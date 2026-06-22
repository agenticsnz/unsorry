import Mathlib

set_option linter.unusedVariables false in
theorem pell_d3_rational_bound_above (x y : ℤ) (h : x ^ 2 - 3 * y ^ 2 = 1) (hy : 0 < y) : 3 * y ^ 2 < x ^ 2 := by
  omega
