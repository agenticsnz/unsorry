import Mathlib

theorem sum_range_pow_four_triangular_form (n : ℕ) :
    15 * ∑ i ∈ Finset.range (n + 1), i ^ 4
      = (∑ i ∈ Finset.range (n + 1), i) * (2 * n + 1) * (3 * n ^ 2 + 3 * n - 1) := by
  sorry
