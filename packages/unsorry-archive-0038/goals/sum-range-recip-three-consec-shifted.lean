import Mathlib

theorem sum_range_recip_three_consec_shifted (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2) * (k + 3))) = (n : ℚ) * (n + 3) / (4 * (n + 1) * (n + 2)) := by
  sorry
