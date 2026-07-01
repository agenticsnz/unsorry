import Mathlib

theorem faulhaber_quintic_sum_coeff_fiftyfive (n : ℕ) : 660 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 55 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
