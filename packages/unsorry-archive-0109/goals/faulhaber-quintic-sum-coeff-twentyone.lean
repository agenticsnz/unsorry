import Mathlib

theorem faulhaber_quintic_sum_coeff_twentyone (n : ℕ) : 252 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 21 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
