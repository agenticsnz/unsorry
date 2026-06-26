import Mathlib

theorem faulhaber_quintic_sum_coeff_forty (n : ℕ) : 480 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 40 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
