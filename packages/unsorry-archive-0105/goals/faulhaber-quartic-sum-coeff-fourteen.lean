import Mathlib

theorem faulhaber_quartic_sum_coeff_fourteen (n : ℕ) : 420 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 14 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
