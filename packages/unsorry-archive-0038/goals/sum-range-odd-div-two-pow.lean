import Mathlib

theorem sum_range_odd_div_two_pow (n : ℕ) : ∑ i ∈ Finset.range (n + 1), (2 * i + 1 : ℚ) / 2 ^ i = 6 - (2 * n + 5) / 2 ^ n := by
  sorry
