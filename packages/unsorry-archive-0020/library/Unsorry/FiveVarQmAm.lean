import Mathlib

theorem five_var_qm_am (a b c d e : ℝ) : (a + b + c + d + e) ^ 2 ≤ 5 * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 + e ^ 2) := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a - c), sq_nonneg (a - d), sq_nonneg (a - e),
    sq_nonneg (b - c), sq_nonneg (b - d), sq_nonneg (b - e),
    sq_nonneg (c - d), sq_nonneg (c - e), sq_nonneg (d - e)]