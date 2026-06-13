import Mathlib

theorem sum_range_pow_five_faulhaber_triangular (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 5
      = (∑ i ∈ Finset.range (n + 1), i) ^ 2 * (4 * (∑ i ∈ Finset.range (n + 1), i) - 1) := by
  sorry
