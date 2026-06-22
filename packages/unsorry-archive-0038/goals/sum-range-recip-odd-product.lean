import Mathlib

theorem sum_range_recip_odd_product (n : ℕ) :
    ∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * k + 1) * (2 * k + 3)) = n / (2 * n + 1) := by
  sorry
