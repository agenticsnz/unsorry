import Mathlib

theorem sum_range_cube_mul_two_pow_closed (n : ℕ) : ∑ k ∈ Finset.range n, ((k : ℤ) ^ 3) * 2 ^ k = ((n : ℤ) ^ 3 - 6 * n ^ 2 + 18 * n - 26) * 2 ^ n + 26 := by
  sorry
