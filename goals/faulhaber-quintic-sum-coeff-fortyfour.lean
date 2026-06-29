import Mathlib

theorem faulhaber_quintic_sum_coeff_fortyfour (n : ℕ) : 528 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 44 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
