import Mathlib

theorem faulhaber_quintic_sum_coeff_twenty (n : ℕ) : 240 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 20 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
