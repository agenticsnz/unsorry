import Mathlib

theorem sum_range_odd_index_choose_eq_two_pow (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * (n + 1)).choose (2 * k + 1) = 2 ^ (2 * n + 1) := by
  sorry
