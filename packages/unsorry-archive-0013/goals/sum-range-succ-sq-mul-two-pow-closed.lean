import Mathlib

theorem sum_range_succ_sq_mul_two_pow_closed (n : ℕ) : ∑ k ∈ Finset.range n, ((k : ℤ) + 1) ^ 2 * 2 ^ k = ((n : ℤ) ^ 2 - 2 * n + 3) * 2 ^ n - 3 := by
  sorry
