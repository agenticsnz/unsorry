import Mathlib

theorem sum_range_four_consecutive_product (n : ℕ) : 5 * (∑ i ∈ Finset.range n, i * (i + 1) * (i + 2) * (i + 3)) = (n - 1) * n * (n + 1) * (n + 2) * (n + 3) := by
  sorry
