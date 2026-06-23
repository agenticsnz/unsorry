import Mathlib

theorem faulhaber_quintic_sum_coeff_thirty (n : ℕ) : 360 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 30 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
