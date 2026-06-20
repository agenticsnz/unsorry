import Mathlib

theorem sum_range_recip_odd_pair_consecutive (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * (k : ℚ) + 1) * (2 * (k : ℚ) + 3)) = (n : ℚ) / (2 * (n : ℚ) + 1) := by
  sorry
