import Mathlib

theorem sum_range_odd_num_sq_succ_sq_telescope (n : ℕ) : ∑ k ∈ Finset.range n, (2 * (k : ℚ) + 3) / ((((k : ℚ) + 1) ^ 2) * (((k : ℚ) + 2) ^ 2)) = 1 - 1 / (((n : ℚ) + 1) ^ 2) := by
  sorry
