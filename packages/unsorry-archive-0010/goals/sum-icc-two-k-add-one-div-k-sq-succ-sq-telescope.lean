import Mathlib

theorem sum_icc_two_k_add_one_div_k_sq_succ_sq_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (2 * (k : ℚ) + 1) / ((k : ℚ) ^ 2 * ((k : ℚ) + 1) ^ 2) = 1 - 1 / ((n : ℚ) + 1) ^ 2 := by
  sorry
