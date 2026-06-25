import Mathlib

theorem faulhaber_quartic_sum_coeff_fifty (n : ℕ) : 1500 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 50 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
