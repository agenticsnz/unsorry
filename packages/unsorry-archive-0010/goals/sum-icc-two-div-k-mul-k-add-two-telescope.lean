import Mathlib

theorem sum_icc_two_div_k_mul_k_add_two_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (2 : ℚ) / ((k : ℚ) * ((k : ℚ) + 2)) = 3 / 2 - 1 / ((n : ℚ) + 1) - 1 / ((n : ℚ) + 2) := by
  sorry
