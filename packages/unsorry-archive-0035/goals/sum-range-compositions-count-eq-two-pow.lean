import Mathlib

theorem sum_range_compositions_count_eq_two_pow (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose (k - 1) = 2 ^ n := by
  sorry
