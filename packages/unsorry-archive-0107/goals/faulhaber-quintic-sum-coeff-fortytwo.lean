import Mathlib

theorem faulhaber_quintic_sum_coeff_fortytwo (n : ℕ) : 504 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 42 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
