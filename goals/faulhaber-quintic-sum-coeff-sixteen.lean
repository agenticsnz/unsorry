import Mathlib

theorem faulhaber_quintic_sum_coeff_sixteen (n : ℕ) : 192 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 16 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
