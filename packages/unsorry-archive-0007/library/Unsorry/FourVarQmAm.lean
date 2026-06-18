import Mathlib

theorem four_var_qm_am (a b c d : ℝ) : (a + b + c + d) ^ 2 ≤ 4 * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2) := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a - c), sq_nonneg (a - d),
             sq_nonneg (b - c), sq_nonneg (b - d), sq_nonneg (c - d)]
