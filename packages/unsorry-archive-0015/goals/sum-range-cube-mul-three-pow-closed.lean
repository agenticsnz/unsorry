import Mathlib

theorem sum_range_cube_mul_three_pow_closed (n : ℕ) : 8 * ∑ k ∈ Finset.range n, ((k : ℤ) ^ 3) * 3 ^ k = (4 * (n : ℤ) ^ 3 - 18 * n ^ 2 + 36 * n - 33) * 3 ^ n + 33 := by
  sorry
