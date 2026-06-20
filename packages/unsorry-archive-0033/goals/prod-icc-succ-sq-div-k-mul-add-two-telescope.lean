import Mathlib

theorem prod_icc_succ_sq_div_k_mul_add_two_telescope (n : ℕ) :
    ∏ k ∈ Finset.Icc 1 n, (((k : ℝ) + 1) ^ 2 / ((k : ℝ) * ((k : ℝ) + 2)))
      = 2 * ((n : ℝ) + 1) / ((n : ℝ) + 2) := by
  sorry
