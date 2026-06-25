import Mathlib

theorem faulhaber_quintic_sum_coeff_eleven (n : ℕ) : 132 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 11 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
