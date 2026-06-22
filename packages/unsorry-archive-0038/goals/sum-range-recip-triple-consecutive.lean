import Mathlib

theorem sum_range_recip_triple_consecutive (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / (((k : ℚ) + 1) * ((k : ℚ) + 2) * ((k : ℚ) + 3)) = 1 / 4 - 1 / (2 * ((n : ℚ) + 1) * ((n : ℚ) + 2)) := by
  sorry
