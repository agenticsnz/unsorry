import Mathlib

theorem faulhaber_quintic_sum_coeff_thirtysix (n : ℕ) : 432 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 36 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  sorry
