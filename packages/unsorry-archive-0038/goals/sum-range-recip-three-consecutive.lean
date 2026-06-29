import Mathlib

theorem sum_range_recip_three_consecutive (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2) * (k + 3)) = 1 / 4 - 1 / (2 * (n + 1) * (n + 2)) := by
  sorry
