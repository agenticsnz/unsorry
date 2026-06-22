import Mathlib

theorem sum_range_recip_three_consec_odd_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * k + 1) * (2 * k + 3) * (2 * k + 5))) = 1 / 12 - 1 / (4 * (2 * (n : ℚ) + 1) * (2 * n + 3)) := by
  sorry
