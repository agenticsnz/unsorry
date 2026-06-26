import Mathlib

theorem sum_k_sq_mul_two_pow (n : ℕ) : ∑ k ∈ Finset.range n, ((k : ℤ) ^ 2) * 2 ^ k = ((n : ℤ) ^ 2 - 4 * n + 6) * 2 ^ n - 6 := by
  sorry
