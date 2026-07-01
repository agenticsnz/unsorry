import Mathlib

theorem faulhaber_quintic_sum_coeff_three (n : ℕ) : 36 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 3 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
