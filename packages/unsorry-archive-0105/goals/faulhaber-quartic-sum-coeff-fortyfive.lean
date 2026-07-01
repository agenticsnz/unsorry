import Mathlib

theorem faulhaber_quartic_sum_coeff_fortyfive (n : ℕ) : 1350 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 45 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
