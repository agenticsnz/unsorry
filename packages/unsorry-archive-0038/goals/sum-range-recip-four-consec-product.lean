import Mathlib

theorem sum_range_recip_four_consec_product (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2) * (k + 3) * (k + 4))) = 1 / 18 - 1 / (3 * ((n : ℚ) + 1) * (n + 2) * (n + 3)) := by
  sorry
