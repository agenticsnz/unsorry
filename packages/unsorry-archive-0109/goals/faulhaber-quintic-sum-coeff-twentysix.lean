import Mathlib

theorem faulhaber_quintic_sum_coeff_twentysix (n : ℕ) : 312 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 26 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
