import Mathlib

theorem faulhaber_quintic_sum_coeff_thirtyfive (n : ℕ) : 420 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 35 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
