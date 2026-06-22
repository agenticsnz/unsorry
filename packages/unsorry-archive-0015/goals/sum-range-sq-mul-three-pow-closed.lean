import Mathlib

theorem sum_range_sq_mul_three_pow_closed (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) ^ 2) * 3 ^ k = ((n : ℤ) ^ 2 - 3 * n + 3) * 3 ^ n - 3 := by
  sorry
