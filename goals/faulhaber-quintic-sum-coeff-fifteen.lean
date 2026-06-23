import Mathlib

theorem faulhaber_quintic_sum_coeff_fifteen (n : ℕ) : 180 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 15 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
