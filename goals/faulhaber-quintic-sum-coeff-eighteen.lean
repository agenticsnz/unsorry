import Mathlib

theorem faulhaber_quintic_sum_coeff_eighteen (n : ℕ) : 216 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 18 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
