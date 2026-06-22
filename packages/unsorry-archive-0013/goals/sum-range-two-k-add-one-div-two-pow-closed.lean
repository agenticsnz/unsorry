import Mathlib

theorem sum_range_two_k_add_one_div_two_pow_closed (n : ℕ) : (∑ k ∈ Finset.range n, (2 * (k : ℚ) + 1) / 2 ^ k) = 6 - (4 * (n : ℚ) + 6) / 2 ^ n := by
  sorry
