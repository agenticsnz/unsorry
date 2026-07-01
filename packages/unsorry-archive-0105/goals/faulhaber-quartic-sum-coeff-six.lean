import Mathlib

theorem faulhaber_quartic_sum_coeff_six (n : ℕ) : 180 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 6 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
