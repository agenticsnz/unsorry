import Mathlib

theorem sum_range_pow_seven_faulhaber_triangular (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 7
      = (∑ i ∈ Finset.range (n + 1), i) ^ 2
        * (6 * (∑ i ∈ Finset.range (n + 1), i) ^ 2 - 4 * (∑ i ∈ Finset.range (n + 1), i) + 1) := by
  sorry
