import Mathlib

theorem sum_range_recip_five_step_product (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((5 * (k : ℚ) + 2) * (5 * (k : ℚ) + 7)) = (n : ℚ) / (2 * (5 * (n : ℚ) + 2)) := by
  sorry
