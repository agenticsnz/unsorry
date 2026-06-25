import Mathlib

theorem faulhaber_quintic_sum_coeff_ten (n : ℕ) : 120 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 10 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
