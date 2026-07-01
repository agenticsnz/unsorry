import Mathlib

theorem faulhaber_quintic_sum_coeff_one (n : ℕ) : 12 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 1 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
