import Mathlib

theorem faulhaber_quintic_sum_coeff_nine (n : ℕ) : 108 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 9 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
