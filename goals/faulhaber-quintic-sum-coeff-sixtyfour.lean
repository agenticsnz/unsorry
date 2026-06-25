import Mathlib

theorem faulhaber_quintic_sum_coeff_sixtyfour (n : ℕ) : 768 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 64 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
