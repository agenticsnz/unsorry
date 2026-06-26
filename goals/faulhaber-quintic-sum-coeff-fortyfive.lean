import Mathlib

theorem faulhaber_quintic_sum_coeff_fortyfive (n : ℕ) : 540 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 45 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
