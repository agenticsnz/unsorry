import Mathlib

theorem sum_range_sq_triangular_form (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 2
      = (∑ i ∈ Finset.range (n + 1), i) * (2 * n + 1) := by
  sorry
