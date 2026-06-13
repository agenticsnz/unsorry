import Mathlib

theorem sum_range_choose_mul_two_pow (n : ℕ) :
    ∑ k ∈ Finset.range (n + 1), n.choose k * 2 ^ k = 3 ^ n := by
  sorry
