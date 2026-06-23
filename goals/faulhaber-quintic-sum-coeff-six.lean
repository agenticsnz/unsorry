import Mathlib

theorem faulhaber_quintic_sum_coeff_six (n : ℕ) : 72 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 6 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
