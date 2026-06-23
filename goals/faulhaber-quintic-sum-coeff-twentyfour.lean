import Mathlib

theorem faulhaber_quintic_sum_coeff_twentyfour (n : ℕ) : 288 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 24 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
