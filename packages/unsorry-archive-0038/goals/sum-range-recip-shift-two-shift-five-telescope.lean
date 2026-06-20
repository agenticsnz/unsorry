import Mathlib

theorem sum_range_recip_shift_two_shift_five_telescope (n : ℕ) : ∑ k ∈ Finset.range n, (3 : ℚ) / (((k : ℚ) + 2) * ((k : ℚ) + 5)) = 13 / 12 - 1 / ((n : ℚ) + 2) - 1 / ((n : ℚ) + 3) - 1 / ((n : ℚ) + 4) := by
  sorry
