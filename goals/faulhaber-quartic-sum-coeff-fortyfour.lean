import Mathlib

theorem faulhaber_quartic_sum_coeff_fortyfour (n : ℕ) : 1320 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 44 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
