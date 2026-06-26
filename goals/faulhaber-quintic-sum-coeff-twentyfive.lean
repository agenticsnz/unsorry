import Mathlib

theorem faulhaber_quintic_sum_coeff_twentyfive (n : ℕ) : 300 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 25 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
