import Mathlib

theorem sum_range_lower_triangle_choose_eq_two_pow (n : ℕ) : ∑ j ∈ Finset.range (n + 1), ∑ k ∈ Finset.range (j + 1), j.choose k = 2 ^ (n + 1) - 1 := by
  sorry
