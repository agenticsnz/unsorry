import Mathlib

theorem sum_icc_four_div_four_k_sub_one_four_k_add_three_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (4 : ℚ) / ((4 * (k : ℚ) - 1) * (4 * (k : ℚ) + 3)) = 1 / 3 - 1 / (4 * (n : ℚ) + 3) := by
  sorry
