import Mathlib

theorem sum_two_k_add_one_mul_two_pow (n : ℕ) : ∑ k ∈ Finset.range n, ((2 * (k : ℤ) + 1)) * 2 ^ k = (2 * (n : ℤ) - 3) * 2 ^ n + 3 := by
  sorry
