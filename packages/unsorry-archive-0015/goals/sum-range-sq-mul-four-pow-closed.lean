import Mathlib

theorem sum_range_sq_mul_four_pow_closed (n : ℕ) : 27 * ∑ k ∈ Finset.range n, ((k : ℤ) ^ 2) * 4 ^ k = (9 * (n : ℤ) ^ 2 - 24 * n + 20) * 4 ^ n - 20 := by
  sorry
