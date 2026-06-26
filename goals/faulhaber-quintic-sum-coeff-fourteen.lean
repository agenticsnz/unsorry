import Mathlib

theorem faulhaber_quintic_sum_coeff_fourteen (n : ℕ) : 168 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 14 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
