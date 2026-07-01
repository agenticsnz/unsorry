import Mathlib

theorem faulhaber_quintic_sum_coeff_seventyfive (n : ℕ) : 900 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 75 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
