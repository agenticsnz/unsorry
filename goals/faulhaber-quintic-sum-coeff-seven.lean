import Mathlib

theorem faulhaber_quintic_sum_coeff_seven (n : ℕ) : 84 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 7 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
