import Mathlib

theorem sum_icc_three_div_three_k_sub_one_three_k_add_two_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (3 : ℚ) / ((3 * (k : ℚ) - 1) * (3 * (k : ℚ) + 2)) = 1 / 2 - 1 / (3 * (n : ℚ) + 2) := by
  sorry
