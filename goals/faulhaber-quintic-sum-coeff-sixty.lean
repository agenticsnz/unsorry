import Mathlib

theorem faulhaber_quintic_sum_coeff_sixty (n : ℕ) : 720 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 60 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
