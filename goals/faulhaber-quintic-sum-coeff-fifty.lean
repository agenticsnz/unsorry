import Mathlib

theorem faulhaber_quintic_sum_coeff_fifty (n : ℕ) : 600 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 50 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
