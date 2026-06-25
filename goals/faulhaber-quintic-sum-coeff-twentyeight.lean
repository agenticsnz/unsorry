import Mathlib

theorem faulhaber_quintic_sum_coeff_twentyeight (n : ℕ) : 336 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 28 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
