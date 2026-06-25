import Mathlib

theorem faulhaber_quintic_sum_coeff_nineteen (n : ℕ) : 228 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 19 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
