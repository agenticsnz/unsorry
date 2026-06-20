import Mathlib

theorem sum_range_recip_four_step_product (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((4 * (k : ℚ) + 1) * (4 * (k : ℚ) + 5)) = (n : ℚ) / (4 * (n : ℚ) + 1) := by
  sorry
