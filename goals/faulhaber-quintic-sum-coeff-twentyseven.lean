import Mathlib

theorem faulhaber_quintic_sum_coeff_twentyseven (n : ℕ) : 324 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 27 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
