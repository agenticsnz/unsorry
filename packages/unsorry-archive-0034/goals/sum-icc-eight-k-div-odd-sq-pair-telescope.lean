import Mathlib

theorem sum_icc_eight_k_div_odd_sq_pair_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (8 * (k : ℝ)) / (((2 * k - 1) ^ 2) * ((2 * k + 1) ^ 2)) = 1 - 1 / ((2 * (n : ℝ) + 1) ^ 2) := by
  sorry
