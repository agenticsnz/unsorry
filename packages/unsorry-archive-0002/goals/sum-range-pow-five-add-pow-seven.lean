import Mathlib

theorem sum_range_pow_five_add_pow_seven (n : ℕ) :
    (∑ i ∈ Finset.range (n + 1), i ^ 5) + (∑ i ∈ Finset.range (n + 1), i ^ 7)
      = 2 * (∑ i ∈ Finset.range (n + 1), i) ^ 4 := by
  sorry
