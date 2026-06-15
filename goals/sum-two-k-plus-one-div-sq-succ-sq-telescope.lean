import Mathlib

theorem sum_two_k_plus_one_div_sq_succ_sq_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (2 * (k + 1) + 1) / (((k + 1) : ℚ) ^ 2 * (k + 2) ^ 2)) = 1 - 1 / ((n : ℚ) + 1) ^ 2 := by
  sorry
